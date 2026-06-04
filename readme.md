# Fletchto99's Dotfiles

Personal macOS / Linux shell + git + tool configuration. Targets macOS (Apple Silicon) as the primary daily driver, with light support for Linux (Codespaces, occasional VMs).

## Install

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/fletchto99/dotfiles/master/script/bootstrap)"
```

The bootstrap is **idempotent** — safe to re-run on an already-configured machine. Existing real files (not symlinks) get backed up to `~/dotfiles_old/` on first link; subsequent runs detect the existing symlinks and skip the backup step to avoid clobbering the original backup. Most steps prompt interactively (Homebrew install, Brewfile sync, iTerm2/Alfred config, dotfile linking) so partial installs are easy.

## What's in here

| File | Purpose |
|---|---|
| `.zshrc`, `.exports`, `.aliases`, `.functions` | Shell config split by responsibility |
| `.gitconfig` + `.gitconfig_{macos,linux,windows}` + `.gitconfig_work` | Base git config + per-OS overrides (1Password SSH signing, credential helper, URL rewrites) wired in via a `~/.gitconfig.local` symlink, plus a work-account override loaded by remote URL |
| `.gitignore_global`, `.inputrc` | Global git ignores + readline (REPL) configuration |
| `.ssh/config*` | Hostname aliases and routing (private keys are NOT versioned — see `.gitignore`) |
| `.copilot/copilot-instructions.md` | Per-user GitHub Copilot CLI preferences |
| `.iterm2/`, `.alfred/` | iTerm2 + Alfred app preference files (loaded via app-specific "load from folder" settings) |
| `Brewfile` | Homebrew formulae + casks + taps, auto-generated via `brew bundle dump` |
| `script/bootstrap` | Idempotent installer |

## Key choices

### Shell: zsh + oh-my-zsh (not fish, not bare zsh, not zinit)

zsh is the macOS default and bash-compatible enough that pasting bash snippets from docs / Stack Overflow / internal runbooks Just Works. oh-my-zsh's compinit overhead (~150ms warm) is acceptable for the convenience of its plugin/completion ecosystem.

Tradeoffs considered:
- **fish** — Better defaults out of the box but requires translating every bash idiom. Bad fit for systems-y work.
- **starship / p10k** — Power prompts. Skipped p10k specifically due to maintenance concerns; starship is fine but I don't need a richer prompt right now.

### Performance tuning

The `.zshrc` is aggressively tuned for fast warm startup (~150ms):

- **Lazy-loaded `nvm` and `rbenv`** — neither runs `init` until you actually call `node` / `nvm` / `ruby` / `rbenv` / `gem` / `bundle` / etc. Function shims do the lazy init on first call and self-replace.
- **NODE_GLOBALS cached** — the slow scan of `~/.nvm/versions/node/**/bin` runs once a week into `~/.nvm-node-globals-cache` rather than on every shell.
- **`$HOMEBREW_PREFIX` cached** — `brew --prefix` is ~50ms; cached to a variable instead of re-running.
- **Dropped the OMZ `git` plugin** — its 30+ aliases (`g`, `gst`, `gco`, etc.) aren't in my muscle memory; the plugin's compdef calls were a measurable share of startup. `git` itself is unaffected.
- **Dropped `bash_completion` sourcing** — zsh has its own completion system; the bash framework was dead weight when sourced in zsh.
- **Disabled `compaudit`, `ENABLE_CORRECTION`, `DISABLE_MAGIC_FUNCTIONS`** — each saves a few ms and removes a class of paste-time surprises.

### Plugins: zsh-autosuggestions + zsh-syntax-highlighting

Both are cloned into `${ZSH_CUSTOM}/plugins/` by the bootstrap (idempotent — only clones if missing). Order matters: zsh-syntax-highlighting must load LAST in `plugins=(...)` because it hooks the command-line preexec.

### Editor: VS Code Insiders, with git integration

`code-insiders` is `core.editor` *and* the git diff/merge tool across all platforms. Works on macOS / Linux / Windows / WSL — the only realistic gap is plain GitHub Codespaces (where only `code` is in PATH; one-line override there).

### Git commit signing: SSH via 1Password

Commits sign via `op-ssh-sign` (1Password's SSH agent), not GPG. The same SSH key is used on every OS — only the path to `op-ssh-sign` and the credential helper differ. Per-OS settings live in three sibling files:

| File | 1Password path | Credential helper |
|---|---|---|
| `.gitconfig_macos` | `/Applications/1Password.app/Contents/MacOS/op-ssh-sign` | `osxkeychain` |
| `.gitconfig_linux` | `/opt/1Password/op-ssh-sign` | `cache --timeout=3600` |
| `.gitconfig_windows` | `C:/Users/<user>/AppData/Local/1Password/app/8/op-ssh-sign.exe` | `manager` (Git Credential Manager) |

Each file is self-contained — including the GitHub `https://` → `git@` URL rewrites — so swapping the active one is a single symlink change.

