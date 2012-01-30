# -*- coding: utf-8 -*-
"""
    lodgeit.database
    ~~~~~~~~~~~~~~~~

    Database fun :)

    :copyright: 2007-2008 by Armin Ronacher, Christopher Grebs.
    :license: BSD
"""
import time
import difflib
from datetime import datetime
from werkzeug import cached_property
from sqlalchemy import MetaData, Integer, Text, DateTime, ForeignKey, \
     String, Boolean, Table, Column, select, and_, func
from sqlalchemy.orm import scoped_session, create_session, backref, relation
from sqlalchemy.orm.scoping import ScopedSession
from lodgeit import local
from lodgeit.utils import generate_paste_hash
from lodgeit.lib.highlighting import highlight, preview_highlight, LANGUAGES

from sqlalchemy.orm import mapper as sqla_mapper

def session_mapper(scoped_session):
    def mapper(cls, *arg, **kw):
        cls.query = scoped_session.query_property()
        return sqla_mapper(cls, *arg, **kw)
    return mapper

session = scoped_session(lambda: create_session(local.application.engine),
    scopefunc=local._local_manager.get_ident)

metadata = MetaData()

pastes = Table('pastes', metadata,
    Column('paste_id', Integer, primary_key=True),
    Column('code', Text),
    Column('parent_id', Integer, ForeignKey('pastes.paste_id'),
           nullable=True),
    Column('pub_date', DateTime),
    Column('language', String(30)),
    Column('user_hash', String(40), nullable=True),
    Column('handled', Boolean, nullable=False),
    Column('private_id', String(40), unique=True, nullable=True)
)


class Paste(object):
    """Represents a paste."""

    def __init__(self, code, language, parent=None, user_hash=None,
                 private=False):
        if language not in LANGUAGES:
            language = 'text'
        self.code = u'\n'.join(code.splitlines())
        self.language = language
        if isinstance(parent, Paste):
            self.parent = parent
        elif parent is not None:
            self.parent_id = parent
        self.pub_date = datetime.now()
        self.handled = False
        self.user_hash = user_hash
        self.private = private

    @staticmethod
    def get(identifier):
        """Return the paste for an identifier.  Private pastes must be loaded
        with their unique hash and public with the paste id.
        """
        if isinstance(identifier, basestring) and not identifier.isdigit():
            return Paste.query.filter(Paste.private_id == identifier).first()
        return Paste.query.filter(
            (Paste.paste_id == int(identifier)) &
            (Paste.private_id == None)
        ).first()

    @staticmethod
    def find_all():
        """Return a query for all public pastes ordered by the id in reverse
        order.
        """
        return Paste.query.filter(Paste.private_id == None) \
                          .order_by(Paste.paste_id.desc())

    @staticmethod
    def count():
        """Count all pastes."""
        s = select([func.count(pastes.c.paste_id)])
        return session.execute(s).fetchone()[0]

    @staticmethod
    def resolve_root(identifier):
        """Find the root paste for a paste tree."""
        paste = Paste.get(identifier)
        if paste is None:
            return
        while paste.parent_id is not None:
            paste = paste.parent
        return paste

    @staticmethod
    def fetch_replies():
        """Get the new replies for the ower of a request and flag them
        as handled.
        """
        s = select([pastes.c.paste_id],
            Paste.user_hash == local.request.user_hash
        )

        paste_list = Paste.query.filter(and_(
            Paste.parent_id.in_(s),
            Paste.handled == False,
            Paste.user_hash != local.request.user_hash,
        )).order_by(pastes.c.paste_id.desc()).all()

        to_mark = [p.paste_id for p in paste_list]
        session.execute(pastes.update(pastes.c.paste_id.in_(to_mark),
                                      values={'handled': True}))
        return paste_list

    def _get_private(self):
        return self.private_id is not None

    def _set_private(self, value):
        if not value:
            self.private_id = None
            return
        if self.private_id is None:
            while 1:
                self.private_id = generate_paste_hash()
                paste = Paste.query.filter(Paste.private_id ==
                                           self.private_id).first()
                if paste is None:
                    break
    private = property(_get_private, _set_private, doc='''
        The private status of the paste.  If the paste is private it gets
        a unique hash as identifier, otherwise an integer.
    ''')
    del _get_private, _set_private

    @property
    def identifier(self):
        """The paste identifier.  This is a string, the same the `get`
        method accepts.
        """
        if self.private:
            return self.private_id
        return str(self.paste_id)

    @property
    def url(self):
        """The URL to the paste."""
        return '/show/%s/' % self.identifier

    def compare_to(self, other, context_lines=4, template=False):
        """Compare the paste with another paste."""
        udiff = u'\n'.join(difflib.unified_diff(
            self.code.splitlines(),
            other.code.splitlines(),
            fromfile='Paste #%s' % self.identifier,
            tofile='Paste #%s' % other.identifier,
            lineterm='',
            n=context_lines
        ))
        if template:
            from lodgeit.lib.diff import prepare_udiff
            diff, info = prepare_udiff(udiff)
            return diff and diff[0] or None
        return udiff

    @cached_property
    def parsed_code(self):
        """The paste as rendered code."""
        return highlight(self.code, self.language)

    def to_xmlrpc_dict(self):
        """Convert the paste into a dict for XMLRCP."""
        return {
            'paste_id':         self.paste_id,
            'code':             self.code,
            'parsed_code':      self.parsed_code,
            'pub_date':         int(time.mktime(self.pub_date.timetuple())),
            'language':         self.language,
            'parent_id':        self.parent_id,
            'url':              self.url
        }

    def render_preview(self, num=5):
        """Render a preview for this paste."""
        return preview_highlight(self.code, self.language, num)

mapper= session_mapper(session)

mapper(Paste, pastes, properties={
    'children': relation(Paste,
        primaryjoin=pastes.c.parent_id==pastes.c.paste_id,
        cascade='all',
        backref=backref('parent', remote_side=[pastes.c.paste_id])
    )
})
