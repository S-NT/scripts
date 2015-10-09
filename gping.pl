#!/usr/bin/perl
# Console histogram visualization for ping, v.0.7.1
#
#The MIT License (MIT)
#Copyright (c) 2015 S-NT
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

use strict;
use warnings;
#use v5.10;

$SIG{QUIT} = sub { my $dummy = "ignore" };
$SIG{INT} = \&handle_SIGINT;

my $ping_c = "/usr/bin/ping";
die "$ping_c not found: $!" unless -e "/usr/bin/ping";

unless (@ARGV) {
  print "SYNTAX:\n\tgping.pl <host|ip-adress>\n\t^\\\tshow stats\n\t^C\tshow stats and exit\n";
  exit 0;
}

my $ping_params = join(" ",  @ARGV);

# Initial maximum latency threshold, in ms
my $max_latency=50;
# Stable ping threshold, concerning the current $max_latency value, in percent
my $threshold=30;
# Inits
my $stable_ping=0;
my $last_packet_num=0;
# Graph width, default is 52
my $max_blocks=52;
# Default block's icon is '-'
my $block_icon='-';

my $ping_pid = open(my $PING, "$ping_c $ping_params |") or die "Cannot start ping: $!";

sub handle_SIGINT {
  kill('SIGINT', $ping_pid);
}

while ( defined(my $ping_line = <$PING>) ){
  chomp $ping_line;
  my $packet_count = 0;
  my $latency = 0;
  my $blocks = 1;
  my $graph_color;
  if ( $ping_line =~ /icmp_seq=(?<r_count>\d+)\sttl=\d+\stime=(?<r_time>[\d.]+)\sms/ ){
    $packet_count = $+{r_count};
    $latency = $+{r_time};

    if ( $latency > $max_latency ) {
      $max_latency = $latency;
      $blocks = $max_blocks;
      $stable_ping = 0;
    }
    else {
      $blocks = int( $latency * $max_blocks / $max_latency + 1 );
      if ( $latency <= ($max_latency*$threshold/100) ){
        $stable_ping += 1; 
      }
      else { $stable_ping = 0; }
    }

    # Decreasing the $max_latency by 20% if last 30 packets haven't exceeded the $threshold
    if ( $stable_ping == 30 ){
      $max_latency = int( $max_latency * 0.8 );
      $stable_ping = 0;
      $graph_color = 37;
    }

    unless ($graph_color){
      my $blocks_percent = int( $latency*100/$max_latency );
      if ( $blocks_percent <= 25 ){
        $graph_color = 35;
      }
      elsif ( $blocks_percent <= 45 ){
        $graph_color = 32;
      }
      elsif ( $blocks_percent <= 75 ){
        $graph_color = 33;
      }
      else {
        $graph_color = 31;
      }
    }

    if ( ($last_packet_num + 1) < $packet_count ){
      print "-\t\e[31m\?\tpacket loss\e[0m\n";
      $stable_ping = 0;
    }
    $last_packet_num = $packet_count;

    my $graph_line = $block_icon x $blocks . " " x ( $max_blocks - $blocks );
    print "$packet_count\t$latency\t\e[${graph_color}m$graph_line\e[0m  $max_latency\n";
  }
  else {
    print $ping_line . "\n";
    print "Packet\tLatency, ms\t\t\tInfo\t\t\tRange max, ms\n" if ( $ping_line =~ /\APING\s\w+/ );
  }
}
close($PING);
