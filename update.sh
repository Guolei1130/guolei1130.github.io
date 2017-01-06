#!/bin/bash

cms="update"

rm ./index.html

hexo g

git add ./

if [ $# -ge 1 ]
then
	cms=$1
fi

git commit -m $cms

git push