**How it gets loaded.** The committed `.gitconfig` has one unconditional line: `[include] path = ~/.gitconfig.local`. Git silently no-ops on a missing include, so the same `.gitconfig` works everywhere — including for repos cloned outside `~/`, which the old `[includeIf "gitdir:/Users/"]` heuristic missed and broke commit signing in `/tmp/` and similar.

- **macOS**: `script/bootstrap` symlinks `~/.gitconfig.local` → `~/.dotfiles/.gitconfig_macos` automatically.
- **Linux**: bootstrap symlinks `→ .gitconfig_linux` **only if** `/opt/1Password/op-ssh-sign` exists. On Codespaces / Linux boxes without 1Password, no symlink is created and commits stay unsigned (the desired behavior — signing would otherwise fail on every push).
- **Windows**: bootstrap doesn't run on Windows (bash script, Homebrew/apt assumptions). Wire it up manually in Git Bash / WSL:
  ```bash
  ln -s ~/.dotfiles/.gitconfig_windows ~/.gitconfig.local
  ```
  Or, from PowerShell:
  ```powershell
  New-Item -ItemType SymbolicLink -Path "$HOME\.gitconfig.local" -Target "$HOME\.dotfiles\.gitconfig_windows"
  ```
  Edit `.gitconfig_windows` if your Windows username isn't `fletchto99` — `%LOCALAPPDATA%` doesn't expand inside git config, so the path is hardcoded.

### Git config additions worth highlighting

- `rerere.enabled = true` — auto-replays previously-resolved conflicts during rebases
- `diff.algorithm = histogram` + `colorMoved = zebra` — readable diffs with distinct coloring for moved lines
- `merge.conflictStyle = zdiff3` — shows common ancestor between conflict markers
- `branch.sort = -committerdate` — most-recently-used branches first in `git branch`
- `commit.verbose = true` — diff shown in commit-message editor
- `push.followTags = true` + `tag.gpgsign = true` — annotated tags push automatically and sign with the same SSH key
- `core.fsmonitor = true` — FSEvents-backed `git status` (5–10× faster on large repos)
- URL rewriting: `https://github.com/` → `git@github.com:` (always use SSH for github.com, plus defensive redirect for the deprecated `git://` protocol)

### Node / Ruby / Python version management

- **Node**: `nvm` (dropped `nodenv` to avoid two tools doing the same job)
- **Ruby**: `rbenv`
- **Python**: `uv` for tool installs (`uv tool install`), system Homebrew Python for the interpreter

### Brewfile philosophy

Generated via `brew bundle dump --formula --cask --tap --no-vscode --describe`. Includes transitive deps so a fresh-machine `brew bundle` reproduces the exact install state.

VS Code extensions are intentionally **NOT** tracked here — Settings Sync (signed in via GitHub) is the single source of truth for extensions, settings, keybindings, and snippets. Two managers fighting over one resource was worse than letting Settings Sync own it.

### Copilot CLI instructions

Only the user-managed `copilot-instructions.md` file is symlinked — not the whole `~/.copilot/` directory. The Copilot CLI writes machine-local state (session state, plugins, MCP configs) under that directory that should stay machine-local.

## Conventions

- Real files get backed up to `~/dotfiles_old/<relative-path>` on first link, never re-backed-up on subsequent runs.
- Special-case directories (`.ssh/`, `.copilot/`) are linked **per-file**, not as whole-directory symlinks — preserves machine-local content (SSH private keys, Copilot runtime state) that shouldn't be versioned.
- `~/.dotfiles/script/bootstrap` is the canonical install path. Editing dotfiles directly in `~/.dotfiles/` then `git push` is the canonical update path (changes are live immediately via the symlinks).
