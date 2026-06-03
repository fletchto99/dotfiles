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
