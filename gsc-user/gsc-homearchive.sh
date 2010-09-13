#! /bin/sh
# Archive user home directory.
# Copyright (C) 2007 Washington University in St. Louis
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# set up script
pkg=gsc-homearchive
version=0.8

dest=/archive/archive/account_archive/home
login=
delete=
# loop through positional parameters
prev_arg=
optarg=
for arg
  do
  if test -n "$prev_arg"; then
      eval "$prev_arg=\$arg"
      prev_arg=
      continue
  fi

  case "$arg" in
      -*=*) optarg=`echo "$arg" | sed 's/[-_a-zA-Z0-9]*=//'` ;;
      *) optarg= ;;
  esac

  case "$arg" in
      -d | --delete | --delet | --dele | --del | --de | --d)
          delete=1
          ;;

      -h | --help | --hel | --he | --h)
          cat <<EOF
Usage: $pkg [OPTIONS]... [LOGIN]
If an argument to a long option is mandatory, it is also mandatory for
the corresponding short option; the same is true for optional arguments.

Options:
  -d,--delete    delete home directory rather than archive
  -h,--help      print this message and exit
  -v,--version   print version number and exit

This is meant to be called from gsc-userdel to archive a user home
directory.

EOF
          exit 0;;

      -v | --version | --versio | --versi | --vers | --ver | --ve | --v)
          echo "$pkg $version"
          exit 0;;

      -*)
          echo "$pkg: unrecognized option:$arg"
          echo "$pkg: Try '$pkg --help' for more information."
          exit 1;;

      *)
          if [ "$login" ]; then
              echo "$pkg: too many parameters:$arg"
              echo "$pkg: Try '$pkg --help' for more information."
              exit 1
          fi
          login="$arg"
          ;;
  esac
done

# make sure we use GNU tar
profile=/gsc/scripts/share/gsc-login/system.profile
if [ -f $profile ]; then
    . $profile
fi

# read command line parameters
if [ ! "$login" ]; then
    echo -n "$pkg: please enter login: "
    read login
fi

# set restrictive umask
if umask 077; then
    :
else
    echo "$pkg: failed to set restrictive umask"
    exit 1
fi

# set home directory
dir="/vol/home/$login"
if [ ! -d "$dir" ]; then
    # not a fatal error
    echo "$pkg: $dir does not exist"
    exit 0
fi
#if [ ! -h "$home" ]; then
#    echo "$pkg: $home is not a link"
#    exit 1
#fi

# get path to true directory
#dir=`ls -l $home | awk '{print $NF}'`
#if [ $? -ne 0 -o ! "$dir" ]; then
#    echo "$pkg: failed to get real home directory from $home"
#    exit 1
#fi

# remove the link in /gscuser
#if rm $home; then
#    :
#else
#    echo "$pkg: failed to remove home directory link:$home"
#    exit 1
#fi

# see if we should delete the home directory
if [ "$delete" ]; then
    echo -n "$pkg: delete $dir? (y/n) [n] "
    read ans
    if [ "$ans" = 'y' ]; then
        rm -rf "$dir"
        exit 0
    fi
    # else
    echo "$pkg: not deleting, will archive $dir"
fi

# remove cache files
for cache in $dir/.mozilla/*/*/Cache* $dir/.netscape/cache \
    $dir/.netscape6/*/*/Cache
  do
  if [ -d "$cache" ]; then
      rm -rf $cache
  fi
done

# change to directory one above home
if cd $dir/..; then
    :
else
    echo "$pkg: failed to change directories to $dir/.."
    exit 1
fi

# create tar
tar=$dest/$login.tar
if tar cf $tar $login; then
    :
else
    echo "$pkg: failed to create tar file: $tar"
    exit 1
fi

# compress the tar file
if gzip $tar; then
    :
else
    echo "$pkg: failed to compress tar file: $tar"
    exit 1
fi

# remove the home directory
rm -rf $dir

exit 0