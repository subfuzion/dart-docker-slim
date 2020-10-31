#!/usr/bin/env bash

timestamp="$(date +%s)"
image="dart-test-image-${timestamp}"
ctr="${image}-ctr"

function cleanup {
  docker rm -f $ctr >/dev/null 2>&1
  docker image rm -f $image >/dev/null 2>&1
}
trap cleanup EXIT

function error {
  echo "FAIL: $1"
  exit 1
}

function check {
  (($? != 0)) && error "$1"
}

docker build -t "$image" .
check "unable to build image"

docker run -d -p 8080:8080 --name "$ctr" "$image"
check "unable to start a test container from image: $image"

dart test

