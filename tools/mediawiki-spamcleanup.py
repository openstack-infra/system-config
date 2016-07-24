#!/usr/bin/python

import sys

import simplemediawiki  # pip install simplemediawiki kitchen

spammers = sys.argv[1:]

wiki = simplemediawiki.MediaWiki('https://wiki.openstack.org/w/api.php')

wiki.login('youruser', 'yourpassword')  # (re)set with ChangePassword.php

token = wiki.call(dict(
    action='query', meta='tokens'))['query']['tokens']['csrftoken']

fullcount = 0
for spammer in spammers:

    # Block the account
    blockinfo = wiki.call(dict(
        action='query', list='users', usprop='blockinfo', ucshow='new',
        ususers=spammer)).get('query').get('users')[0]
    if 'missing' not in blockinfo and blockinfo.get(
            'blockexpiry') != 'infinity':
        print('Blocking account for spammer "%s"...' % spammer)
        result = wiki.call(dict(
            token=token, action='block', reason='spamming', noemail=True,
            allowusertalk=False, watchuser=False, user=spammer))
        print('  %s block set' % result['block']['expiry'])

    # Delete uploaded image file pages
    imagepages = wiki.call(dict(
        action='query', list='allimages', ailimit='max', aisort='timestamp',
        aiuser=spammer))
    if imagepages.get('query').get('allimages'):
        print('Deleting images for spammer "%s"...' % spammer)
        count = 0
        for page in imagepages['query']['allimages']:
            result = wiki.call(dict(
                token=token, action='delete', reason='spam',
                title=page['title']))
            print('  %s' % result['delete']['title'].encode('utf-8'))
            count += 1
            fullcount += 1
        print('  %s images deleted' % count)

    # Delete created pages
    newpages = wiki.call(dict(
        action='query', list='usercontribs', uclimit='max', ucshow='new',
        ucuser=spammer))
    if newpages.get('query').get('usercontribs'):
        print('Deleting pages for spammer "%s"...' % spammer)
        count = 0
        for page in newpages['query']['usercontribs']:
            if 'new' in page:
                result = wiki.call(dict(
                    token=token, action='delete', reason='spam',
                    title=page['title']))
                print('  %s' % result['delete']['title'].encode('utf-8'))
                count += 1
                fullcount += 1
        print('  %s pages deleted' % count)

print('total pages deleted: %s' % fullcount)
