export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="robbyrussell"
ENABLE_CORRECTION="true"
plugins=(git)

source $ZSH/oh-my-zsh.sh

# ssh
export SSH_KEY_PATH="~/.ssh/rsa_id"

alias afk="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend"

eval $(thefuck --alias)
export PATH="/usr/local/sbin:$PATH"


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

alias delb='git checkout master && git pull && git branch --merged master | grep -v " master" | xargs -n 1 git branch -d'
