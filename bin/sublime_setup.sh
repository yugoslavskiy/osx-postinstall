#!/usr/bin/env bash

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

ST3_SETTINGS_FOLDER=$1

usage() {
  printf "${BOLD}Usage:${NORMAL}\n\n"
  printf "   ${GREEN}./$(basename "$0")${NORMAL} ${BLUE}path/to/folder/with/sublime_text/config/files${NORMAL}\n\n"
}

[ -z "${ST3_SETTINGS_FOLDER}" ] && { 
  printf "\n${RED}[!] Error: no path/to/folder/with/sublime_text/config/files provided.${NORMAL}\n\n"
  usage;
  exit 1;
}

USER_SETTINGS_FOLDER="$HOME/Library/Application Support/Sublime Text 3/Packages/User"
LINK_USER_SETTINGS_FOLDER="$( echo ${USER_SETTINGS_FOLDER} | sed 's/ /\\ /g' )"
PACKAGE_CONTROL_FOLDER="$HOME/Library/Application Support/Sublime Text 3/Installed Packages/Package Control.sublime-package"

printf "${GREEN}[+]${NORMAL} Creating ${GREEN}subl${NORMAL} - command line ST3 launcher...\n"
mkdir -p ~/bin;
ln -sfhv "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" ~/bin/subl >& /dev/null || {
  printf "\n${RED}[!] Error: Package Control installation failed.${NORMAL}\n"
}

printf "${GREEN}[+]${NORMAL} Installing ${GREEN}Package Control${NORMAL}...\n"
wget https://packagecontrol.io/Package%20Control.sublime-package -O "$PACKAGE_CONTROL_FOLDER" >& /dev/null || {
  printf "\n${RED}[!] Error: Package Control installation failed.${NORMAL}\n"
}

cd ${ST3_SETTINGS_FOLDER}

for CONFIG_FILE in $( ls ); do
  
  FULL_CONFIG_PATH="${USER_SETTINGS_FOLDER}/${CONFIG_FILE}"
  LINK_FULL_CONFIG_PATH=${LINK_USER_SETTINGS_FOLDER}/${CONFIG_FILE}

  printf "${BLUE}[*] Looking for an existing ${BOLD}${CONFIG_FILE}...${NORMAL}\n"
  if [[ -f ${FULL_CONFIG_PATH} ]] || [[ -h ${FULL_CONFIG_PATH} ]]; then
    printf "${YELLOW}[!] Found ${FULL_CONFIG_PATH}.${NORMAL}\n"
    printf "${GREEN}[*] Backing up to ${FULL_CONFIG_PATH}.pre-sublime-install${NORMAL}\n";
    mv "${FULL_CONFIG_PATH}" "${FULL_CONFIG_PATH}.pre-sublime-install";
  fi

  bash -c "ln -sfhv \"${PWD}/${CONFIG_FILE}\" ${LINK_FULL_CONFIG_PATH}" >& /dev/null

done

killall 'Sublime Text'

printf "\n${GREEN}[+] ST3 ${NORMAL}settings settings are applyed.\n"

exit 0