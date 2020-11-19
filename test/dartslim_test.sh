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

echo "Building local image: subfuzion/dart:slim..."
docker build -t subfuzion/dart:slim ..
check "unable to build subfuzion/dart:slim"
docker image ls subfuzion/dart:slim

echo "Building local test image: $image..."
docker build -t "$image" .
check "unable to build test image"
docker image ls $image

echo "Starting server in test container..."
docker run -d -p 8080:8080 --name "$ctr" "$image"
check "unable to start a test container from test image: $image"
echo "Started test server"

echo "Starting tests..."
dart test -r expanded
