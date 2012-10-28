#!/usr/bin/perl -w
#
# viciphone_config.pl is used to retrieve phone configuration variables
# from the vicidial "phones" table in order to configure grandstream phones
#
# Created by Loren Burlingame on 10/20/2012
#

use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use DateTime();
use DateTime::TimeZone();
use DBI();

use strict;

# ------------------------------------------------------------

# phone template config directory
my $base_cfg_dir = '/srv/www/htdocs/gs';

# Script name
my $script_name = 'viciphone_config.pl';

# Timezone
my $timezone = 'America/Chicago';

# database connection variables
my $vici_db_host = '192.168.1.201';
my $vici_db_port = '3306';
my $vici_db_name = 'asterisk';
my $vici_db_user = 'cron';
my $vici_db_pass = '1234';

open ASTGUICLIENT, '/etc/astguiclient.conf';
while (<ASTGUICLIENT>) {
	$vici_db_host = $1 if $_ =~ /VARDB_server => (\S+)/i;
	$vici_db_name = $1 if $_ =~ /VARDB_database => (\S+)/i;
	$vici_db_user = $1 if $_ =~ /VARDB_user => (\S+)/i;
	$vici_db_pass = $1 if $_ =~ /VARDB_pass => (\S+)/i;
	$vici_db_port = $1 if $_ =~ /VARDB_port => (\S+)/i;
}
close ASTGUICLIENT;

# ------------------------------------------------------------

# Connect to vicidial database
my $vici_dsn = "DBI:mysql:database=$vici_db_name;host=$vici_db_host;port=$vici_db_port";

# Database connection handle
my $dbh = DBI->connect($vici_dsn, $vici_db_user, $vici_db_pass, { RaiseError => 1 });

# CGI variables
my $cgi = new CGI;

## Output of the below path variables
#
#$uri_path: http://testing.example.com/viciphone_config.pl/cfg000000000000.xml
#$uri_absolute_path: /viciphone_config.pl
#$uri_relative_path: viciphone_config.pl

my $uri_path = $cgi->url( -path_info => 1 );

my $uri_absolute_path;
if ($uri_path !~ /\/$script_name\/?/) {
	$uri_absolute_path = $cgi->url( -absolute => 1 );
	$uri_absolute_path =~ s/\/$//;
	$uri_absolute_path .= '/' . $script_name;
} else {
	$uri_absolute_path = $cgi->url( -absolute => 1 );
}	

my $uri_relative_path  = $cgi->url( -relative => 1 );

# Get remote IP address
my $remote_ip = $cgi->remote_addr();

# Grandstream Model HW GXP1450 SW 1.0.4.23 DevId 000000000000
my $http_user_agent = $cgi->user_agent();

my ($ua_str, $ua_mac_addr) = ($1, $2) if $http_user_agent =~ /(grandstream.*) DevId ([0-9a-z]{12})/i;

# ------------------------------------------------------------

# Set up time variables

my $tz = DateTime::TimeZone->new( name => $timezone);

# Get current date/time for time calculations
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();

$year += 1900;
$mon += 1;

my $ctime = DateTime->new(year => $year,
						  month => $mon,
						  day => $mday,
						  hour => $hour,
						  minute => $min,
						  second => $sec,
						  time_zone => $tz);
						  
my $cyear = $ctime->year();
my $cmonth = $ctime->month();
my $cday = $ctime->day();
my $chour = $ctime->hour();
my $cminute = $ctime->minute();
my $csecond = $ctime->second();

# SQL DATETIME format '2012-10-03 00:00:00'
my $cdatetime = $cyear . '-' . $cmonth . '-' . $cday . ' ' . $chour . ':' . $cminute . ':' . $csecond;

# ------------------------------------------------------------

