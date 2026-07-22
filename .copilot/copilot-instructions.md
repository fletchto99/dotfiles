# Personal preferences for Copilot CLI sessions

## Clone directory for ad-hoc work

When cloning a repository for temporary or session-scoped work (security
advisory patch series, investigation, throwaway experimentation, gem
audits, etc.), clone it under:

```
/Users/fletchto99/Programming/copilot-repos/
```

**Do not** clone into `/tmp/`, `/var/`, or any path outside `/Users/`.

### Rationale

My git configuration has a conditional include:

```
[includeIf "gitdir:/Users/"]
  path = .gitconfig_macos
```

`.gitconfig_macos` contains the SSH-signing configuration that points
commit signing at the 1Password `op-ssh-sign` helper:

```
[user]
  signingkey = key::ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE...

[gpg]
  format = ssh

[gpg "ssh"]
  program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
```

I also have `commit.gpgsign = true` set globally.

Repos cloned outside `/Users/` skip the conditional include. With no
`gpg.format=ssh` override, git falls back to its default
`gpg.format=openpgp` (GPG), but I don't have GPG installed on this
machine. The result: every commit fails with `error: cannot run gpg:
No such file or directory`, forcing a manual `git -c commit.gpgsign=false`
bypass on every commit and leaving the resulting commits unsigned.

Cloning under `/Users/` makes the `includeIf` fire and commits sign
automatically via SSH + 1Password Touch ID.

### If a repo already exists outside `/Users/`

Either re-clone it under `/Users/fletchto99/Programming/copilot-repos/`
(preferred), or add a one-shot local include to pull in the signing
config:

```bash
git -C <repo> config --local include.path ~/.gitconfig_macos
```

## Worktrees for multi-branch / multi-PR work

When working on more than one branch of the same repo at once (e.g. two
PRs in parallel), prefer `git worktree` over a second full clone:

- Keep one main clone at `/Users/fletchto99/Programming/copilot-repos/<repo>/`.
- Add a worktree per branch/PR as a sibling directory:

  ```bash
  # existing branch
  git worktree add ../<repo>--<branch> <branch>
  # new branch off main
  git worktree add -b <newbranch> ../<repo>--<newbranch> origin/main
  ```

- List with `git worktree list`; clean up finished ones with
  `git worktree remove ../<repo>--<branch>` (and `git worktree prune`).
- For a PR branch, fetch first then add: `git fetch origin` →
  `git worktree add ../<repo>--pr<N> <pr-branch>`. Don't use
  `gh pr checkout` for this — it retargets the *current* worktree instead
  of creating a new one.

### Rationale

- **Isolation without churn** — each branch stays checked out in its own
  directory, so I never have to `git checkout`/stash back and forth to
  switch PRs.
- **Prevents concurrent-agent hijack** — git forbids the same branch in
  two worktrees and each worktree has its own HEAD, so one Copilot agent
  can't switch the branch out from under another (a failure mode I hit
  with a shared clone).
- **Cheap** — shared object store and shared Go build/module cache
  (`GOCACHE`/`GOMODCACHE`), so no re-clone and builds stay warm.
- **Signing still works** — a worktree's gitdir lives under the main
  clone's `.git/worktrees/<name>`, which is under `/Users/`, so the
  `includeIf "gitdir:/Users/"` conditional include still fires and
  commits sign automatically via 1Password.

### When to use a separate full clone instead

Prefer a distinct clone (not a worktree) for isolated, destructive, or
long-running background-agent tasks that shouldn't share an object store
— e.g. aggressive `gc`, history rewrites, or an autonomous agent doing
heavy git surgery. Worktrees share one `.git`, so destructive operations
in one affect them all.

### Clean up review worktrees after posting

When I spin up a worktree **solely to review a PR** (not to make
changes), tear it down once the review is posted:

- After the review is submitted (COMMENT / REQUEST_CHANGES / APPROVE),
  `git worktree remove <path>` the worktree I created for that review
  (and delete the throwaway `pr-<N>` branch if I created one).
- Only remove a worktree **I created for the review**, and only if it's
  clean (no uncommitted changes). Never remove a worktree where edits
  were made, or one that already existed.
- Skip removal on a `dry-run` review, or if the review wasn't actually
  posted.
- Leave the main clone and any feature-work worktrees intact.

### Periodic cleanup of stale worktrees / clones

Treat a worktree or clone as a cleanup candidate once its PR has merged
or closed, or it hasn't been touched in over a week. Before removing,
confirm it's clean (no uncommitted changes ignoring stray artifacts) and
fully pushed (no commits missing from a remote); skip anything still in
active use. Merged/closed-PR working trees and stale base clones on
`main`/`master` are safe to reclaim — they can be re-created from the
remote when needed.

**Never auto-remove security-advisory / GHSA-fork clones** (e.g. a
secure-coding patch series pushed to a private `ghsa-*` fork). They have
no public PR by design and may sit untouched for weeks while an advisory
is in progress — "no PR" and "stale >1 week" do NOT imply abandoned. Only
remove one on explicit instruction.
