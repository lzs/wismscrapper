#!/usr/bin/perl

use strict;
use JSON;
use File::Temp qw/ :POSIX /;
use Data::Dumper;
use Digest::SHA;
use Getopt::Long;

sub fetch_clientlist($$);
sub parse_client($);
sub print_row($$);
sub do_help();

    my $USER;
    my $PASS;
    my $HOST;
    my $url;
    my $format = "macaddr,name,ap";
    my $quiet_flag;
    my $total_flag;

    my @clientlist;

    my $PAGESIZE = 100;

    if (GetOptions('u=s' => \$USER,
                   'p=s' => \$PASS,
                   'h=s' => \$HOST,
                   'f=s' => \$format,
                   'q' => \$quiet_flag,
                   't' => \$total_flag
                   ) == 0) {
        do_help();
        die;
    }

    my $url = "https://$HOST/data/client-table.html?take=$PAGESIZE&sort[0][field]=Name&sort[0][dir]=desc&skip=";

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

    if (!defined $quiet_flag || !$quiet_flag) {
        foreach my $i (@clientlist) {
            print_row($i, $format);
        }
    }

    if (defined $total_flag && $total_flag) {
        print "Total clients: $total_entries\n";
    }

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

sub print_row($$)
{
    my ($data, $format) = @_;
    my @output;

    foreach my $i (split /,/, $format) {
        if ($i eq 'macaddr') {
            push @output, $data->{'macaddr'};
        }
        elsif ($i eq 'hmacaddr') {
            push @output, Digest::SHA::sha224_hex($data->{'macaddr'});
        }
        elsif ($i eq 'ssid') {
            push @output, $data->{'SSID'};
        }
        elsif ($i eq 'ut') {
            push @output, $data->{'UT'};
        }
        elsif ($i eq 'pt') {
            push @output, $data->{'PT'};
        }
        elsif ($i eq 'devtype') {
            push @output, $data->{'devtype'};
        }
        elsif ($i eq 'sd') {
            push @output, $data->{'sd'};
        }
        elsif ($i eq 'name') {
            push @output, $data->{'Name'};
        }
        elsif ($i eq 'hname') {
            push @output, Digest::SHA::sha224_hex($data->{'Name'});
        }
        elsif ($i eq 'ss') {
            push @output, $data->{'SS'};
        }
        elsif ($i eq 'bytes_total') {
            push @output, $data->{'bytes_total'};
        }
        elsif ($i eq 'st') {
            push @output, $data->{'ST'};
        }
        elsif ($i eq 'ap') {
            push @output, $data->{'AP'};
        }
        elsif ($i eq 'ts') {
            push @output, time();
        }
    }
    print join(',', @output) . "\n";
}

sub do_help()
{
    print <<EOM;
$0 <arguments>

  --u user    Username for authentication
  --p pass    Password for authentication
  --h host    Hostname or IP of WISM controller
  --f str     Print with specified format string
EOM
}
