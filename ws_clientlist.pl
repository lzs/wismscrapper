#!/usr/bin/perl

use strict;

use File::Temp qw/ :POSIX /;

use Getopt::Long;

    my $USER;
    my $PASS;
    my $HOST;
    my $url;

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

    print "DEBUG\n";
    print $OUT;
