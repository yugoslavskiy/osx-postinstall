#!/bin/bash

set -e

# Use colors, but only if connected to a terminal, and that terminal
# supports them.
if which tput >/dev/null 2>&1; then
    ncolors=$(tput colors)
fi
if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
  RED="$(tput setaf 1)"
  BLUE="$(tput setaf 4)"
  BOLD="$(tput bold)"
  NORMAL="$(tput sgr0)"
else
  RED=""
  BLUE=""
  BOLD=""
  NORMAL=""
fi

TOOLS_LIST=$1

usage() {
	printf "${BOLD}Usage:${NORMAL}\n\n"
	printf "   ${GREEN}./$(basename "$0")${NORMAL} ${BLUE}path/to/tools_list.txt${NORMAL}\n\n"
}

[ -z "${TOOLS_LIST}" ] && { 
	printf "\n${RED}[!] Error: no path/to/tools_list.txt provided.${NORMAL}\n\n"
	usage;
	exit 1;
}

export HOMEBREW_CASK_OPTS="--appdir=/Applications"

command_list=(
	"brew install" 
	"brew cask install" 
	"pip install" 
	"gem install" 
	"brew tap" 
	"vagrant plugin install" 
)

declare -a errors

cat $TOOLS_LIST | grep -v "#" | tr -s '[:space:]' | sed '/^$/d' | while read line; 
do
	tool=$(   echo ${line} | cut -d ':' -f 1 );
	number=$( echo ${line} | cut -d ':' -f 2 );

	# In case of manual launch agent adding (for example, tor:6)
	if [ ${number} = 6 ] ; then
		mkdir -p ~/Library/LaunchAgents;
		ln -sfv /usr/local/opt/${tool}/*.plist ~/Library/LaunchAgents;
  else
		${command_list["${number}"]} ${tool} || {
			printf "\n${RED}[!] Error: ${tool} installation failed.${NORMAL}\n\n"
			errors+=(fail)
  	}
	fi
done

brew cleanup --force >& /dev/null;
brew cask cleanup --force >& /dev/null;
brew prune >& /dev/null;
find /opt/homebrew-cask/Caskroom -type f \( -name '*.dmg' -o -name '*.pkg' \) -delete >& /dev/null;
find /Library/Caches/Homebrew/ -type f -delete >& /dev/null;

# it's not working...
[ -z "$errors" ] || return 10