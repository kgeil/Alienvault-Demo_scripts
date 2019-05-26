#!/usr/bin/perl
use Term::ANSIColor qw(:constants);
use Net::Ping;

#Installer
#  Add plugins and logs for plugins to ./plugins  They must all have the same basename!!!!
#  Add Pcaps to ./pcaps
#  Asset stuff in ./assets/
#
# 
# This script can be run over and over, so when in doubt just re-run this...
# Just felt like using perl this time, dunno...


my $plugin_dir = './plugins';
opendir(DIR, $plugin_dir) or die $!;

my @plugins = grep { /\.cfg$/ && -f "$plugin_dir/$_" } readdir(DIR);
closedir(DIR);


# Check Internet connection
my $p = Net::Ping->new("icmp");
print MAGENTA,, "+ Checking Internet connection\n", RESET;
    if ($p->ping("www.cisco.com")){
        print GREEN, " - Internet connection is active!\n\n", RESET;

        #Installing tcpreplay. Removed in 5.1, we need it back
		print "Installing tcpreplay....\n";
		`apt-get -y install tcpreplay`;
		print "Done.\n";
    }
    else{
        print RED, "+ Internet connection not active! Sleeping..\n\n", RESET;
        printf " - Is neccesary to install tcpreplay. Do you want to continue (Y/N)?";
        my $input = <STDIN>;
        chomp $input;
            if ($input =~ m/^[N]$/i){
                printf " - Check your connection and try again\n\n\n";
                exit 0;
            }
    }

print " - Done\n\n";

#Save names for ossim_setup
my @plugin_names;


print "+ Installing plugins for Demo use...........................\n";
foreach my $plugin (@plugins) {
	#Get basename
	my ($base) = (split /\./, $plugin)[0];
	print " - Found ", GREEN, "$base", RESET, ".  Installing...\n";
	#I want to overwrite, so not checking for existance...
	print " - Copying...";
	`cp $plugin_dir/$plugin /etc/ossim/agent/plugins/`;
	my $local = "[config]\nlocation=/var/log/demologs/$base.log\n";
	print " - Adding Local Config...";
	`echo "$local" > /etc/ossim/agent/plugins/$plugin.local`;
	if (-e "$plugin_dir/$base.sql") {
		print YELLOW, " - Found SQL...Adding..", RESET;
		`cat $plugin_dir/$base.sql | ossim-db`;
		print " - Added.";
	}
	push @plugin_names, $base;
	print " - Done\n\n";
}
print "+ Adding sonicwall events...\n";
`sonicwall/convert_sonicwall.sh`;
print " - Done\n\n";

print "+ Bringing Up Dummy Network...\n";
`modprobe dummy`;
`ifconfig dummy0 up`;
`ifconfig dummy0 promisc`;
print " - Done\n\n";

print YELLOW, "+ Adding Rsyslog config...", RESET;
`cp ./misc/aa-demo.conf /etc/rsyslog.d/`;
print CYAN, " - Restarting rsyslog...", RESET;
`service rsyslog restart`;
print " - Done\n\n";

print CYAN, "+ Adding logrotate file...", RESET;
`cp ./misc/logrotate /etc/logrotate.d/demologs`;
print " - Done\n\n";

if (-e "/etc/ossim/ossim_setup.conf.demo") {
	print CYAN, "+ Backup file already exists.\n", RESET;
} else {
	`cp /etc/ossim/ossim_setup.conf /etc/ossim/ossim_setup.conf.demo`;
	print GREEN, "+ Created Backup File of ossim_setup.\n", RESET;
}
print " - Done\n\n";


my $detectors = `grep detectors= /etc/ossim/ossim_setup.conf`;
my ($d) = (split /=/, $detectors)[1];
chomp($d);
my @d2 = split /\,\s/, $d;
my %dupecheck;
my @d3 = grep( !$dupecheck{$_}++, @d2, @plugin_names);
my $to_insert = join(', ', @d3);
print "+ Adding detectors... $to_insert ....\n";
`sed -i -e 's/detectors=.*/detectors=$to_insert/' /etc/ossim/ossim_setup.conf`;

