# Clone dotfiles
git clone git@github.com:fletchto99/dotfiles.git ~/.dotfiles

# Install homebrew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Ensure homebrew is up to date
brew update

# Tap brew repos
brew tap caskroom/cask

# Instal homebrew libs & tools
brew install node nmap python3 sqlmap thefuck hub

# Install some default apps
brew cask install keybase keypassx speedcrunch sublime-text tunnelblick iterm2 meld

# Configure iTerm 2 preferences
ln -s  ~/.dotfiles/.iterm2 ~/.iterm2/
defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "~/.iterm2"
defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true

# Install some default software
curl -L http://install.ohmyz.sh | sh

# Link dotfiles
ln -s ~/.dotfiles/.bash_profile ~/.bash_profile
ln -s ~/.dotfiles/.bashrc ~/.bashrc
ln -s ~/.dotfiles/.gitconfig ~/.gitconfig
ln -s ~/.dotfiles/.gitignore_global ~/.gitignore_global
ln -s ~/.dotfiles/.zshrc ~/.zshrc

#Setup sublime
ln -s  ~/.dotfiles/.sublime ~/.sublime/
rm -rf "~/LibraryApplication Support/Sublime Text 3/Packages/User"
ln -s ~/.sublime "~/Library/Application Support/Sublime Text 3/Packages/User"
mkdir ~/bin
ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" ~/bin/subl

#Setup some defaults
defaults write com.apple.screencapture location ~/Downloads/
killall SystemUIServer