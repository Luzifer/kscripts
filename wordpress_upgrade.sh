#!/bin/bash

if [ $# -lt 1 ]
then
	echo "Usage: $0 <version>"
	exit 2
fi

VERSION=$1

echo "Invoking SVN..."
svn sw http://svn.automattic.com/wordpress/tags/$VERSION/ .

if [ $? -eq 0 ]
then
	echo "Update done."
	exit 0
else
	echo "Update failed."
	exit 1
fi
