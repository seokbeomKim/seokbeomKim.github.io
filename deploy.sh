#!/usr/bin/env sh

cd /home/sukbeom/workspace/gitblog
hugo
git add . && git commit -m "$(date)"
git push origin draft

cd /home/sukbeom/workspace/gitblog/public
git add .
git commit -m "$(date)"
git push origin master