sub mydebug {

	# Debugging
	my $logfile = $cmonth . $cday . "-" . $script_name . ".debug";

	open DEBUG, ">>../logs/$logfile";
	print DEBUG "\n\n<----------------- " . $cdatetime . " ----------------->\n\n";
	print DEBUG "BEGIN GLOBAL VARIABLES\n";
	print DEBUG "======================\n";
	print DEBUG "\$remote_ip: " . $remote_ip . "\n";
	print DEBUG "\$uri_path: " . $uri_path . "\n";
	print DEBUG "\$uri_absolute_path: " . $uri_absolute_path . "\n";
	print DEBUG "\$script_name: " . $script_name . "\n";
	print DEBUG "\$http_user_agent: " . $http_user_agent . "\n";
	print DEBUG "\$vici_db_host: " . $vici_db_host . "\n";
	print DEBUG "\$vici_db_port: " . $vici_db_port . "\n";
	print DEBUG "\$vici_db_name: " . $vici_db_name . "\n";
	print DEBUG "\$vici_db_user: " . $vici_db_user . "\n";
	print DEBUG "\$vici_db_pass: " . $vici_db_pass . "\n";
	print DEBUG "\n";
	close DEBUG;
	
}

#&mydebug();

# Begin main script logic
my $extension;
my $dialplan_number;
my $server_ip;
my $voicemail_id;
my $phone_type;
my $fullname;
my $company;
my $park_on_extension;
my $conf_on_extension;
my $monitor_prefix;
my $recording_exten;
my $voicemail_exten;
my $voicemail_dump_exten;
my $outbound_cid;
my $phone_ring_timeout;
my $conf_secret;
my $codecs_list;
my $dtmf_send_extension;

my $uri_mac_addr;
my $uri_xml_file;

($uri_xml_file, $uri_mac_addr) = ($1, $2) if $uri_path =~ /(cfg)([0-9a-z]{12})\.xml$/i;
($uri_xml_file, $uri_mac_addr) = ($1, $2) if $uri_path =~ /(screen)([0-9a-z]{12})\.xml$/i;

