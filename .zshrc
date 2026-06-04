source ~/.exports
source ~/.aliases
source ~/.functions

# ─── OH MY ZSH ──────────────────────────────────────────────────────────────
ZSH_THEME="robbyrussell"
# Skip the "did you mean ...?" prompt — slows down typos more than it saves keystrokes.
ENABLE_CORRECTION="false"
# Skip compinit's permission audit (compaudit). Faster shell startup; safe given Homebrew
# prefixes are user-owned on Apple Silicon and we're not on a shared host.
ZSH_DISABLE_COMPFIX=true
# Skip the periodic `git fetch` that OMZ runs against its own repo at shell startup.
# Run `omz update` manually when you want to update.
DISABLE_AUTO_UPDATE="true"
# Skip OMZ's URL-quoting / bracketed-paste magic. Saves a few ms and removes a class of
# paste-time surprises (auto-escaping URLs, stripping characters from pasted commands).
DISABLE_MAGIC_FUNCTIONS="true"
# Only zsh-autosuggestions + zsh-syntax-highlighting. Dropped the OMZ `git`
# plugin since none of its 30+ git aliases (g/gst/gco/gp/etc.) are in use.
# `git` itself is unaffected — you still use it normally.
# IMPORTANT: zsh-syntax-highlighting must be the LAST plugin (it hooks the
# command-line preexec and gets confused if other plugins load after it).
plugins=(zsh-autosuggestions zsh-syntax-highlighting)

# Docker CLI completions must enter fpath BEFORE oh-my-zsh runs compinit, otherwise
# completions for Docker subcommands don't register on first shell.
if [ -d "$HOME/.docker/completions" ]; then
  fpath=("$HOME/.docker/completions" $fpath)
fi

# ─── COMPINIT FAST PATH ─────────────────────────────────────────────────────
# OMZ runs `compinit -u -d "$ZSH_COMPDUMP"` (skips compaudit thanks to
# ZSH_DISABLE_COMPFIX, but still checks every fpath entry for changes on
# every shell — ~100-300ms). Replace that with the standard once-a-day
# pattern: do the full check at most once every 24h, otherwise load the
# cached dump with `-C` (no scan). New completions appear within 24h, or
# immediately if you `rm ~/.zcompdump` after a brew/npm install that ships
# completions.
ZSH_COMPDUMP="$HOME/.zcompdump"
autoload -Uz compinit
# Full rebuild if the dump is missing OR older than 24 hours. Otherwise load
# the cached dump with `-C` (no fpath scan). (#qN.mh+24) is the glob qualifier
# for "files modified more than 24h ago"; N makes a non-match expand to empty.
if [[ ! -s $ZSH_COMPDUMP ]] || [[ -n $ZSH_COMPDUMP(#qNmh+24) ]]; then
  compinit -u -d "$ZSH_COMPDUMP"
else
  compinit -C -d "$ZSH_COMPDUMP"
fi
# Stub compinit so OMZ's own call is a no-op (it would otherwise re-do the
# scan we just optimized away).
compinit() { :; }

source $ZSH/oh-my-zsh.sh

# Restore the real compinit in case a later plugin or interactive session
# legitimately needs it.
unfunction compinit
autoload -Uz compinit

# ─── ZSH HISTORY & OPTIONS ──────────────────────────────────────────────────
# Larger history + dedup so Up-arrow / Ctrl-R searches aren't cluttered with duplicates.
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS HIST_VERIFY SHARE_HISTORY
# Keep the `history` command itself and one-off function definitions out of history.
setopt HIST_NO_STORE HIST_NO_FUNCTIONS

# Type a directory name without `cd` to enter it.
setopt AUTO_CD
# Allow `# comments` to be pasted into the interactive prompt without zsh errors.
setopt INTERACTIVE_COMMENTS
# Enable zsh power-globbing: ``**/*.rb``, ``^pattern`` negation, ``~exclude``, qualifier flags.
# Standard zsh feature, often assumed by shell snippets in docs.
setopt EXTENDED_GLOB
# After tab-completing, move cursor to the end of the completed word (instead of after the
# matched prefix). Subtle, but you'll notice the absence after using it for a week.
setopt ALWAYS_TO_END
# Disable the terminal bell on completion errors / line-edit boundaries.
unsetopt BEEP

# Case-insensitive tab completion + partial-word matching. `Down<TAB>` → `Downloads`,
# `git co<TAB>` matches both ``checkout`` and ``commit``.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# ─── CODESPACES / LINUX SKIPS ───────────────────────────────────────────────
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
  # File-cache `brew --prefix` across shells. `brew` is a Ruby script — even a
  # single fork is 50-150ms on a warm cache and 1-3s when the page cache is
  # cold (post-sleep, post-reboot). New iTerm/Terminal tabs are fresh login
  # shells, so a process-local cache wouldn't help. The prefix is effectively
  # constant per machine (/opt/homebrew on Apple Silicon, /usr/local on
  # Intel), so caching to disk is safe; delete the file if you ever migrate.
  HBP_CACHE="$HOME/.cache/homebrew-prefix"
  if [[ ! -s "$HBP_CACHE" ]]; then
    mkdir -p "${HBP_CACHE:h}"
    brew --prefix 2>/dev/null > "$HBP_CACHE"
  fi
  typeset -gx HOMEBREW_PREFIX="$(<$HBP_CACHE)"

  # ── nvm: lazy-load on first node-ecosystem command ────────────────────────
  # Original snippet from https://gist.github.com/fl0w/07ce79bd44788f647deab307c94d6922
  # The find scan of ~/.nvm/versions/node/**/bin is the slow part — cache it.
  # Force a rebuild after installing a new global with: rm ~/.nvm-node-globals-cache
  NVM_CACHE="$HOME/.nvm-node-globals-cache"
  if [[ ! -f "$NVM_CACHE" ]] || [[ $(find "$NVM_CACHE" -mtime +7 2>/dev/null) ]]; then
    find ~/.nvm/versions/node -maxdepth 3 -type l -wholename '*/bin/*' 2>/dev/null \
      | xargs -n1 basename | sort -u > "$NVM_CACHE"
  fi
  NODE_GLOBALS=("${(@f)$(<$NVM_CACHE)}")
  NODE_GLOBALS+=("node")
  NODE_GLOBALS+=("nvm")

  load_nvm() {
    export NVM_DIR=~/.nvm
    [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && . "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
  }

  for cmd in "${NODE_GLOBALS[@]}"; do
    eval "${cmd}(){ unset -f ${NODE_GLOBALS}; load_nvm; ${cmd} \$@ }"
  done

  # ── rbenv: lazy-load on first ruby-ecosystem command ──────────────────────
  # Same pattern as nvm — `rbenv init` is ~50-100ms and most shells don't touch ruby.
  export PATH="$HOME/.rbenv/bin:$PATH"
  for cmd in rbenv ruby gem bundle bundler rake irb erb; do
    eval "${cmd}(){ unset -f rbenv ruby gem bundle bundler rake irb erb; eval \"\$(command rbenv init - zsh)\"; ${cmd} \$@ }"
  done
fi
