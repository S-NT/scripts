#!/bin/sh
# Sorted du (disk usage) output, v.0.1.1
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

script_name=`echo $0 | sed "s/^.\+\///gi"`
du_sys=/usr/bin/du
sort_sys=/usr/bin/sort

if [ -z "$1" ]
  then
    echo -e "SYNTAX:\n\t${script_name} /path/to/directory"
    exit 1
fi

# Checking for alternative path to 'sort' (CentOS related)
if [ ! -x $sort_sys ]
  then
    sort_sys=/bin/sort
    if [ ! -x $sort_sys ]
      then
        echo "(x) Cannot find 'sort' executable!"
        exit 2
    fi
fi

$du_sys -am --max-depth=1 "$1" | $sort_sys -n

exit 0
