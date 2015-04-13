# viciphone_config
A Perl-based web script to configure Grandstream phones via VICIdial

Created by Loren Burlingame @ Tonka TelTec (loren at tonkateltec dot com)

10/20/2012

viciphone_config.pl is used to retrieve phone configuration variables
from the vicidial "phones" table in order to configure grandstream phones

In order to configure a Grandstream phone you must:

1. Put the template name and phone MAC address in the "Phone Type" field in VICIdial's Admin > Phones section

 Example: gxp1450,001a2b3c4d5e

2. Copy all the files from this project into your web server's htdocs folder (/srv/www/htdocs)

3. Create a log directory that is writeable by the web server (see $debug_log_dir below)

4. Modify the templates to suite your needs

5. Add the HTTP path to your Grandstream phone

 Example: web.server.com/viciphone_config.pl

# NOTE ON SECURITY

This script will match the MAC address sent in the HTTP User Agent string from the phone with the MAC address in the
VICIdial database. Given time and effort, this could be discovered by a malicious user who would then have access
to a phone configuration for your VICIdial server. If you have your SIP ports open to the world, it would then allow
the attacker to use the information in the config to register a phone on your server and start to make calls.

# ****It is very important to secure your server with IP access lists or authentication mechanisms****

This script is distributed "as-is" and the author nor Tonka TelTec take upon themselves any responsibility for any damage
done to your system by or as a result from using this script.

Note the Perl packages you will need installed in order to run this script

- CGI.pm
- CGI::Carp
- DateTime
- DateTime::TimeZone
- DBI
