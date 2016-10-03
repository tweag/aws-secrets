#!/bin/sh -e

cd `dirname $0`
../send-env test-env
../retrieve-env bduggan-test > /tmp/out
if diff -q test-env /tmp/out; then
    echo ok
else
    echo fail
    exit 1
fi

