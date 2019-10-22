# Panch - patchbranch

Situation: a parent branch has been rebased

Goal: rebase to parent branch

Problem: git does not detect "rewritten" commits

## Starting point: 3 branches
A branch `feature` has been created.
Another branch `sub-feature` stems from commits of `feature`.
The root branch `master` has also some additional commit.
```
                X---Y---Z sub-feature
               /
          E---F---G---H  feature
         /
    A---B---C---D  master
```

## Rebase of `feature`
Now, `feature` has been rebased to `master`.
_Conceptually_, it looks like this:
```
                X---Y---Z sub-feature
               /
          E---F---G---H  feature(previous)
         /
    A---B---C---D  master
                 \
                  E'--F'--G'--H' feature(new)
```

## Git information
_Actually_, git only has the following information:

```
                G---H (dangling refs)
               /
          E---F---X---Y---Z sub-feature
         /
    A---B---C---D  master
                 \
                  E'--F'--G'--H' feature
```
Furthermore, git can _not_ identify the relationship between `E,F` and `E',F'` at this point.

## Goal
Rebase `sub-feature` onto `feature`. Specifically, rebase `sub-feature` with `X,Y,Z` onto `F'` of `feature`.
```
    A---B---C---D  master
                 \
                  E'--F'--G'--H' feature
                       \
                        X---Y---Z sub-feature
```

## Problem
`git rebase sub-feature feature` is not enough. git will also include `E,F`, which are conceptually already in `feature` as `E',F'`[not verified].

## Solution

Use "author date" field of commit, which does not get rewritten during a rebase, to find a conceptually equal commit that is the common parent.

Traverse `sub-feature` upwards from leaf, for each commit: check if "author date" of commit is present in some commit of `feature` (traverse upwards from leaf). Authors must match. Additional heuristics may be performed, such as checking for commit message equalness.

Once identified, git can rebase more specifically with `--onto`. Given that we have found that `F` matches `F'`, and `F` is the parent of `X`, we can do `git rebase --onto F X F'`[not verified].

## Considerations
* Are timestamps + heuristics enough to prevent false positives?
* Can/should this be combined with a gerrit-like tagging system?
* Does this work across remotes?
