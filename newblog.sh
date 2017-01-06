#!/bin/bash

blogname=""

if [ $# -le 0  ]
then
	echo "this shell need input blog name"
	read name
	blogname=$name
else
	blogname=$1
fi

hexo new $blogname
chmod a+x ./insert.py
./insert.py $blogname
