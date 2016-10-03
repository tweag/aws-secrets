#!/bin/sh -e

cd `dirname $0`
cd ..
src=test/test-env
dst=`mktemp`

./send-env -s $src -b bduggan-test-bucket -k an-s3-key -a bduggan-test
./retrieve-env     -b bduggan-test-bucket -k an-s3-key -a bduggan-test > $dst

if diff -q $src $dst; then
    echo ok
else
    echo fail
    exit 1
fi

rm $dst

