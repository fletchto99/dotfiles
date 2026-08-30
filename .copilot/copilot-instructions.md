# Personal preferences for Copilot CLI sessions

> **This file is synced to a public dotfiles repo.** Keep it free of
> internal/employer-specific details (repo names, hostnames, team
> workflows) — put those in the Copilot memory store instead, and keep
> examples here generic.

## Clone directory for ad-hoc work

When cloning a repository for temporary or session-scoped work (security
advisory patch series, investigation, throwaway experimentation, gem
audits, etc.), clone it under:

```
/Users/fletchto99/Programming/copilot-repos/base-clones/
```

**Do not** clone anywhere else (e.g. `/tmp/`) — one predictable location
keeps clones easy to find, audit, and clean up.

### Rationale

Commit signing (SSH via 1Password's `op-ssh-sign`, `commit.gpgsign=true`)
is configured through an unconditional `[include] path = ~/.gitconfig.local`
(symlinked to `.gitconfig_macos` in my dotfiles), so signing works from
any path on this machine — the location rule is organizational, not a
signing requirement.

## Worktrees for all branch work

**Base clones stay on the default branch (main/master) at all times.**
Never create feature branches or commit work directly in a base clone —
even for a single-branch task. All branch/feature work happens in a
worktree:

- Keep one main clone at
  `/Users/fletchto99/Programming/copilot-repos/base-clones/<repo>/`.
- Add a worktree per branch/PR under
  `/Users/fletchto99/Programming/copilot-repos/worktrees/`:

  ```bash
  # existing branch (run from the base clone)
  git worktree add ../../worktrees/<repo>--<branch> <branch>
  # new branch off the default branch (check: main vs master)
  git worktree add -b <newbranch> ../../worktrees/<repo>--<newbranch> origin/main
  ```

- List with `git worktree list`; clean up finished ones with
  `git worktree remove ../../worktrees/<repo>--<branch>` (and `git worktree prune`).
  After removing a worktree, also `git branch -D` its now-orphaned local
  branch (unless it still has unmerged/unpushed work).
- **Clean up docker containers with the worktree**: if the worktree ran
  its own `docker compose` services (check
  `docker ps -a --format '{{.Names}}'` for the compose project name,
  e.g. `<repo>--<branch>-db-1`), remove them when removing the worktree
  — but never remove a running container another worktree is using
  (e.g. the one shared DB serving port 3306).
- **Prune gone branches** during base-clone cleanup: delete local branches
  whose upstream was deleted on the remote (merged PRs), as long as no
  worktree still has them checked out:

  ```bash
  git fetch -p && git branch -vv | awk '/: gone]/{print $1}' | xargs git branch -D
  ```
- **Fetch before branching**: run `git fetch origin` in the base clone
  before creating a worktree off `origin/main` — base clones can sit
  days behind.
- For a PR branch, fetch first then add: `git fetch origin` →
  `git worktree add ../../worktrees/<repo>--pr<N> <pr-branch>`. Don't use
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

Treat a worktree as a cleanup candidate once its PR has merged or
closed, or it hasn't been touched in over a week. Before removing,
confirm it's clean (no uncommitted changes ignoring stray artifacts) and
fully pushed (no commits missing from a remote); skip anything still in
active use.

**Base clones**: keep them by default (they anchor worktrees and stay
warm), but one cloned solely for a one-off task (e.g. a PR review) may
be removed once that task is done. **Never delete a base clone that has
modified/uncommitted files**, and never remove one that still has linked
worktrees.

**Never auto-remove security-advisory / GHSA-fork clones** (e.g. a
secure-coding patch series pushed to a private `ghsa-*` fork). They have
no public PR by design and may sit untouched for weeks while an advisory
is in progress — "no PR" and "stale >1 week" do NOT imply abandoned. Only
remove one on explicit instruction.

## Addressing PR review feedback

When fixing something a reviewer (human or Copilot) flagged in a PR
review comment, always reply **in that comment's thread** after pushing,
citing the fix: e.g. "Addressed in `<short-sha>` — <one-line summary of
the fix>". Use `gh api repos/<owner>/<repo>/pulls/<pr>/comments/<id>/replies`
for inline comments. Don't leave review threads dangling, and don't
reply before the fix is actually pushed.

## Machine tooling notes

- **Dotfiles**: shell/git/ssh config files (`~/.zshrc`, `~/.exports`,
  `~/.gitconfig*`, `~/.ssh/config*`, this instructions file, etc.) are
  symlinks into the `~/.dotfiles` git repo. Edit through the symlinks
  freely, but remind me to review/commit the dotfiles repo after config
  changes — don't commit it autonomously.
- **VS Code**: "open in VS Code" means **VS Code Insiders** — use the
  `code-insiders` CLI (the only one on PATH; there is no stable `code`
  CLI, and the interactive-only `code` shell alias isn't visible to
  agents).
- **Ruby**: managed by rbenv (Homebrew, `/opt/homebrew/bin/rbenv`).
  `~/.rbenv/shims` is on PATH via `~/.exports`, so `ruby`/`bundle`/`rails`
  resolve the repo's `.ruby-version` automatically — no `rbenv init`
  needed. If shims are somehow missing from PATH (CLI launched from a
  stale shell), fall back to `eval "$(rbenv init - bash)"`. Installed
  versions live in `~/.rbenv/versions`; install missing ones with
  `rbenv install`.
- **MySQL for Rails test suites**: tests connect to `127.0.0.1:3306`;
  any one worktree's `docker compose` DB container satisfies every
  worktree, so check `docker ps` for an existing container before
  starting another (the port can only be bound once).
- **gh extensions**: some repo scripts silently no-op (print gh help,
  exit 0) when a required gh extension isn't installed — if a script
  wrapping `gh <subcommand>` does nothing, check `gh extension list`
  before debugging further.
