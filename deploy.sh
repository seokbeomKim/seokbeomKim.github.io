#!/usr/bin/env sh

pushd public
git add . && git commit -m "$(date)"
git push origin master
popd

git add . && git commit -m "$(date)"
git push origin draft
