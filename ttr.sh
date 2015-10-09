#!/bin/sh
# Tiny UT to Date translation tool, v.0.5.1
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

script_name=$(basename `echo $0`)
date_params=$*

if [ -z "$date_params" ]
  then
    echo -e "SYNTAX:\n\t${script_name} 01234567890\t\t\tConvert Unix Time to Date\n\t${script_name} 01234567890.123\n\n\t${script_name} YYYY-mm-dd HH:MM:SS\t\tConvert Date to Unix Time\n\t${script_name} YYYY-mm-dd\n\t${script_name} HH:MM"
    exit 1
fi

if echo $date_params | egrep -q "[0-9]{10}\.?[0-9]?"
  then
    date -d @${date_params} +"%F %T"
  else
    date -d $date_params +%s
fi

exit 0
