#!/bin/bash

rm -rf test_repo
mkdir test_repo

cd test_repo
git init
echo "line 1" > file
git add file
git commit -m "initial commit" --date=format:relative:8.hours.ago

git checkout -b branch1
echo "line 2" >> file
git add file
git commit -m "branch1" --date=format:relative:7.hours.ago

git checkout -b branch2
echo "line 3" >> file
git add file
git commit -m "branch2" --date=format:relative:6.hours.ago

git log --all --graph | cat

git checkout branch1
echo -e "line 0\n$(cat file)" > file
git add file
git commit --amend -m "branch1 rewritten"

git checkout branch2

git log --all --graph | cat

../target/debug/panch

