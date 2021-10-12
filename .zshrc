source ~/.exports
source ~/.aliases
source ~/.functions

# Homebrew
HOMEBREW_NO_ENV_FILTERING="true"

# OH MY ZSH
ZSH_THEME="robbyrussell"
ENABLE_CORRECTION="true"
ZSH_DISABLE_COMPFIX=true
plugins=(git zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh

# Add tab completion for many Bash commands
if which brew &> /dev/null && [ -f "$(brew --prefix)/share/bash-completion/bash_completion" ]; then
  source "$(brew --prefix)/share/bash-completion/bash_completion";
elif [ -f /etc/bash_completion ]; then
  source /etc/bash_completion;
fi;

# Fix for crtl+M when pressing enter
stty sane

# Codespaces we dont want this
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
  # Speed up loading nvm thanks to https://gist.github.com/fl0w/07ce79bd44788f647deab307c94d6922
  # Add every binary that requires nvm, npm or node to run to an array of node globals
  NODE_GLOBALS=(`find ~/.nvm/versions/node -maxdepth 3 -type l -wholename '*/bin/*' | xargs -n1 basename | sort | uniq`)
  NODE_GLOBALS+=("node")
  NODE_GLOBALS+=("nvm")

  # Lazy-loading nvm + npm on node globals call
  load_nvm () {
    export NVM_DIR=~/.nvm
    [ -s "$(brew --prefix nvm)/nvm.sh" ] && . "$(brew --prefix nvm)/nvm.sh"
  }

  # Making node global trigger the lazy loading
  for cmd in "${NODE_GLOBALS[@]}"; do
    eval "${cmd}(){ unset -f ${NODE_GLOBALS}; load_nvm; ${cmd} \$@ }"
  done

  # Init the Ruby env
  eval "$(rbenv init -)"

  # Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
  h=()
  if [[ -r ~/.ssh/config ]]; then
    h=($h ${${${(@M)${(f)"$(cat ~/.ssh/config)"}:#Host *}#Host }:#*[*?]*})
  fi
  if [[ -r ~/.ssh/known_hosts ]]; then
    h=($h ${${${(f)"$(cat ~/.ssh/known_hosts{,2} || true)"}%%\ *}%%,*}) 2>/dev/null
  fi
  if [[ $#h -gt 0 ]]; then
    zstyle ':completion:*:ssh:*' hosts $h
    zstyle ':completion:*:slogin:*' hosts $h
  fi

  eval "$(nodenv init -)"
fi
