#!/bin/sh

# This may be used with the about-filter or repo.about-filter setting in cgitrc.
# It passes formatting of about pages to differing programs, depending on the usage.

# Markdown support requires perl.
# RestructuredText support requires python and docutils.
# Man page support requires groff.

# The following environment variables can be used to retrieve the configuration
# of the repository for which this script is called:
# CGIT_REPO_URL        ( = repo.url       setting )
# CGIT_REPO_NAME       ( = repo.name      setting )
# CGIT_REPO_PATH       ( = repo.path      setting )
# CGIT_REPO_OWNER      ( = repo.owner     setting )
# CGIT_REPO_DEFBRANCH  ( = repo.defbranch setting )
# CGIT_REPO_SECTION    ( = section        setting )
# CGIT_REPO_CLONE_URL  ( = repo.clone-url setting )

cd /usr/libexec/cgit/filters//html-converters/
case "$(tr '[:upper:]' '[:lower:]' <<<"$1")" in
        *.md|*.mkd) exec ./md2html; ;;
        *.rst) exec sh /usr/local/bin/rst2html; ;;
        *.[1-9]) exec ./man2html; ;;
        *.htm|*.html) exec cat; ;;
        *.txt|*) exec ./txt2html; ;;
esac
