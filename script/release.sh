#!/bin/bash
# npm run release -- -m 'Stable version'
# 1) Update version due to option -M, -m, -p
# 2) Commit change and add Tag to git
# 3) Publish to npm
# npm run release -- -m 'message'
# If error reading version try chmod +x ./package.json

function readJson {
  UNAMESTR=`uname`
  if [[ "$UNAMESTR" == 'Linux' ]]; then
    SED_EXTENDED='-r'
  elif [[ "$UNAMESTR" == 'Darwin' ]]; then
    SED_EXTENDED='-E'
  fi;

  VALUE=`grep -m 1 "\"${2}\"" ${1} | sed ${SED_EXTENDED} 's/^ *//;s/.*: *"//;s/",?//'`

  if [[ ! "$VALUE" ]]; then
    echo "Error: Cannot find \"${2}\" in ${1}" >&2;
    exit 1;
  else
    echo $VALUE ;
  fi;
}

# Parse command line options.
while getopts ":Mmpd" Option
do
  case $Option in
    M ) major=true;;
    m ) minor=true;;
    p ) patch=true;;
    d ) dry=true;;
    c ) commit=true;;
  esac
done

# Display usage
if [ -z $major ] && [ -z $minor ] && [ -z $patch ];
then
  echo "usage: $(basename $0) [Mmp] [message]"
  echo ""
  echo "  -d Dry run"
  echo "  -M for a major release"
  echo "  -m for a minor release"
  echo "  -p for a patch release"
  echo ""
  echo " Example: npm run release -- -m 'Stable version'"
  echo " means create a patch release with the message \"Some fix\""
  exit 1
fi

if [[ ! -z $major ]]
then
    version_incre="major"
elif [[ ! -z $minor ]]
then
    version_incre="minor"
elif [[ ! -z $patch ]]
then
    version_incre="patch"
fi

# If a command fails, exit the script
set -e

shift $(($OPTIND - 1))

branch=$(git branch | grep \* | cut -d ' ' -f2)
version=`readJson ./package.json version` || exit 1
version_name=`readJson ./package.json name` || exit 2
#username=$(git config user.name)
msg="$1"

#Check if branch is master
if [[ "$branch" != "master" ]]
then
echo "Not on master branch, terminated script"
exit 3
fi

if [[ ! -z $dry ]]
then
  echo "Tag message: $msg"
  #echo "Username: $username"
  echo "npm version $version_incre"
  echo "Current version: $version_name@$version"
else
  npm run build

  echo "git commit  with message: $msg"
  git add .

  #git commit -m "$msg"
  #git push origin master

  #echo "git push tag v$next_version with message: $msg"
  #git tag -a "v$next_version" -m "$msg"
  #git push --tags origin master

  echo "npm version $version_incre -f -m \"$msg\""
  npm version $version_incre -f -m "$msg"

  next_version=`readJson ./package.json version` || exit 1

  echo "npm publish $version_name@$next_version with message: $msg"
  npm publish

  git push --tags
  git push
cd ../
  echo "Publish completed $version_name@$next_version"
fi