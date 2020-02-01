#!/usr/bin/perl

use strict;

use File::Temp qw/ :POSIX /;

use Getopt::Long;

sub parse_client($);

    my $USER;
    my $PASS;
    my $HOST;
    my $url;
    my $total_entries;

    if (GetOptions('user=s' => \$USER,
                   'pass=s' => \$PASS,
                   'host=s' => \$HOST) == 0) {
        die;
    }

    my $url = "https://$HOST/screens/apf/mobile_station_list.html?pgInd=1";

    my $cookiefile = tmpnam();

    # Login to get session cookie, no need the output
    my $OUT = qx(wget --keep-session-cookies --save-cookies $cookiefile --no-check-certificate --user $USER --password $PASS $url -O - 2> /dev/null);

    $OUT = qx(wget --load-cookies $cookiefile  --no-check-certificate --user $USER --password $PASS $url -O - 2> /dev/null);

    if ($OUT =~ /total_entries" VALUE="(\d+)"/s) {
        $total_entries = $1;
        print "DEBUG total_entries = $total_entries\n";
    }

    while ($OUT =~ /<tr>(.*?)<\/tr>/gs) {
        my $row = $1;
        if ($row =~ /var indexVal =(\d+);/s) {
            parse_client($row);
        }
    }

    unlink $coookiefile;

    exit;

sub parse_client($)
{
    my ($row) = @_;

    print "***\n";
    my @fields = ($row =~ /VALUE="(.*?)"/g);
    print join(', ', @fields) . "\n";

}