if ($uri_mac_addr eq $ua_mac_addr) {

	my $sth = $dbh->prepare("SELECT extension,
									dialplan_number,
									server_ip,
									voicemail_id,
									phone_type,
									fullname,
									company,
									park_on_extension,
									conf_on_extension,
									monitor_prefix,
									recording_exten,
									voicemail_exten,
									voicemail_dump_exten,
									outbound_cid,
									phone_ring_timeout,
									conf_secret,
									codecs_list,
									dtmf_send_extension
							 FROM phones
							 WHERE on_hook_agent = \'Y\'
							 AND phone_type LIKE \'\%$ua_mac_addr\%\'");
	$sth->execute();

	$sth->bind_col(1,\$extension);
	$sth->bind_col(2,\$dialplan_number);
	$sth->bind_col(3,\$server_ip);
	$sth->bind_col(4,\$voicemail_id);
	$sth->bind_col(5,\$phone_type);
	$sth->bind_col(6,\$fullname);
	$sth->bind_col(7,\$company);
	$sth->bind_col(8,\$park_on_extension);
	$sth->bind_col(9,\$conf_on_extension);
	$sth->bind_col(10,\$monitor_prefix);
	$sth->bind_col(11,\$recording_exten);
	$sth->bind_col(12,\$voicemail_exten);
	$sth->bind_col(13,\$voicemail_dump_exten);
	$sth->bind_col(14,\$outbound_cid);
	$sth->bind_col(15,\$phone_ring_timeout);
	$sth->bind_col(16,\$conf_secret);
	$sth->bind_col(17,\$codecs_list);
	$sth->bind_col(18,\$dtmf_send_extension);

	if ($sth->fetch()) {
	
		if ($uri_xml_file eq "cfg") {
		
			my ($phone_model, $mac_addr) = split(/,/,$phone_type);
	
			my $cfg_path = $base_cfg_dir . '/' . $phone_model . '/template.xml';
		
			#print $cgi->header();
			print "Content-type: text/xml\n\n"; 
			#print "Content-Type:application/octet-stream; name=\"" . $mac_addr . "\"\r\n";
			#print "Content-Disposition: attachment; filename=\"" . $mac_addr . "\"\r\n\n";

			open CFGFILE, $cfg_path;
			while (<CFGFILE>) {
				$_ =~ s/\%extension\%/$extension/g;
				$_ =~ s/\%dialplan_number\%/$dialplan_number/g;
				$_ =~ s/\%server_ip\%/$server_ip/g;
				$_ =~ s/\%voicemail_id\%/$voicemail_id/g;
				$_ =~ s/\%fullname\%/$fullname/g;
				$_ =~ s/\%company\%/$company/g;
				$_ =~ s/\%park_on_extension\%/$park_on_extension/g;
				$_ =~ s/\%conf_on_extension\%/$park_on_extension/g;
				$_ =~ s/\%monitor_prefix\%/$monitor_prefix/g;
				$_ =~ s/\%recording_exten\%/$recording_exten/g;
				$_ =~ s/\%voicemail_exten\%/$voicemail_exten/g;
				$_ =~ s/\%voicemail_dump_exten\%/$voicemail_dump_exten/g;
				$_ =~ s/\%outbound_cid\%/$outbound_cid/g;
				$_ =~ s/\%phone_ring_timeout\%/$phone_ring_timeout/g;
				$_ =~ s/\%conf_secret\%/$conf_secret/g;
				$_ =~ s/\%codecs_list\%/$codecs_list/g;
				$_ =~ s/\%dtmf_send_extension\%/$dtmf_send_extension/g;
				$_ =~ s/\%phone_model\%/$phone_model/g;
				$_ =~ s/\%mac_addr\%/$mac_addr/g;
				$_ =~ s/\%script_name\%/$script_name/g;
				print $_;
			}
			close CFGFILE;
			
		} elsif ($uri_xml_file eq "screen") {
		
			my ($phone_model, $mac_addr) = split(/,/,$phone_type);
		
			my $cfg_path = $base_cfg_dir . '/' . $phone_model . '/screentemplate.xml';
		
			#print $cgi->header();
			print "Content-type: text/xml\n\n"; 
			#print "Content-Type:application/octet-stream; name=\"" . $mac_addr . "\"\r\n";
			#print "Content-Disposition: attachment; filename=\"" . $mac_addr . "\"\r\n\n";

			open SCREENFILE, $cfg_path;
			while (<SCREENFILE>) {
				$_ =~ s/\%extension\%/$extension/g;
				$_ =~ s/\%dialplan_number\%/$dialplan_number/g;
				$_ =~ s/\%server_ip\%/$server_ip/g;
				$_ =~ s/\%voicemail_id\%/$voicemail_id/g;
				$_ =~ s/\%fullname\%/$fullname/g;
				$_ =~ s/\%company\%/$company/g;
				$_ =~ s/\%park_on_extension\%/$park_on_extension/g;
				$_ =~ s/\%conf_on_extension\%/$park_on_extension/g;
				$_ =~ s/\%monitor_prefix\%/$monitor_prefix/g;
				$_ =~ s/\%recording_exten\%/$recording_exten/g;
				$_ =~ s/\%voicemail_exten\%/$voicemail_exten/g;
				$_ =~ s/\%voicemail_dump_exten\%/$voicemail_dump_exten/g;
				$_ =~ s/\%outbound_cid\%/$outbound_cid/g;
				$_ =~ s/\%phone_ring_timeout\%/$phone_ring_timeout/g;
				$_ =~ s/\%conf_secret\%/$conf_secret/g;
				$_ =~ s/\%codecs_list\%/$codecs_list/g;
				$_ =~ s/\%dtmf_send_extension\%/$dtmf_send_extension/g;
				$_ =~ s/\%phone_model\%/$phone_model/g;
				$_ =~ s/\%mac_addr\%/$mac_addr/g;
				$_ =~ s/\%script_name\%/$script_name/g;
				print $_;
			}
			close SCREENFILE;
			
		}
	
	} else {

		print $cgi->header();

	}

} else {

	print $cgi->header();

}