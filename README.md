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

## Goal
Rebase `feature` to `master` (straightforward). Rebase `sub-feature` onto `feature`. Specifically, rebase `sub-feature` with `X,Y,Z` onto `HEAD` of `feature`.
```
    A---B---C---D  master
                 \
                  E'--F'--G'--H' feature
                               \
                                X---Y---Z sub-feature
```

## Details of "Rebase `feature` to `master`"
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

But _actually_, git only has the following information:

```
                G---H (dangling refs)
               /
          E---F---X---Y---Z sub-feature
         /
    A---B---C---D  master
                 \
                  E'--F'--G'--H' feature
```
git can _not_ identify the relationship between `E,F` and `E',F'` at this point.

## Problem
`git rebase sub-feature feature` is not enough. git will also include `E,F`, which are conceptually already in `feature` as `E',F'`[not verified]. These are also guaranteed to produce merge conflicts, at each rebase step!
```
    A---B---C---D  master
                 \
                  E'--F'--G'--H' feature
                               \
                                E---F---X---Y---Z sub-feature
```


## Solution by heuristics

> Use "author date" field of commit, which does not get rewritten during a rebase, to find a conceptually equal commit that is the common parent.

* For each commit in `sub-feature` from `HEAD`:
  * For each commit in `feature` from `HEAD`:
    * If they are conceptually equal, pick this commit of `sub-feature` as `fork-point`.  
    We can compare the commits author-dates and assume they will not get tampered with.  
    Additional heuristics may be performed, such as checking for commit message equalness.

Once `fork-point` is identified, git can rebase more specifically with `--onto`, providing the target branch `sub-feature` and the commit id: `git rebase --onto feature sha1(fork-point) sub-feature`.

## Solution by additional tagging during rebase

Gerrit writes a unique id into commit messages to track rewritten commits and treat them as patches. A similar but not so invading technique could be used.

During "Rebase `feature` to `master`", `F` could be rewritten to include the id of the new commit `F'`, for example `fork-point:sub-feature:<sha1 of new F'>`. It could later be parsed before rebasing `sub-feature` onto `feature` as fork-point identification without heuristics.

This would only affect "stale" commits, so no garbage will be added to any commits that will get merged into master.