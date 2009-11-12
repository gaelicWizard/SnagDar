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
# Update 5/10/2007
# Snagdar now works with the Darwin source as it's stored on Apple's password
# protected servers.  However, now you need to specify a username and password.
# To do this you need to create the file "~/.snagdarpass", and in it put your
# ADC username and password as follows:
#
#     username=bob@bob.com
#     password=something
#
# Since this file contains your actual ADC username and password you should
# probably chmod it to 0600.
#
# Thanks to weltonch777's post at
# http://forums.macosxhints.com/archive/index.php/t-50441.html for figuring out
# the tricks for using curl through Apple's web auth stuff.
# 

# Authenticates with Apple's servers and stores the cookies in a file.  The
# file path where the cookies should be stored should be given as the first
# (and only) argument to this function.
function AuthAndStoreCookieInFile() {
  source ~/.snagdarpass
  password="$(security -q find-internet-password -a "$username" -s daw.apple.com -g 2>&1 | ruby -e 'print $1 if STDIN.gets =~ /^password: "(.*)"$/')"

  if [[ -z $username || -z $password ]]
  then
    echo ERROR: no username and password found
    exit 1
  fi

  touch $1
  chmod 0600 $1

  auth_action=$(curl -sL $base_url/tarballs/apsl/ | grep appleConnectForm \
                | awk 'BEGIN { RS = "\"" } ; {print $1}' | grep cgi)
  auth_url="https://daw.apple.com$auth_action?theAccountName=$username&theAccountPW=$password"
  curl -sL "$auth_url" -c $1 > /dev/null
}

base_url=http://www.opensource.apple.com
projects_url=$base_url/text/mac-os-x-1056.txt
cookie_file=/tmp/com.apple.daw.apsl.cookie.txt.$$

# If no arg was specified, just display the projects file
test -z $1 && exec curl -sL $projects_url

# Authenticate with Apple's servers
AuthAndStoreCookieInFile $cookie_file

# D/l and untar all projects that match the regex in $1
exec < <(curl -bL $cookie_file -s $projects_url | grep -v ^\# | egrep "$1")
while read line
do
  tarball=$(echo $line | awk '{print $1"-"$2}')
  dir=$(echo $line | awk '{print $3}' | tr '[:upper:]' '[:lower:]')
  dl_url=$base_url/tarballs/$1/$tarball.tar.gz

  printf "\n +++++ Snagging %s\n" $dl_url
  curl -bL $cookie_file $dl_url | tar zxf -
done

rm $cookie_file

