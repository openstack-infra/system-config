======================
 Summit Invite Script
======================

It sends codes from codes.csv to ATCs in atc.csv and outputs a csv file
with which name corresponds to which code.

You use it like this:

- Copy settings.py.sample to settings.py
- Update values in settings.py, especially *EMAIL_USER*, *EMAIL_FROM*,
  *EMAIL_SIGNATURE* and *EMAIL_PASSWORD*
- Note that literal ``$`` characters in the template which are not part
  of a substitution variable (such as dollar amounts) should be doubled
  to escape them like ``... a $$600-off discount code ...`` so as to
  avoid raising *ValueError: Invalid placeholder in string: line <X>,
  col <Y>*
- Run a test with ``PYTHONIOENCODING=utf-8 python send.py atc_sample.csv codes_sample.csv > sent_sample.csv``

Should work on stock Ubuntu.

When ready, run the real thing with::

  $ PYTHONIOENCODING=utf-8 python send.py atc.csv codes.csv > sent.csv
