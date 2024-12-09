#!/usr/bin/env sh

hugo

pushd public
git add .
git commit -m "$(date)"
git push origin master
popd

pushd content
git add .
git commit -m "$(date)"
git push origin main
popd

git add . && git commit -m "$(date)"
git push origin draft
