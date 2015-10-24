#!/usr/bin/perl
# Analysis of user shell accounts, v.0.5.3
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

use strict;
use warnings;
use v5.8.8;

my $passwd_sys='/etc/passwd';
my $shadow_sys='/etc/shadow';

open(my $PASSWD, "< $passwd_sys") or die "(x) Cannot open $passwd_sys for reading: $!";

# All primary data would be placed into %shells hash of arrays of arrays, where
# hash keys suit for shell-grouping and every array of arrays holds all related
# user data in table form
my %shells;
my %shadow;
my @cols_width = (0) x 7;

# Processing the 'shadow' data (optional):
# locked   - password authentication is unavailable, but any other method is allowed
# disabled - current account is disabled for logging in
# !EMPRY!  - this account has no password set (password is empty!)
# !set     - current account has a password
if ( -r $shadow_sys ){
  open(my $SHADOW, "< $shadow_sys");
  while ( defined( my $readline = <$SHADOW>) ){
    chomp $readline;
    my ($name, $pass_type) = split(':', $readline);
    if ( $pass_type =~ /\A!!?([\w\$.\/]+)?\z/i ){
      $shadow{$name}="locked";
    }
    elsif ( $pass_type =~ /\A\*\z/ ){
      $shadow{$name}="disabled";
    }
    elsif ( $pass_type =~ /\A\z/ ){
      $shadow{$name}="!EMPTY!";
    }
    elsif ( $pass_type =~ /\A\$[\w\$.\/]+\z/ ){
      $shadow{$name}="!Set";
    }
  }
}
else{
  print "(!) Cannot open $shadow_sys for reading (non-root user?)\n";
}

while ( defined( my $readline = <$PASSWD>) ){
  chomp $readline;
  my ($name, $pass, $uid, $gid, $comment, $home, $sh) = split(':', $readline);
  my @headers = qw(Name Password UID GID Home Comment);
  if (exists $shadow{$name}){
    $pass=$shadow{$name};
  }
  else{
    $pass="n/a";
  }

  my @user_data = ($name, $pass, $uid, $gid, $home, $comment);
  # Determining the columns width
  for my $i (0 .. $#user_data){
    if ( length($user_data[$i]) > $cols_width[$i] ){
      $cols_width[$i]=length($user_data[$i]);
    }
    if ( length($headers[$i]) > $cols_width[$i] ){
      $cols_width[$i]=length($headers[$i]);
    }
  }

  unless(exists $shells{$sh}){
    push @{ $shells{$sh}->[0] }, @headers;
    push @{ $shells{$sh}->[1] }, @user_data;
  }
  else {
  my $new_index = @{ $shells{$sh} };
  push @{ $shells{$sh}->[$new_index] }, @user_data;
  }
}

for my $sh (sort keys %shells){
  print "\n   [$sh]\n";
  for my $i ( 0 .. $#{ $shells{$sh} }){
    printf("%-$cols_width[0]s %-$cols_width[1]s  %-$cols_width[2]s %-$cols_width[3]s %-$cols_width[4]s %-$cols_width[5]s\n", @{ $shells{$sh}->[$i] });
  }
}
