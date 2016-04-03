#!/bin/sh

set -e

# Use colors, but only if connected to a terminal, and that terminal
# supports them.
if which tput >/dev/null 2>&1; then
    ncolors=$(tput colors)
fi
if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
  RED="$(tput setaf 1)"
  GREEN="$(tput setaf 2)"
  YELLOW="$(tput setaf 3)"
  BLUE="$(tput setaf 4)"
  BOLD="$(tput bold)"
  NORMAL="$(tput sgr0)"
else
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  BOLD=""
  NORMAL=""
fi


usage() {
	echo ""
	echo "${BOLD}Post-installation script for Mac OS X 10.11.${NORMAL}"
	echo ""
	echo "${BOLD}Description:${NORMAL}"
	echo ""
	echo "   Script uses ${GREEN}BlockBlock${NORMAL} and ${GREEN}OS X Lockdown${NORMAL} (optionally) for system hardening,"
	echo "   after that — install all tools from Darwin/install/tools_list.txt and other sources."
	echo "   For more information please see source code."
	echo ""
	echo "${BOLD}Usage:${NORMAL}"
	echo ""
	echo "   ${GREEN}./$(basename "$0")${NORMAL} ${BLUE}<options>${NORMAL}"
  echo ""
  echo "${BOLD}Options:${NORMAL}"
  echo ""
  echo "   ${BLUE}--all${NORMAL} 		Use ${GREEN}all${NORMAL} options (below)."
  echo ""
  echo "   ${BLUE}--bb_first${NORMAL} 		Force install ${GREEN}BlockBlock${NORMAL} first to control Launch Agents installations."
  echo ""
  echo "   ${BLUE}--osxlockdown${NORMAL} 	Apply ${GREEN}OSX Lockdown${NORMAL} security settings."
  echo ""
  echo "   ${BLUE}--osxdefaults${NORMAL}   	Apply ${GREEN}OSX Defaults${NORMAL} settings."
  echo ""
  echo "   ${BLUE}--msf${NORMAL}           	Install ${GREEN}Metasploit Framework${NORMAL}."
  echo ""
  echo "   ${BLUE}--dotfiles${NORMAL}      	Install ${GREEN}dotfiles${NORMAL}."
  echo ""
  echo "   ${BLUE}--st3${NORMAL}     		Setup ${GREEN}Sublime Text 3${NORMAL}."
  echo ""
  echo "   ${BLUE}--git_install${NORMAL} 	Install a few tools from github / bitbucket."
  echo ""
}

while test "$#" != 0; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --all) ALL_OPT=y ;;
        --bb_first) BB_FIRST=y ;;
				--osxlockdown) OSX_LOCKDOWN=y ;;
        --osxdefaults) OSX_DEFAULTS=y ;;
        --dotfiles) DOTFILES=y ;;
				--msf) MSF=y ;;
        --st3) ST3=y ;;
				--git_install) GIT_INSTALL=y ;;
        --) shift; break ;; # standard terminate loop; end of options list
        -*) echo >&2 "$0: unknown option '$1'"; usage; exit 1 ;;
        *) echo >&2 "$0: unknown argument '$1'"; usage; exit 1 ;;
    esac
    shift
done


[ "${ALL_OPT}" = "y" ] && {
	BB_FIRST=y;
	OSX_LOCKDOWN=y;
	OSX_DEFAULTS=y;
	DOTFILES=y;
	MSF=y;
	ST3=y;
	GIT_INSTALL=y;
}


source defaults.sh

# Ask for admin password
printf "${YELLOW}[!] I need root password for installations.${NORMAL}\n"
sudo -v

# Keep-alive: update existing sudo time stamp until install.sh has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Set up permissons (el capitan bugfix)
sudo chown -R $( whoami ) /usr/local

###############################################################################
# Xcode checking 					                                              			#
###############################################################################

printf "${BLUE}[*]${NORMAL} Checking ${GREEN}Xcode Command Line Tools${NORMAL} installation...\n"

[ "$( xcode-select --install 2>&1 | grep 'already installed' )" ] || {
	printf "${RED}[!] You have to manually install Xcode via App Store and run the script again.${NORMAL}\n"
	exit 1;
}

# Auto agree if installed
sudo xcodebuild -license accept;

printf "${GREEN}[*]${NORMAL} ${GREEN}Xcode Command Line Tools${NORMAL} are installed.\n"

###############################################################################
# Homebrew  				                                              						#
###############################################################################

printf "${BLUE}[*]${NORMAL} Checking ${GREEN}Homebrew${NORMAL} installation...\n"
if (hash brew >& /dev/null)
then
	printf "${GREEN}[*]${NORMAL} ${GREEN}Homebrew${NORMAL} is already installed. Update it...\n"
	brew update >& /dev/null;
	printf "${GREEN}[*]${NORMAL} ${GREEN}Homebrew${NORMAL} is updated.\n"
else
	printf "${GREEN}[+]${NORMAL} Installing ${GREEN}Homebrew${NORMAL}...\n"
	yes '' | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" >& /dev/null || {
  	printf "${RED}[!] Error: Homebrew installation failed.${NORMAL} Quitting...\n"
  	exit 1;
	}
	printf "${GREEN}[*]${NORMAL} ${GREEN}Homebrew${NORMAL} is installed.\n"
