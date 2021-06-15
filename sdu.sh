#!/bin/sh
# Sorted du (disk usage) output, v.1.0.3
#
#The MIT License (MIT)
#Copyright (c) 2021 S-NT  (https://github.com/S-NT/scripts)
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

script_name=`basename $0`
du_sys=/usr/bin/du
sort_sys=/usr/bin/sort

# Checking for alternative path to 'sort' (CentOS related)
if [ ! -x "$sort_sys" ]
  then
    sort_sys=/bin/sort
    if [ ! -x "$sort_sys" ]
      then
        echo "(x) Cannot find 'sort' executable!"
        exit 2
    fi
fi


show_help() {
  echo -e "SYNTAX:\n\t${script_name} [-b|-k|-m|-g] <path_to_directory>"
  echo -e "\t-b\tscale sizes by Bytes"
  echo -e "\t-k\tscale sizes by KB"
  echo -e "\t-m\tscale sizes by MB, default option"
  echo -e "\t-g\tscale sizes by GB"
}


while getopts bkmg opt
  do
    case "$opt" in
      b)
        block_size="1"
        units="bytes"
      ;;
      k)
        block_size="1K"
        units="KB"
      ;;
      m)
        block_size="1M"
        units="MB"
      ;;
      g)
        block_size="1G"
        units="GB"
      ;;
      *)
        show_help
        exit 1
      ;;
    esac
  done

if [ -z "$block_size" ]
  then
    block_size="1M"
    units="MB"
fi

shift $(($OPTIND - 1)) && path=$1

if [ -z "$path" ]
  then
    show_help
    exit 1
fi

echo " [ ${units} ]"
${du_sys} -a --block-size="${block_size}" --max-depth=1 "${path}" | ${sort_sys} -n

exit 0
