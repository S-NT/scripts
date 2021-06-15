#!/bin/sh
# User Info
username=$1
GREP_COLORS="mt=00;32"

show_help() {
  script_name=$(basename $0)
  echo -e "SYNTAX:\t${script_name} <user_name>\n\t\tor"
  echo -e "\t${script_name} \"<regular_expression>\""
}

show_info() {
  filename=$1
  echo -e "  [ ${filename} ]"
  if egrep -qi "${username}" $filename
    then
      egrep -i --color=auto "${username}" $filename
    else
      echo -e "(i) No matches found"
  fi
  echo ""
}

if [[ $username = "" ]]
  then
    show_help
    exit 0
fi

show_info /etc/passwd
show_info /etc/group
show_info /etc/aliases

exit 0