fi

################################################################################
## BlockBlock 				 		                                              			 #
################################################################################

# If '--bb_first' flag is set and app does not exists, download it
if [[ ( "${BB_FIRST}" = "y" ) && ! ( -e /Applications/BlockBlock.app ) ]]
then
	printf "${GREEN}[+]${NORMAL} Downloading ${GREEN}BlockBlock${NORMAL}...\n"
	brew cask install blockblock || {
		echo ''
		printf "${RED}[!] Error: BlockBlock download failed.${NORMAL}\n"
		echo ''
		exit 1
	}
	printf "${GREEN}"
	echo ''
	echo ' ______          _____   _____          ______          _____   _____        	'
	echo ' |_____] |      |     | |       |____/  |_____] |      |     | |       |____/ '
	echo ' |_____] |_____ |_____| |_____  |    \  |_____] |_____ |_____| |_____  |    \ '
	echo '                                                                          		'
	echo '...is downloaded. 																														'
	printf "${NORMAL}"
	echo ''
	echo 'You have to install it following instructions above and run the script again.'
	echo ''
	exit 0

# If already installed
elif [[ ( "${BB_FIRST}" = "y" ) && ( -e /Applications/BlockBlock.app ) ]]
then
	printf "${GREEN}"
	echo ''
	echo ' ______          _____   _____          ______          _____   _____       	'
	echo ' |_____] |      |     | |       |____/  |_____] |      |     | |       |____/ '
	echo ' |_____] |_____ |_____| |_____  |    \  |_____] |_____ |_____| |_____  |    \ '
	echo '                                                                          		'
	echo '...is installed. 													 																		'
	printf "${NORMAL}"
	echo ''
	echo 'Now you will be able to permit or deny Launch Agents installations.'
	echo ''
	sleep 5
fi

###############################################################################
# OSX Lockdown settings																												#
###############################################################################

[ "${OSX_LOCKDOWN}" = "y" ] && {
	printf "${BLUE}[*]${NORMAL} Applying ${GREEN}OSX Lockdown${NORMAL} security settings...\n"
	./osxlockdown.sh >& /dev/null
	printf "${GREEN}[+] OSX Lockdown${NORMAL} security settings are applied.\n"
}

###############################################################################
# Tools install 								                                              #
###############################################################################

printf "${BLUE}[*]${NORMAL} Installing ${GREEN}tools${NORMAL} from tools_list.txt...\n"
source tools_install.sh $PATH_TO_TOOLS_LIST

# it's not working...
if [ $? = "10" ]
then
	printf "\n${YELLOW}[*] Something went wrong with tools installation.${NORMAL} Check ${RED}RED${NORMAL} output above.\n"
else
	printf "\n${GREEN}[+] Tools${NORMAL} are installed.\n"
fi

###############################################################################
# Metasploit Framework 					                                              #
###############################################################################

[ "${MSF}" = "y" ] && {
	printf "${BLUE}[*]${NORMAL} Installing ${GREEN}Metasplot Framework${NORMAL}...\n"
	source msf_install.sh
}

###############################################################################
# Dotfiles 	 	  		                                              						#
###############################################################################

[ "${DOTFILES}" = "y" ] && {
	printf "${BLUE}[*]${NORMAL} Installing ${GREEN}Dotfiles${NORMAL}...\n"
	bash -c "$(curl -fsSL https://raw.githubusercontent.com/yugoslavskiy/dotfiles/master/install.sh)"
}

###############################################################################
# Sublime Text settings																												#
###############################################################################

[ "${ST3}" = "y" ] && {
	printf "${BLUE}[*]${NORMAL} Applying ${GREEN}Sublime Text${NORMAL} settings...\n"
	source sublime_setup.sh ${PATH_TO_ST3_CONFIG_FILES}
}

###############################################################################
# Tools from github / bitbucket                                       				#
###############################################################################

[ "${GIT_INSTALL}" = "y" ] && {
	printf "${BLUE}[*]${NORMAL} Installing ${GREEN}github / bitbucket${NORMAL} tools...\n"
	source git_install.sh --git_tools_dir ${PATH_TO_GIT_TOOLS}
}

#############################################################################
# OSX Defaults settings                                           						#
#############################################################################

[ "${OSX_DEFAULTS}" = "y" ] && {
	printf "${BLUE}[*]${NORMAL} Applying ${GREEN}OSX Defaults${NORMAL} settings...\n"
	source osxdefaults.sh >& /dev/null
	printf "${GREEN}[+] OSX Defaults${NORMAL} settings are applied.\n"
}

# -Done-----------------------------------------------------------------------#

printf "\n${YELLOW}[i]${NORMAL} Don't forget to:"
printf "\n${YELLOW}[i]${NORMAL} Check the above output (Did everything install? Any errors? (${RED}HINT: What's in RED${NORMAL}?)\n\n"

printf "\n${GREEN}[+]${NORMAL} ${BOLD}OSX Postinstall${NORMAL}: ${GREEN}Done.${NORMAL}\n\n"

exit 0
