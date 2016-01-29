#!/usr/bin/perl
# Brief system analysis, v.0.5.4
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
# Notify, if there any cron job running for more than $cron_threshold seconds (N)
# or minutes ('Nm')
my $cron_threshold = '30m';

# External utilities:
my $df_sys = 'df';
my $ps_sys = 'ps';
# crond binary can be named as either 'crond' or 'cron'
my $crond_sys = '/usr/sbin/crond';
$crond_sys = '/usr/sbin/cron' unless ( -e $crond_sys );
undef $crond_sys unless ( -e $crond_sys );

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
  print "\n  (!) Filesystems with more than ${df_threshold}% of used space:\n\n";
  print "$_\n" for (@df_data);
}


# Checking for 'hungry' processes: CPU and MEM
find_path( \$ps_sys );
my @mem_values;
my @mem_lines;

my @cron_data;
my @crond_pids;
my @cron_jobs;
my @zombies;

open(my $PS, "$ps_sys axo euser,pid,ppid,pcpu,pmem,tname,state,time,etime,args --sort -time,-pcpu |");

print "\n\n  TOP-$ps_cpu_top of CPU consumption:\n\n";
while ( defined(my $line = <$PS>) ){
  chomp $line;
  # Displaying CPU Top right now
  print "$line\n" if ( $. <= ($ps_cpu_top + 1) );
  # Adding the ps header to other stat categories
  if ( $. == 1 ){
    push(@cron_jobs, $line);
    push(@zombies, $line);
    @mem_values = ( 0 );
    @mem_lines = ( $line );
    next;
  }
  # Using two arrays for manual sorting of ps output, because
  # older versions of ps cannot sort output by MEM usage:
  #   @mem_values atm contains current sorted memory values
  #   @mem_lines atm contains corresponding ps lines
  # Size of each array is strictly limited to $ps_mem_top elements
  if ( $line =~ /\A\w+\s+(\d+\s+){2}[\d.]+\s+([\d.]+)\s+[\w?\/]+\s+\w\s+([\d\:-]+\s+){2}.+\z/ ){
    my $lines_stored = @mem_values;
    my $current_value = $2;
    if ($lines_stored == 1){
      $mem_values[$lines_stored] = $current_value;
      $mem_lines[$lines_stored]  = $line;
    }
    else{
      for my $index ( reverse(1 .. $#mem_values) ){
        if ( $current_value > $mem_values[$index] ){
          if ( $index < ($ps_mem_top - 1) ){
            $mem_values[($index + 1)] = $mem_values[$index];
            $mem_lines[($index + 1)]  = $mem_lines[$index];
            $mem_values[$index] = $current_value;
            $mem_lines[$index]  = $line;
          }
          else{
            $mem_values[$index] = $current_value;
            $mem_lines[$index]  = $line;
          }
        }
        else{
          if ( $index < ($ps_mem_top - 1) ){
            $mem_values[($index + 1)] = $current_value;
            $mem_lines[($index + 1)]  = $line;
          }
          last;
        }
      }
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

      # Converting elapsed time from [[DD-]hh:]mm:ss format to seconds
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
        print "(?) Something wrong with 'etime' format\n";
        next;
      }
      my $elapsed_seconds = ( ${days}*24*3600 + ${hours}*3600 + ${minutes}*60 + $seconds);
      # End of the conversion block

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
  print "(!) Cannot find crond binary: cron stats would be unavailable\n";
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
