#!/bin/bash

BRANCH=$1
if [ -z "$BRANCH" ]
then
    BRANCH=`git rev-parse --abbrev-ref HEAD`
fi

git checkout --quiet $BRANCH

SINCE=$2

if [ -z "$SINCE" ]
then
    SINCE=`git describe --abbrev=0 --tags`
fi

UNTIL=$3

if [ -z "$UNTIL" ]
then
    UNTIL="HEAD"
fi



ALL_COMMITS=`git log $SINCE..$UNTIL --oneline | awk '{ print $1 }'`

NUM_ALL=$(echo $ALL_COMMITS | wc -w)

echo "Testing all $NUM_ALL commits from $SINCE until $UNTIL on branch '${BRANCH}', in reverse order."

cp -v .config config-all-compile-backup

echo -n "" > ok.txt
echo -n "" > failed.txt

COUNT=0
for x in $ALL_COMMITS
do
	COUNT=$((COUNT + 1))
	git checkout --quiet $x > /dev/null
	echo -n "[${COUNT}/${NUM_ALL}] "
	git log -n1 --oneline --quiet HEAD
	make olddefconfig > /tmp/make-msg.txt 2>&1
	make -j 64 bzImage >> /tmp/make-msg.txt 2>&1 && echo $x >> ok.txt && echo "$x ok" || (echo $x >> failed.txt; mv /tmp/make-msg.txt diag-$x.log; echo "$x FAILED")
done

git checkout $BRANCH
cp -v config-all-compile-backup .config
