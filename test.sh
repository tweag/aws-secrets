#!/bin/bash

cd `dirname $0`
src=`mktemp`
cat >> $src <<DONE
export SECRET_WORD=xyzzy
export MAGIC_WORDS=squeamish_ossifrage
export RAND=$RANDOM
DONE
dst=`mktemp`
n=1

ok() {
    if [ "$?" == "0" ]; then
        echo "ok $n - $@"
    else
        echo "not ok $n - $@"
    fi
    n=`expr $n + 1`
}

echo '1..3'

./send-env -s $src -b bduggan-test-bucket -k an-s3-key -a bduggan-test
ok 'sent'
./retrieve-env -b bduggan-test-bucket -k an-s3-key -a bduggan-test > $dst
ok 'retrieved'

diff -q $src $dst
ok 'got the same thing back'

rm $src
rm $dst

