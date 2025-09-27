#!/bin/sh
for plat in windows linux mac; do
  butler push "build/$plat" "vhoyer/yasapo:$plat"
done
