#!/usr/bin/perl

use strict;

use File::Temp qw/ :POSIX /;

use Getopt::Long;

sub fetch_pagelis($$);
sub parse_client($);
sub do_help();

    my $USER;
    my $PASS;
    my $HOST;
    my $url;
    my @clientlist;

    if (GetOptions('user=s' => \$USER,
                   'pass=s' => \$PASS,
                   'host=s' => \$HOST) == 0) {
        do_help();
        die;
    }

    my $url = "https://$HOST/screens/apf/mobile_station_list.html?pgInd=";

    my $cookiefile = tmpnam();

    # Login to get session cookie, no need the output
    my $OUT = qx(wget --keep-session-cookies --save-cookies $cookiefile --no-check-certificate --user $USER --password $PASS $url -O - 2> /dev/null);

    my $page = 0;
    my $total_rows_found = 0;
    my $total_entries = 0;
    do {
        my $rows_found;

        $page++;
        ($rows_found, $total_entries) = fetch_pagelist($page, \@clientlist);
        $total_rows_found += $rows_found;
    } until ($total_rows_found >= $total_entries);

    unlink $cookiefile;

    foreach (@clientlist) {
        print join(', ', split(/\t/, $_)) . "\n";
    }
    print "Total clients: $#clientlist\n";
    exit;

sub fetch_pagelist($$)
{
    my ($page, $clientlist) = @_;
    my $rows_found = 0;
    my $total_entries;

    $OUT = qx(wget --load-cookies $cookiefile  --no-check-certificate --user $USER --password $PASS $url$page -O - 2> /dev/null);

    if ($OUT =~ /total_entries" VALUE="(\d+)"/s) {
        $total_entries = $1;
    }

    while ($OUT =~ /<tr>(.*?)<\/tr>/gs) {
        my $row = $1;
        if ($row =~ /var indexVal =(\d+);/s) {
            my @client = parse_client($row);
            push @$clientlist, join("\t", @client);
            $rows_found++;
        }
    }
    return ($rows_found, $total_entries);
}

sub parse_client($)
{
    my ($row) = @_;

    # Fields are: Client MAC Addr, IP Address, AP Name, WLAN Profile,
    #             WLAN SSID, User Name, Protocol, Status, Auth, Port,
    #             Slo Id, Tunnel, Fastlane, PMIPv6, WGB, Device Type,
    #             Fabric Status, U3 Interface
    my @fields = ($row =~ /<td.*?VALUE="(.*?)".*?<\/td>/gs);

    return @fields[0..7];
}

sub do_help()
{

}
