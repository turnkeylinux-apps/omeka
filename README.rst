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

     **Security note**: Updates to Omeka may require supervision so
     they **ARE NOT** configured to install automatically. See `Omeka
     documentation`_ for upgrading.

- SSL support out of the box.
- `Adminer`_ administration frontend for MySQL (listening on port)
  12322 - uses SSL).
- Postfix MTA (bound to localhost) to allow sending of email (e.g.,
  password recovery).
- Webmin modules for configuring Apache2, PHP, MySQL and Postfix.

Credentials *(passwords set at first boot)*
-------------------------------------------

-  Webmin, SSH, MySQL: username **root**
-  Adminer: username **adminer**
-  Omeka: username **admin**


.. _Omeka: https://omeka.org/
.. _TurnKey Core: https://www.turnkeylinux.org/core
.. _Omeka documentation: https://omeka.org/classic/docs/Installation/Upgrading/
.. _Adminer: https://www.adminer.org/
