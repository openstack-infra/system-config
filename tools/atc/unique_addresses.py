#!/usr/bin/env python

# Generate a unique list of Primary E-mail addresses from an ATCs CSV
# dump, aggregating any ATC which may have multiple entries sharing a
# common address, even if it wasn't the primary address.

import csv
import sys

def canonicalize_email(email):
    """Lower-case the domain part"""
    localpart, domainpart = email.split('@')
    return '@'.join((localpart, domainpart.lower()))

# Read the CSV file provided at the command line into a list of lists
raw_atcs = list(csv.reader(open(sys.argv[1])))

# This will hold a cross-reference mapping all addresses to primary addresses
address_xref = {}

# Iterate over the rows from the CSV file
for atc in raw_atcs:

    # Skip any rows which completely lack E-mail addresses
    if len(atc) > 2:

        # Work from a list of canonicalized addresses for this ATC
        addresses = [canonicalize_email(a) for a in atc[2:]]

        # Assume the first address is the primary
        primary = addresses[0]

        # Iterate over the list of addresses for this ATC
        for address in addresses:

            # If the address is already in the cross-reference...
            if address in address_xref:

                # ...and if it there's a different primary listed for it...
                if address_xref[address] != primary:

                    # ...then use the primary we found there
                    primary = address_xref[address]

        # Iterate back over the list of addresses in a second pass...
        for address in addresses:

            # ...and if the address isn't in the cross-reference yet...
            if address not in address_xref:

                # ...then add it with the primary mapping we know is valid
                address_xref[address] = primary

# Output the unique, sorted set of values from the primary map
print('\n'.join(sorted(set(address_xref.values()))))
