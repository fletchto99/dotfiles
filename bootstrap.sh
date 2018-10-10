 #!/bin/bash
if [ -d "~/.dotfiles" ]
then
	# Clone dotfiles
	git clone https://github.com/fletchto99/dotfiles.git ~/.dotfiles
else
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

if hash brew 2>/dev/null; then
read -p "Do you wish to install homebrew defaults? " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		# Instal homebrew libs & tools
		brew install automake binwalk cmake coreutils exiftool fcrackzip ffmpeg gdb gist git git-lfs glide gnupg go grep hashcat hub nmap nvm openssh pidof pinentry-mac pipenv pv radare2 rbenv rlwrap screen socat sqlmap telnet tree volatility wpscan
	fi

	read -p "Do you wish to install casks? " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		# Tap brew repos
		brew tap caskroom/cask
		brew tap buo/cask-upgrade

		# Install some default apps
		brew cask install 1password adobe-acrobat-reader bartender bettertouchtool binary-ninja burp-suite datagrip db-browser-for-sqlite deluge disablemonitor discord docker encryptme etcher filezilla google-chrome hyperdock idafree intellij-idea iterm2 java8 keka keybase mactex megasync meld messenger metasploit microsoft-office moom paragon-extfs plex-media-player runescape skim slack softu2f speedcrunch spotify steam sublime-text teamviewer vlc vmware-fusion whatsapp wireshark zoomus
	fi

	brew cleanup
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
	echo "iTerm not installed, skipping iTerm setup!"
fi

read -p "Do you wish to install Oh-My-ZSH? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	# Install some default software
	curl -L http://install.ohmyz.sh | sh
fi

read -p "Do you wish to setup nodejs? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	nvm install node
	nvm alias default node
	npm install npm-check-updates -g
	npm install pm2 -g
fi

if [ -d "/Applications/Sublime Text.app/" ]
then
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

		ln -s "$HOME/.sublime/Packages" "$HOME/Library/Application Support/Sublime Text 3/"
		ln -s "$HOME/.sublime/Installed Packages" "$HOME/Library/Application Support/Sublime Text 3/"


		#Add subl command
		if [ ! -f "$HOME/bin/subl" ]
		then
			mkdir -p ~/bin
			ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" ~/bin/subl
		fi
	fi
else
	echo "Sublime not installed; skipping sublime setup!"
fi

read -p "Do you wish to link your dotfiles? (old ones will be backed up to ~/dotfiles_old) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then

	mkdir -p ~/dotfiles_old

	files=( ".aliases" ".curlrc" ".editorconfig" ".exports" ".functions" ".gdbinit" ".gitignore_global" ".inputrc" ".screenrc" ".wgetrc" ".zshrc")

	for file in "${files[@]}"
	do
		if [[ -f ~/$file ]]
			cp -L ~/$file ~/dotfiles_old/$file
			rm -f ~/$file
		fi
		ln -s ~/.dotfiles/$file ~/$file
	done

	# Build gitconfig
	if [ -f '.gitconfig' ]
	then
			cp -L ~/.gitconfig ~/dotfiles_old/.gitconfig
			rm -f ~/.gitconfig
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

	# Link gitconfig
	ln -s ~/.dotfiles/.gitconfig ~/.gitconfig

	echo "Please run 'gist --login' after to finish github setup"
fi

read -p "Do you wish to setup some Apple defaults? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	./macos
fi
