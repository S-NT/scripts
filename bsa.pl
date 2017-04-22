#!/usr/bin/perl
# Brief system analysis, v.0.5.8
#
#The MIT License (MIT)
#Copyright (c) 2015 S-NT  (https://github.com/S-NT/scripts)
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

use warnings;
use strict;
#use v5.10;
use v5.8;

# Global settings:

my $terminal_lang = 'LANG=en_US';
# How many items CPU/MEM Top should contain
my $ps_cpu_top = 10;
my $ps_mem_top = 10;
# Notify, if used space for any local filesystem reached next threshold (in percent)
my $df_threshold = 85;
# Notify, if any local filesystem reaches the threshold of used inodes (in percent)
my $inode_threshold = 50;
# Notify, if there any cron job running for more than $cron_threshold seconds (N)
# or minutes ('Nm')
my $cron_threshold = '30m';

# External utilities:
my $df_sys = 'df';
my $ps_sys = 'ps';
my $uptime_sys = '/usr/bin/uptime';
# crond binary can be named as either 'crond' or 'cron'
my $crond_sys = '/usr/sbin/crond';
$crond_sys = '/usr/sbin/cron' unless ( -e $crond_sys );
undef $crond_sys unless ( -e $crond_sys );


# Functions

sub find_path {
  my $utility = shift;
  my @paths = qw( /usr/bin/ /bin/ );
  for my $path (@paths){
    if ( -x "${path}${ $utility }" ){
      ${ $utility } = "${path}${ $utility }";
      return;
    }
  }
  die "(x) Cannot find ${ $utility }: $!";
}

# Subroutine for converting elapsed time from [[DD-]hh:]mm:ss format
# to seconds
sub etime2seconds {
  my $elapsed_time = shift;
  my $days = 0;
  my ( $hours, $minutes, $seconds );
  if ( $elapsed_time =~ /\A(\d+)-/ ){
    $days = $1 ;
  }
  if ($elapsed_time =~ /(\d+):(\d+):(\d+)\z/ ){
    ( $hours, $minutes, $seconds ) = ($1, $2, $3);
  }
  elsif ($elapsed_time =~ /(\d+):(\d+)\z/ ){
    ( $hours, $minutes, $seconds ) = (0, $1, $2);
  }
  else {
    print "(?) Something wrong with 'etime' format: ($elapsed_time)\n";
    return -1;
  }
  return ( ${days}*24*3600 + ${hours}*3600 + ${minutes}*60 + $seconds);
}

