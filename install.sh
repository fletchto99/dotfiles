 #!/bin/bash
if [ -d "~/.dotfiles" ]
then

	# Clone dotfiles
	git clone git@github.com:fletchto99/dotfiles.git ~/.dotfiles

elif [[ condition ]]
then
	echo "~/.dotfiles directory already exists! Make sure to git pull to ensure it is up to date"
fi

# Homebrew process
read -p "Do you wish to install homebrew? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then

	# Install homebrew
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

	# Ensure homebrew is up to date
	brew update
	brew upgrade

fi

read -p "Do you wish to install homebrew defaults? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	# Instal homebrew libs & tools
	brew install node nmap python3 sqlmap thefuck hub
fi


read -p "Do you wish to install casks? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	# Tap brew repos
	brew tap caskroom/cask

	# Install some default apps
	brew cask install keybase keepassx speedcrunch sublime-text tunnelblick iterm2 meld
fi

if [ -d "/Applications/iTerm.app/" ]
then
	read -p "Do you wish to setup iTerm configs? " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		# Backup old iterm configs
		mkdir -p ~/dotfiles_old/.iterm2
		cp -r ~/.iterm2 ~/dotfiles_old/.iterm2

		if [ -d ~/.iterm2 ]
		then
			rm -r ~/.iterm2
		fi

		# Configure iTerm 2 preferences
		ln -s  ~/.dotfiles/.iterm2 ~
		defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "~/.iterm2"
		defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true
	fi
else
	echo "Default terminal program does not appear to be iTerm!"
fi


read -p "Do you wish to install Oh-My-ZSH? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	# Install some default software
	curl -L http://install.ohmyz.sh | sh
fi

read -p "Do you wish to link your dotfiles? (old ones will be backed up to ~/dotfiles_old) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	mkdir -p ~/dotfiles_old

	#backup current dotfiles
	mv ~/.bash_profile ~/dotfiles_old/.bash_profile
	mv ~/.bashrc ~/dotfiles_old/.bashrc
	mv ~/.gitconfig ~/dotfiles_old/.gitconfig
	mv ~/.gitignore_global ~/dotfiles_old/.gitignore_global
	mv ~/.zshrc ~/dotfiles_old/.zshrc

	#regenerate gitconfig
	if [ -f '.gitconfig' ]
	then
		rm .gitconfig
	fi

	cp .gitconfig_template .gitconfig

	read -p "What name would you like in your gitconfig: " -e -r
	sed -i '' "s/#NAME#/$REPLY/g" '.gitconfig'

	read -p "What email would you like in your gitconfig: " -e -r
	sed -i '' "s/#EMAIL#/$REPLY/g" '.gitconfig'

	read -p "What signing key would you like in your gitconfig: " -e -r
	sed -i '' "s/#SIGNINGKEY#/$REPLY/g" '.gitconfig'

	read -p "What is your github username: " -e -r
	sed -i '' "s/#USERNAME#/$REPLY/g" '.gitconfig'

	# Link dotfiles
	ln -s ~/.dotfiles/.bash_profile ~/.bash_profile
	ln -s ~/.dotfiles/.bashrc ~/.bashrc
	ln -s ~/.dotfiles/.gitconfig ~/.gitconfig
	ln -s ~/.dotfiles/.gitignore_global ~/.gitignore_global
	ln -s ~/.dotfiles/.zshrc ~/.zshrc
fi

read -p "Do you wish to setup sublime configs? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then

	#Backup sublime prefs
	mkdir -p "$HOME/dotfiles_old/sublime/Packages"
	cp -r "$HOME/Library/Application Support/Sublime Text 3/Packages" "$HOME/dotfiles_old/sublime/Packages"
	rm -r "$HOME/Library/Application Support/Sublime Text 3/Packages"

	mkdir -p "$HOME/dotfiles_old/sublime/Installed Packages"
	cp -r "$HOME/Library/Application Support/Sublime Text 3/Installed Packages" "$HOME/dotfiles_old/sublime/Installed Packages"
	rm -r "$HOME/Library/Application Support/Sublime Text 3/Installed Packages"

	#Remove any old configs sublime
	if [ -d ~/.sublime ]
	then
		rm -r ~/.sublime
	fi

	#Setup sublime
	ln -s  ~/.dotfiles/.sublime ~

	mkdir -p "$HOME/Library/Application Support/Sublime Text 3/Packages"
	mkdir -p "$HOME/Library/Application Support/Sublime Text 3/Installed Packages"

	ln -s "$HOME/.sublime/Packages" "$HOME/Library/Application Support/Sublime Text 3/Packages"
	ln -s "$HOME/.sublime/Installed Packages" "$HOME/Library/Application Support/Sublime Text 3/Installed Packages"


	#Add subl command
	if [ ! -f "$HOME/bin/subl" ]
	then
		mkdir -p ~/bin
		ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" ~/bin/subl
	fi
fi

read -p "Do you wish to setup some Apple defaults? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	#Setup some defaults
	defaults write com.apple.screencapture location ~/Downloads/
	killall SystemUIServer
fi
