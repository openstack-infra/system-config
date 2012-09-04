#!/bin/sh
PATH=/usr/sbin:/usr/bin:/sbin:/bin

# in case of `dpkg -r' leaving conffile.
if ! [ -x /usr/sbin/tmpreaper ]; then
    exit 0
fi

# Remove `/tmp/...' files not accessed in X time (configured in
# /etc/tmpreaper.conf, default 7 days), protecting the .X, .ICE, .iroha and
# .ki2 files; but removing symlinks. For directories not the access time, but
# the modification time is used (--mtime-dir), as reading a directory to check
# the contents will update the access time!
#
# In the default, /tmp/. is used, not the plain /tmp you might expect, as this
# accomodates the situation where /tmp is a symlink to some other place.
#
# Note that the sockets are safe even without the `--protect', unless `--all'
# is given, and the `.X*-lock' files would be safe also, as long as they have
# no write permissions, so this particular protect is mainly illustrative, and
# redundant.  For best results, don't try to get fancy with the moustache
# expansions.  KISS.  Always --test your protect patterns.
#
# Immutable files (such as ext3fs' .journal) are not (cannot be) removed;
# when such a file is encountered when trying to remove it, no error is given
# unless you use the --verbose option in which case a message is given.
#
# In case you're wondering: .iroha is for cannaserver and .ki2 is for kinput2
# (japanese software, lock files).
# journal.dat is for (older) ext3 filesystems
# quota.user, quota.group is for (duh) quotas.

# Set config defaults
SHOWWARNING=''

# get the TMPREAPER_TIME value from /etc/default/rcS

if grep '^TMPTIME=' /etc/default/rcS >/dev/null 2>&1; then
    eval $(grep '^TMPTIME=' /etc/default/rcS)
    if [ -n "$TMPTIME" ]; then
        # Don't clean files if TMPTIME is negative or 'infinite'
        # to mimic the way /lib/init/bootclean.sh works.
        case "$TMPTIME" in
          -*|infinite|infinity)
                # don't use this as default
                ;;
           *)
                if [ "$TMPTIME" -gt 0 ]; then
                    TMPREAPER_TIME=${TMPTIME}d
                else
                    TMPREAPER_TIME=7d
                fi
                ;;
        esac
    fi
fi

# ! Important !  The "set -f" below prevents the shell from expanding
#                file paths, which is vital for the configuration below to work.

set -f

# preserve environment setting of TMPREAPER_DELAY to allow manual override when
# running the cron.daily script by hand:
if [ -n "$TMPREAPER_DELAY" ]; then
    # check for digits only
    case "$TMPREAPER_DELAY" in
        [0-9]*) TMPREAPER_DELAY_SAVED="$TMPREAPER_DELAY";;
        *)      ;;
    esac
fi

if [ -s /etc/tmpreaper.conf ]; then
    . /etc/tmpreaper.conf
fi

# Now restore the saved value of TMPREAPER_DELAY (if any):
if [ -n "$TMPREAPER_DELAY_SAVED" ]; then
    TMPREAPER_DELAY="$TMPREAPER_DELAY_SAVED"
else
    # set default in case it's not given in tmpreaper.conf:
    TMPREAPER_DELAY=${TMPREAPER_DELAY:-256}
fi

if [ "$SHOWWARNING" = true ]; then
    echo "Please read /usr/share/doc/tmpreaper/README.security.gz first;"
    echo "edit /etc/tmpreaper.conf to remove this message (look for SHOWWARNING)."
    exit 0
fi

# Verify that these variables are set, and if not, set them to default values
# This will work even if the required lines are not specified in the included
# file above, but the file itself does exist.
TMPREAPER_TIME=${TMPREAPER_TIME:-7d}
TMPREAPER_PROTECT_EXTRA=${TMPREAPER_PROTECT_EXTRA:-''}
TMPREAPER_DIRS=${TMPREAPER_DIRS:-'/tmp/.'}

nice -n10 tmpreaper --delay=$TMPREAPER_DELAY --mtime-dir --symlinks $TMPREAPER_TIME  \
  $TMPREAPER_ADDITIONALOPTIONS \
  --ctime \
  --protect '/tmp/.X*-{lock,unix,unix/*}' \
  --protect '/tmp/.ICE-{unix,unix/*}' \
  --protect '/tmp/.iroha_{unix,unix/*}' \
  --protect '/tmp/.ki2-{unix,unix/*}' \
  --protect '/tmp/lost+found' \
  --protect '/tmp/journal.dat' \
  --protect '/tmp/quota.{user,group}' \
  `for i in $TMPREAPER_PROTECT_EXTRA; do echo --protect "$i"; done` \
  $TMPREAPER_DIRS
