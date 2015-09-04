Omeka - Serious web publishing for cultural collections
=======================================================

`Omeka`_ is a standards-based web-publishing platform for the display of
library, museum, archives, and scholarly collections and exhibitions.
Its "five-minute setup" makes launching an online exhibition as easy as
launching a blog. It is designed for scholars, museums, libraries,
archives, and all cultural heritage enthusiasts.

This appliance includes all the standard features in `TurnKey Core`_,
and on top of that:

- Omeka configurations:
   
   - Installed from upstream source code to /var/www/omeka

- SSL support out of the box.
- `Adminer`_ administration frontend for MySQL (listening on port)
  12322 - uses SSL).
- Postfix MTA (bound to localhost) to allow sending of email (e.g.,
  password recovery).
- Webmin modules for configuring Apache2, PHP, MySQL and Postfix.

Credentials *(passwords set at first boot)*
-------------------------------------------

-  Webmin, SSH, MySQL, Adminer: username **root**
-  Omeka: username **admin**


.. _Omeka: http://omeka.org/
.. _TurnKey Core: http://www.turnkeylinux.org/core
.. _Adminer: http://www.adminer.org/
