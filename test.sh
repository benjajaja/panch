#!/bin/bash
set -e

hours_ago=20
function commit {
  echo "line $1" >> file
  git add file
  hours_ago=$((hours_ago-1))
  git commit -m "$1" --date=format:relative:${hours_ago}.hours.ago
  echo $hours_ago
}

exec_amend_prime="git commit --quiet --amend -m \"\$(git log --format=%B -n 1)'\""

function resolve_rebase_conflict_both {
  sed -i '' -e '/^<<<<<<</d' file
  sed -i '' -e '/^=======/d' file
  sed -i '' -e '/^>>>>>>>/d' file
  git add file
  GIT_EDITOR=cat git rebase --continue
  echo "Resolved conflict by keeping both patches"
}


rm -rf test_repo
mkdir test_repo

cd test_repo
git init

# create initial topology

echo "line A" > file
git add file
git commit -m "A" --date=format:relative:${hours_ago}.hours.ago
commit B
commit C
commit D

git checkout --detach HEAD~2
git checkout -b feature
commit E
commit F
commit G
commit H

git checkout --detach HEAD~2
git checkout -b sub-feature
commit X
commit Y
commit Z

# rebase feature to master

git checkout feature --quiet
git rebase master --exec "$exec_amend_prime" --quiet || echo "resolving conflicts..."
resolve_rebase_conflict_both

# find fork-point

git checkout sub-feature

# TODO find fork-point here, instead of using known ref
fork_id=$(git log --all --grep="^F$" --format=%H)
echo "fork at: $fork_id"

# rebase with fork-point
git rebase --exec "$exec_amend_prime" --onto feature $fork_id sub-feature || echo "resolving conflicts..."
resolve_rebase_conflict_both

# verify

echo "* Z' (10 hours ago)  (HEAD -> sub-feature)
* Y' (11 hours ago) 
* X' (12 hours ago) 
* H' (13 hours ago)  (feature)
* G' (14 hours ago) 
* F' (15 hours ago) 
* E' (16 hours ago) 
* D (17 hours ago)  (master)
* C (18 hours ago) 
* B (19 hours ago) 
* A (20 hours ago) " > expected_output

git log --all --graph --topo-order --abbrev-commit --decorate --format=format:'%s (%ar) %d' > actual_output
echo "" >> actual_output # add newline to match echo above

echo "Expected output:"
cat expected_output
echo "Actual output:"
cat actual_output

diff expected_output actual_output && echo "TEST PASSED"

