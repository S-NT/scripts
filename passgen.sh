#!/bin/sh
# Simple password generator, v.0.5.1
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

# Use /dev/urandom to avoid blocking of /dev/random device while
# generating large password lines (more than 70..90 characters long)
rnd_device=/dev/random

# Default password length
pwd_length=12

# Filter pattern, default is "[^a-zA-Z0-9]"
# To disable filtering set the filter pattern to "" (empty string)
filter="[^a-zA-Z0-9]"

if echo "$1" | egrep -qw "[0-9]{1,3}"
  then
    pwd_length=$1
fi

if echo $filter | egrep -qw "^\[.+\]$"
  then
    filter="s/"${filter}"//g; s/\(.\)\1\+/\1/g"
  else
    filter="s/=\+$/\n/g; s/\(.\)\1\+/\1/g"
fi

dd if=$rnd_device count=1 bs=512 2> /dev/null | base64 -w 0 | sed "$filter" | cut -c -${pwd_length}

exit 0
