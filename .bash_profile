eval "$(thefuck --alias)"
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

alias brewski='brew update && brew upgrade && brew cleanup; brew doctor'
alias afk="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend"
