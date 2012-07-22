#!/usr/bin/python
"""Set Omeka admin password and email

Option:
    --pass=     unless provided, will ask interactively
    --email=    unless provided, will ask interactively

"""

import sys
import getopt
import hashlib
import random
import string

from dialog_wrapper import Dialog
from mysqlconf import MySQL

def usage(s=None):
    if s:
        print >> sys.stderr, "Error:", s
    print >> sys.stderr, "Syntax: %s [options]" % sys.argv[0]
    print >> sys.stderr, __doc__
    sys.exit(1)

def main():
    try:
        opts, args = getopt.gnu_getopt(sys.argv[1:], "h",
                                       ['help', 'pass=', 'email='])
    except getopt.GetoptError, e:
        usage(e)

    password = ""
    email = ""
    for opt, val in opts:
        if opt in ('-h', '--help'):
            usage()
        elif opt == '--pass':
            password = val
        elif opt == '--email':
            email = val

    if not password:
        d = Dialog('TurnKey Linux - First boot configuration')
        password = d.get_password(
            "Omeka Password",
            "Enter new password for the Omeka 'admin' account.")

    if not email:
        if 'd' not in locals():
            d = Dialog('TurnKey Linux - First boot configuration')

        email = d.get_email(
            "Omeka Email",
            "Enter email address for the Omeka 'admin' account.",
            "admin@example.com")

    salt = ''.join((random.choice(string.letters+string.digits) for x in range(16)))
    hash = hashlib.sha1(salt + password).hexdigest()

    m = MySQL()
    m.execute('UPDATE omeka.users SET password=\"%s\", salt=\"%s\" WHERE username=\"admin\";' % (hash, salt))

    m.execute('UPDATE omeka.entities SET email=\"%s\" WHERE id=1' % email)
    m.execute('UPDATE omeka.options SET value=\"%s\" WHERE name=\"administrator_email\"' % email)

if __name__ == "__main__":
    main()

