#!/bin/bash
#
# snagdar.sh
#
# This is a quick-n-dirty script to automate downloading and extracting source
# for Darwin projects.  It has two modes, where if run with no arguments, it
# simply displays a list of all available Darin projects.  This is useful for
# viewing with less, grepping, or whatever.  Or if an argument is given, it is
# treated as a regex to filter the list, and the matching packages are
# downloaded and extracted into the current directory.  Pretty simple.
#
# Examples:
#   List all available Darwin packages:
#   $ ./snagdar.sh
#
#   Extract the source for XNU Kernel in the current directory
#   $ ./snagdar.sh xnu
#
#   Get source for bzip2 and gunzip
#   $ ./snagdar.sh ^.+zip
#
#   To see what packages will be snagged for a given regex
#   $ ./snagdar.sh | egrep ^.+zip
#

base_url="http://www.opensource.apple.com"
system_version="$(sw_vers -productVersion | awk -F. '{print $1$2$3}')"
projects_url="$base_url/text/mac-os-x-$system_version.txt"

# If no arg was specified, just display the projects file
test -z "$1" && exec curl -sL "$projects_url"

# D/l and untar all projects that match the regex in $1
exec < <(curl -bL "$cookie_file" -s "$projects_url" | grep -v ^\# | egrep "$1")
while read line
do
  tarball="$(echo "$line" | awk '{print $1"-"$2}')"
  dir="$(echo "$line" | awk '{print $1}')"
  dl_url="$base_url/tarballs/$dir/$tarball.tar.gz"

  printf "\n +++++ Snagging %s\n" "$dl_url"
  curl -L "$dl_url" | tar zxf -
done