#Adding Dummy Interface..
#I'll likely playback files with suricata, this may go away or be used only for netflow...
my $interfaces = `grep interfaces= /etc/ossim/ossim_setup.conf`;
my ($i) = (split /=/, $interfaces)[1];
chomp($i);
my @i2 = split /\,\s*/, $i;
my %dupecheck2;
my @interface_name = ('dummy0');
my @i3 = grep( !$dupecheck2{$_}++, @i2, @interface_name);
$to_insert = join(',', @i3);
print "+ Adding dummy interface... $to_insert ....\n";
`sed -i -e 's/interfaces=.*/interfaces=$to_insert/' /etc/ossim/ossim_setup.conf`;

print "+ Adding Modified ossec.conf....";
`cp ./ossecwin/ossec.conf /var/ossec/etc/`;
`ossecwin/brutewin2.sh`;
print " - Done\n";

print "+ Adding prads local...";
`cp ./assets/prads_dummy0.cfg.local /etc/ossim/agent/plugins/`;
print " - Done\n";

print "+ Finished updating ", CYAN, "ossim_setup", RESET, ".  Running re-config...\n";
`ossim-reconfig -c -v`;
print " - Waiting a bit for reconfig...\n\n";
`sleep 10`;
print YELLOW, "+ Adding assets...", RESET;
#This makes the agent wake up.  Putting these in their own place so pcaps dont change things.
`mkdir /var/log/demologs` if (!-d "/var/log/demologs");
`touch /var/log/demologs/prads.log`;
`cat ./assets/asset-playback >> /var/log/demologs/prads.log`;
`sleep 2`;
`cat ./assets/asset-playback >> /var/log/demologs/prads.log`;
print CYAN, " - Done!\n\n", RESET;


print MAGENTA, "+ Checking for vulnscan...\n", RESET;

$check_query = "select report_id from vuln_nessus_reports WHERE name = 'test3';";
$is_added = `echo "$check_query" | ossim-db`;
if (length($is_added)) {
	print " - Scan already there...skipping\n\n";
} else {
	print MAGENTA, " - Adding in a Vulnerability Scan...", RESET;
	$ctx_query = "select hex(id) as id from acl_entities WHERE entity_type = 'context' AND parent_id = unhex('00000000000000000000000000000000')";
	$ctx = `echo "$ctx_query" | ossim-db | tail -1`;
	chomp($ctx);
	print " - Using context id: ", MAGENTA, $ctx, RESET, "\n\n";
	`/usr/bin/perl -w /usr/share/ossim/scripts/vulnmeter/import_nbe.pl ./misc/demo.nbe dGVzdDM7OTg5OEVBNzExMDZBMTFFNDhDNzQwMDBDMjlCQzNGMDE= 1 -4 $ctx 0`;
}

print BLUE, "+ Stopping the generators...You may see errors if this is the first run.\n", RESET;
`service runlogs stop`;
`service runpcaps stop`;

print BLUE, "+ Adding the generators...\n", RESET;
`chmod 755 ./runlogs.pl`;
`chmod 755 ./runpcaps.pl`;
`./runlogs.pl get_init_file > /etc/init.d/runlogs`;
`./runpcaps.pl get_init_file > /etc/init.d/runpcaps`;
`chmod 755 /etc/init.d/runlogs`;
`chmod 755 /etc/init.d/runpcaps`;
print BLUE, " - Adding the generators to startup...\n\n", RESET;
`update-rc.d runlogs defaults`;
`update-rc.d runpcaps defaults`;
print BLUE, " - Starting Generators...\n\n", RESET;
`service runlogs start`;
`service runpcaps start`;
print GREEN, "+ Adding Assets Again...\n\n\n", RESET;
`cat ./assets/asset-playback >> /var/log/demologs/prads.log`;

print "All Done. Really that's it.  Login and enjoy.\n\n";