# Subroutine, used for sorting pairs of arrays with ps data
sub sort_array_data {
  my ( $a_values, $a_lines, $current_value, $line, $top_size ) = @_;
  for my $index ( reverse(1 .. $#{ $a_values }) ){
    if ( $current_value > ${ $a_values }[$index] ){
      if ( $index < $top_size ){
        ${ $a_values }[($index + 1)] = ${ $a_values }[$index];
        ${ $a_lines }[($index + 1)]  = ${ $a_lines }[$index];
        ${ $a_values }[$index] = $current_value;
        ${ $a_lines }[$index]  = $line;
      }
      else{
        ${ $a_values }[$index] = $current_value;
        ${ $a_lines }[$index]  = $line;
      }
    }
    else{
      if ( $index < $top_size ){
        ${ $a_values }[($index + 1)] = $current_value;
        ${ $a_lines }[($index + 1)]  = $line;
      }
      last;
    }
  }
}


# Show current uptime

print "\n  Uptime info:\n\n";
if ( -x $uptime_sys ){
  system("$terminal_lang $uptime_sys");
}
else{
  print "(x) Cannot execute ${uptime_sys}: $!";
}


# Checking for the filesystems with low free space

find_path( \$df_sys );
my @df_data;
# Workaround for lines with too long named devices
my $broken_line;

open(my $DF, "$terminal_lang $df_sys -Th |");

while ( defined(my $line = <$DF>) ){
  chomp $line;
  if ( $. == 1 ){
    push(@df_data, $line);
    next;
  }
  my $used_space = $line;
  if ( $used_space =~ /.+\s(\d+)%\s.+/ ){
    $used_space = $1;
    if ( defined($broken_line) ){
      $line =~ s/\A\s+/ /;
      $line = $broken_line . " " . $line;
      undef $broken_line;
    }
    push(@df_data, $line) if ( $used_space >= $df_threshold );
  }
  else{
    $broken_line = $line;
  }
}

close($DF);

if ( @df_data > 1 ){
  print "\n\n  (!) Filesystems with more than ${df_threshold}% of used space:\n\n";
  print "$_\n" for (@df_data);
}


# Checking for the filesystems with high inode usage

undef @df_data;
undef $DF;
# Workaround for lines with too long named devices
undef $broken_line;

open($DF, "$terminal_lang $df_sys -Thi |");

while ( defined(my $line = <$DF>) ){
  chomp $line;
  if ( $. == 1 ){
    push(@df_data, $line);
    next;
  }
  my $used_inodes = $line;
  if ( $used_inodes =~ /.+\s(\d+)%\s.+/ ){
    $used_inodes = $1;
    if ( defined($broken_line) ){
      $line =~ s/\A\s+/ /;
      $line = $broken_line . " " . $line;
      undef $broken_line;
    }
    push(@df_data, $line) if ( $used_inodes >= $inode_threshold );
  }
  else{
    $broken_line = $line;
  }
}

close($DF);

if ( @df_data > 1 ){
  print "\n\n  (!) Filesystems with more than ${inode_threshold}% of used inodes:\n\n";
  print "$_\n" for (@df_data);
}


# Checking for 'hungry' processes: CPU and MEM

find_path( \$ps_sys );
my @cpu_values;
my @cpu_lines;
my @mem_values;
my @mem_lines;

my @cron_data;
my @crond_pids;
my @cron_jobs;
my @zombies;

open(my $PS, "$ps_sys axo euser,pid,ppid,pcpu,pmem,tname,state,time,etime,args |");

while ( defined(my $line = <$PS>) ){
  chomp $line;
  # Adding the ps header to every stat category
  if ( $. == 1 ){
    push(@cron_jobs, $line);
    push(@zombies, $line);
    @cpu_values = ( 0 );
    @cpu_lines = ( $line );
    @mem_values = ( 0 );
    @mem_lines = ( $line );
    next;
  }
  # Using two pairs of arrays for manual sorting of ps output,
  # because older versions of ps cannot sort output by CPUtime
  # or MEM usage:
  #   @cpu_values atm contains current sorted CPUtime values
  # (in seconds)
  #   @cpu_lines atm contains corresponding ps lines
  #
  #   @mem_values atm contains current sorted memory values
  #   @mem_lines atm contains corresponding ps lines
  # Size of each array is strictly limited to $ps_cpu_top or
  # to $ps_mem_top elements respectively

  # Populating and sorting arrays for CPU-Top
  if ( $line =~ /\A(\S+\s+){7}([\d\:-]+)\s+\S.+\z/ ){
    my $lines_stored = @cpu_values;
    my $current_value = etime2seconds($2);
    if ($lines_stored == 1){
      $cpu_values[$lines_stored] = $current_value;
      $cpu_lines[$lines_stored]  = $line;
    }
    else{
      sort_array_data( \@cpu_values, \@cpu_lines, $current_value, $line, $ps_cpu_top );
    }
  }
  # Populating and sorting arrays for MEM-Top
  if ( $line =~ /\A(\S+\s+){4}([\d.]+)\s+\S.+\z/ ){
    my $lines_stored = @mem_values;
    my $current_value = $2;
    if ($lines_stored == 1){
      $mem_values[$lines_stored] = $current_value;
      $mem_lines[$lines_stored]  = $line;
    }
    else{
      sort_array_data( \@mem_values, \@mem_lines, $current_value, $line, $ps_mem_top );
    }
  }
  # Populating @cron_data array
  push(@cron_data, $line);
  # Searching for crond service PID(s)
  if ( $line =~ /\A\S+\s+(\d+)\s+1\s+(\S+\s+){6}\S*cron.+\z/ ){
    push(@crond_pids, $1);
  }
  # Populating @zombies array, if any found
  if ( $line =~ /\A\w+\s+(\d+\s+){2}([\d.]+\s+){2}[\w?\/]+\s+Z\s+([\d\:-]+\s+){2}.+\z/ ){
    push(@zombies, $line);
  }
}

close($PS);

print "\n\n  TOP-$ps_cpu_top of CPU consumption:\n\n";
print "$_\n" for (@cpu_lines);

print "\n\n  TOP-$ps_mem_top of memory consumption:\n\n";
print "$_\n" for (@mem_lines);


# Finding the long running cron jobs

sub find_cron_jobs {
  my $crond_pid = shift;
  my @crond_children_pids;
  for my $line (@cron_data){
    push (@crond_children_pids, $1) if ( $line =~ /\A\S+\s+(\d+)\s+${crond_pid}\s+(\S+\s+){6}\S*cron.+\z/i );
  }
  return unless (@crond_children_pids);
  my $search_pattern = join('|', @crond_children_pids);
  for my $line (@cron_data){
    if ( $line =~ /\A\S+\s+\d+\s+(${search_pattern})\s+(\S+\s+){5}([\d:-]+)\s+.+\z/ ){
      my $elapsed_time = $3;

      my $elapsed_seconds = etime2seconds($elapsed_time);
      next if ($elapsed_seconds == -1 );

      my $threshold = $cron_threshold;
      # Converting threshold to seconds if minutes are used
      $threshold = ${1}*60 if ( $threshold =~ /(\d+)m/ );
      push(@cron_jobs, $line) if ( $elapsed_seconds >= $threshold );
    }
  }
}

if ( defined($crond_sys) ){
    if ( @crond_pids > 1 ){
      my $amount = @crond_pids;
      print "(!) Probably you have got $amount crond services running concurrently\n";
    }
    else{
      find_cron_jobs(@crond_pids);
    }
}
else{
  print "(x) Cannot find crond binary: cron stats would be unavailable\n";
}

# Printing @cron_jobs if there any data
if (@cron_jobs > 1){
  if ( $cron_threshold =~ /(\d+)m/ ){
    print "\n\n  (!) Cron task(s), running for more than $1 minute(s):\n\n";
  }
  else{
    print "\n\n  (!) Cron task(s), running for more than $cron_threshold second(s):\n\n";
  }
  print "$_\n" for (@cron_jobs);
}


# Printing @zombies array, if we've got any data

if (@zombies > 1){
  my $amount = (@zombies - 1);
  print "\n\n  (!) $amount zombie process(es) found:\n\n";
  print "$_\n" for (@zombies);
}
