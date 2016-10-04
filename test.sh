#!/bin/bash -e

cd `dirname $0`
src=`mktemp`
cat >> $src <<DONE
export SECRET_WORD=xyzzy
export MAGIC_WORDS=squeamish_ossifrage
export RAND=$RANDOM
DONE
dst=`mktemp`

echo '# sending'
./send-env -s $src -b bduggan-test-bucket -k an-s3-key -a bduggan-test
echo '# retrieving'
./retrieve-env     -b bduggan-test-bucket -k an-s3-key -a bduggan-test > $dst

if diff -q $src $dst; then
    echo "pass"
    exit 0
else
    echo "fail"
    exit 1
fi

rm $src
rm $dst

