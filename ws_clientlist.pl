#!/usr/bin/perl

use strict;
use JSON;
use File::Temp qw/ :POSIX /;
use Data::Dumper;

use Getopt::Long;

sub fetch_clientlist($$);
sub parse_client($);
sub do_help();

    my $USER;
    my $PASS;
    my $HOST;
    my $url;
    my @clientlist;

    my $PAGESIZE = 100;

    if (GetOptions('user=s' => \$USER,
                   'pass=s' => \$PASS,
                   'host=s' => \$HOST) == 0) {
        do_help();
        die;
    }

    my $url = "https://$HOST/data/client-table.html?take=$PAGESIZE&sort[0][field]=Name&sort[0][dir]=desc&skip=";
    #my $url = "https://$HOST/screens/apf/mobile_station_list.html?pgInd=";

    my $cookiefile = tmpnam();

    # Login to get session cookie, no need the output
    my $OUT = qx(wget --keep-session-cookies --save-cookies $cookiefile --no-check-certificate --user $USER --password $PASS '$url' -O - 2> /dev/null);


    my $total_rows_found = 0;
    my $total_entries = 0;
    do {
        my $rows_found;

        ($rows_found, $total_entries) = fetch_clientlist($total_rows_found, \@clientlist);
        $total_rows_found += $rows_found;
    } until ($total_rows_found >= $total_entries);

    unlink $cookiefile;

    print Dumper(@clientlist);
    print "Total clients: $total_entries\n";

    exit;

sub fetch_clientlist($$)
{
    my ($skip, $clientlist) = @_;
    my $rows_found = 0;
    my $rows_this_fetch;

    $OUT = qx(wget --load-cookies $cookiefile  --no-check-certificate --user $USER --password $PASS '$url$skip' -O - 2> /dev/null);

    my $json = JSON->new->allow_nonref;
    my $data = $json->decode($OUT);

    $total_entries = $data->{'total'};

    push @$clientlist, @{$data->{'data'}};

    $rows_this_fetch = $#{$data->{'data'}} + 1;

    return ($rows_this_fetch, $total_entries);
}

sub do_help()
{
    print <<EOM;
$0 <arguments>

  --user user    Username for authentication
  --pass pass    Password for authentication
  --host host    Hostname or IP of WISM controller
EOM
}
