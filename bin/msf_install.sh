#!/usr/bin/env bash

# Original post:
# http://www.darkoperator.com/installing-metasploit-framewor/

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
  WHITE="$(tput setaf 7)"
  BOLD="$(tput bold)"
  NORMAL="$(tput sgr0)"
else
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  WHITE=""
  BOLD=""
  NORMAL=""
fi

usage () {
  echo "${BOLD}Metasploit Framework installation script for Mac OS X 10.11.${NORMAL}"
  echo ""
  echo "${BOLD}Description:${NORMAL}"
  echo ""
  echo "    Script uses default ruby (2.3.0p0), java (1.8.0) and postgresql (9.5.1)"
  echo "    versions from Homebrew for MSF installation."
  echo "    It will install them if required. Original article:"
  echo "    http://www.darkoperator.com/installing-metasploit-framewor/"
  echo ""
  echo "${BOLD}Usage:${NORMAL}"
  echo ""
  echo "    ${GREEN}./$(basename $0)${NORMAL} ${BLUE}--db_user${NORMAL} <username> ${BLUE}--db_pass${NORMAL} <password> ${BLUE}--db_name${NORMAL} <db name> [${RED}--reinstall${NORMAL}]"
  echo ""
  echo "${BOLD}Where:${NORMAL}"
  echo ""
  echo "    ${BLUE}--db_user${NORMAL}     New postgresql user for MSF (${YELLOW}default: ${BOLD}msf${NORMAL})"
  echo ""
  echo "    ${BLUE}--db_pass${NORMAL}     New postgresql user password for MSF (${YELLOW} default: ${BOLD}msf${NORMAL})"
  echo ""
  echo "    ${BLUE}--db_name${NORMAL}     Name of new postgresql database for MSF (${YELLOW}default: ${BOLD}msf${NORMAL})"
  echo ""
  echo "    ${BLUE}--reinstall${NORMAL}   ${RED}WARNING: The script will ${BOLD}completely${NORMAL} ${RED}remove postgresql"
  echo "                  and all old msf stuff and install it again.${NORMAL} (${YELLOW}default: ${BOLD}not${NORMAL})"
  echo ""
}

# Defaults
MSF_DB_USER=msf
MSF_DB_PASS=msf
MSF_DB_NAME=msf
MSF_REINSTALL=n
RUBY_VERSION=' 2.3.'
JAVA_VERSION=' 1.8.'

##### Read command line arguments
while [[ "${#}" -gt 0 && ."${1}" == .-* ]]; do
  opt="${1}";
  shift;
  case "$(echo ${opt} | tr '[:upper:]' '[:lower:]')" in
    -|-- ) break 2;;
    --help|-help|-h) usage; exit 0 ;;

    --db_user|-db_user ) MSF_DB_USER="${1}"; shift;;
    --db_user=*|-db_user=* ) MSF_DB_USER="${opt#*=}";;

    --db_pass|-db_pass ) MSF_DB_PASS="${1}"; shift;;
    --db_pass=*|-db_pass=* ) MSF_DB_PASS="${opt#*=}";;

    --db_name|-db_name ) MSF_DB_NAME="${1}"; shift;;
    --db_name=*|-db_name=* ) MSF_DB_NAME="${opt#*=}";;

    --reinstall|-reinstall ) MSF_REINSTALL=y ;;
     *) printf '\n'${RED}'[!]'${NORMAL}" Unknown option: ${RED} ${opt} ${NORMAL}\n\n" 1>&2 ; usage; exit 1;;
   esac
done

# Check if MSF already installed and there is no ``--reinstall'' flag
hash msfconsole >& /dev/null && [ $MSF_REINSTALL != 'y' ] && {
  echo ""
  printf "${RED}[!] Metasploit Framework already installed! To reinstall use "
  printf "${BLUE}\'--reinstall\'${NORMAL} ${RED}flag.${NORMAL}\n"
  echo ""
  usage
  exit 1
}

# Check if Postgresql already installed and there is no ``--reinstall'' flag
hash postgres >& /dev/null && [ $MSF_REINSTALL != 'y' ] && {
  printf "${RED}[!] Postgresql already installed, and it's a problem. "
  printf "To continue MSF installation you have to use ${BOLD}\'--reinstall\'${NORMAL} ${RED}flag.${NORMAL}\n"
  exit 1
}

# Ask for admin password
printf "${YELLOW}[!] I need root password for installations.${NORMAL}\n"
sudo -v

# Keep-alive: update existing `sudo` time stamp until `install.sh` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

printf "${BLUE}[*] Checking Xcode...${NORMAL}\n"
[ "$( xcode-select --install 2>&1 | grep -i 'already installed' )" ] || {
  printf "${RED}[!] You have to manually install Xcode via App Store before run the script.${NORMAL}\n"
}

# Auto agree
sudo xcodebuild -license accept

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

# Set up permissons (el capitan bugfix)
sudo chown -R $( whoami ) /usr/local

# In case of reinstall
[ "${MSF_REINSTALL}" = "y" ] && {
  printf "${YELLOW}[i] Removing postgres...${NORMAL}\n"
  printf "${YELLOW}[i] Stopping postgres deamon...${NORMAL}\n"
  launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist >& /dev/null

  printf "${YELLOW}[i] Reinstalling postgres via Homebrew...${NORMAL}\n"
  brew remove postgresql >& /dev/null
  printf "${YELLOW}[i] Removing postgres softlinks...${NORMAL}\n"
  brew cleanup --force >& /dev/null
    brew prune >& /dev/null
  
  printf "${YELLOW}[i] Removing all postgres files form \'/usr/local/\'...${NORMAL}\n"
  rm -rfv /usr/local/var/postgres >& /dev/null
  rm -rfv /usr/local/share/postgresql >& /dev/null
  rm -rfv /usr/local/Cellar/postgresql >& /dev/null
  
  sudo chown -R $( whoami ) /usr/local
  
  printf "${YELLOW}[i] Removing MSF files...${NORMAL}\n"
  rm -rfv $( dirname $( realpath $( which msfconsole >& /dev/null ) >& /dev/null ) >& /dev/null ) >& /dev/null || {
    rm -rfv /usr/local/share/metasploit-framework >& /dev/null
  }
  printf "${YELLOW}[i] Removing MSF gems...${NORMAL}\n"
  gem cleanup >& /dev/null
}

printf "${BLUE}[*] Checking ruby version...${NORMAL}\n"
ruby -v | grep ${RUBY_VERSION} >& /dev/null || {
  printf "${RED}[-] Error: Ruby version is not${RUBY_VERSION}*${NORMAL}\n"
  printf "${YELLOW}[i] Trying to install Ruby via Homebrew...${NORMAL}\n"
  brew install ruby  || {
    printf "${RED}[-] Error: Ruby installation failed.${NORMAL} Quitting...\n"
    exit 1
  }
}

printf "${BLUE}[*] Checking Bundler...${NORMAL}\n"
hash bundler >& /dev/null || {
  printf "${RED}[!] Error: Bundler is not installed${NORMAL}\n"
  printf "${YELLOW}[i] Trying to install Bundler via Gem...${NORMAL}\n"
  gem install bundler >& /dev/null || {
    printf "${RED}[-] Error: Bundler installation failed.${NORMAL} Quitting...\n"
    exit 1
  }
}

printf "${BLUE}[*] Checking Nmap...${NORMAL}\n"
hash nmap >& /dev/null || {
  printf "${RED}[!] Error: Nmap is not installed.${NORMAL}\n"
  printf "${YELLOW}[i] Trying to install Nmap via Homebrew...${NORMAL}\n"
  brew install nmap >& /dev/null || {
    printf "${RED}[-] Error: Nmap installation failed.${NORMAL} Quitting...\n"
    exit 1
  }
}

printf "${BLUE}[*] Checking Java...${NORMAL}\n"
hash java >& /dev/null || {
  printf "${RED}[!] Error: Java is not installed${NORMAL}\n"
  printf "${YELLOW}[i] Trying to install Java via Homebrew...${NORMAL}\n"
  brew cask install java >& /dev/null || {
    printf "${RED}[-] Error: Java installation failed.${NORMAL} Quitting...\n"
    exit 1
  }
}

printf "${BLUE}[*] Checking Java version...${NORMAL}\n"
java -version 2>&1 | grep ${JAVA_VERSION} >& /dev/null || {
  printf "${RED}[!] Error: Java version is not${JAVA_VERSION}*${NORMAL}\n"
  printf "${YELLOW}[i] Trying to update it via Homebrew...${NORMAL}\n"
  brew cask info java | grep -i 'Not installed' >& /dev/null && {
    printf "${RED}[-] Error: Java haven't been installed via Homebrew.${NORMAL}\n"
    printf "${YELLOW}[i] Try to install Java via Homebrew or update it manually.${NORMAL} Quitting... \n"
    exit 1
  }
  brew cask install java --force >& /dev/null || {
    printf "${RED}[-] Error: Java installation failed.${NORMAL} Quitting... \n"
    exit 1
  }
}

printf "${GREEN}[+]${NORMAL} Installing ${GREEN}Postgresql${NORMAL} via Homebrew...\n"
brew install postgresql --without-ossp-uuid >& /dev/null || {
  printf "\n${RED}[-] Error: Postgresql installation failed.${NORMAL} Quitting... \n"
  exit 1
}

# fix permissions again
sudo chown -R $( whoami ) /usr/local 

# just in case...
rm -rfv /usr/local/var/postgres >& /dev/null

printf "${GREEN}[+]${NORMAL} Initializing ${GREEN}Postgresql${NORMAL} database...\n"
initdb /usr/local/var/postgres >& /dev/null || {
  printf "\n${RED}[-] Error: Cannot create new Postgresql database (initdb).${NORMAL} Quitting... \n"
  exit 1
}

sleep 5

printf "${GREEN}[+]${NORMAL} Creating ${GREEN}Postgresql${NORMAL} daemon...\n"
mkdir -p ~/Library/LaunchAgents
ln -sfv /usr/local/opt/postgresql/*.plist ~/Library/LaunchAgents

printf "${GREEN}[+]${NORMAL} Launching ${GREEN}Postgresql${NORMAL} daemon...\n"
launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist >& /dev/null || {
  printf "\n${RED}[-] Error: Cannot launch Postgresql...${NORMAL} Quitting... \n"
  exit 1
}

sleep 5

printf "${GREEN}[+]${NORMAL} Creating ${GREEN}Postgresql${NORMAL} ${BOLD}user${NORMAL}...\n"
createuser ${MSF_DB_USER} -h localhost >& /dev/null || {
  printf "\n${RED}[-] Error: Cannot create Postgresql user.${NORMAL} Quitting... \n"
  exit 1
}

sleep 5

printf "${GREEN}[+]${NORMAL} Creating ${GREEN}Postgresql${NORMAL} user ${BOLD}password${NORMAL}...\n"
sudo -u _postgres psql -U  $( whoami ) -d postgres -c "ALTER USER ${MSF_DB_USER} WITH PASSWORD '${MSF_DB_PASS}';;" >& /dev/null || {
  printf "\n${RED}[-] Error: Cannot add password to ${MSF_DB_USER} user in postgres.${NORMAL}\n"
  printf "\n${RED}[!] I will continue, but remember — ${MSF_DB_USER} user password is blank. "
  printf "You should (but not required) create it manually.${NORMAL}\n"
  MSF_DB_PASS=""
}

printf "${GREEN}[+]${NORMAL} Creating ${GREEN}Postgresql${NORMAL} ${BOLD}database${NORMAL} for MSF...\n"
createdb -O ${MSF_DB_USER} ${MSF_DB_NAME} -h localhost >& /dev/null || {
  printf "\n${RED}[-] Error: Cannot create Postgresql database.${NORMAL} Quitting... \n"
  exit 1
}

printf "${GREEN}[+]${NORMAL} Cloning ${GREEN}MSF${NORMAL} repo...\n"
git clone https://github.com/rapid7/metasploit-framework.git /usr/local/share/metasploit-framework >& /dev/null || {
    printf "\n${RED}[-] Error: Cloning of MSF repo failed.${NORMAL} Quitting... \n"
    exit 1
}

cd /usr/local/share/metasploit-framework

# Symlink bugfix (in case of RVM, who knows)
for MSF in $(ls msf*); do ln -s /usr/local/share/metasploit-framework/$MSF /usr/local/bin/$MSF >& /dev/null ;done

# Installing Metasploit Framework
printf "${GREEN}[+]${NORMAL} Installing ${GREEN}MSF${NORMAL} via Bundler...\n"
bundle install >& /dev/null || {
    printf "\n${RED}[-] Error: Bundler installation of MSF failed.${NORMAL} Quitting... \n"
    exit 1
}

printf "${GREEN}[+]${NORMAL} Creating ${GREEN}database.yml${NORMAL} — database configuration file...\n"
cat > /usr/local/share/metasploit-framework/config/database.yml << EOF
production:
 adapter: postgresql
 database: ${MSF_DB_NAME}
 username: ${MSF_DB_USER}
 password: ${MSF_DB_PASS}
 host: 127.0.0.1
 port: 5432
 pool: 75
 timeout: 5
EOF

echo ""
echo "${BLUE}MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM${NORMAL}"
echo "${BLUE}MMMMMMMMMMM                MMMMMMMMMM${NORMAL}"
echo "${BLUE}MMMNv${NORMAL}                           ${BLUE}vMMMM${NORMAL}"
echo "${BLUE}MMMNl${NORMAL}  ${WHITE}MMMMM             MMMMM${NORMAL}  ${BLUE}JMMMM${NORMAL}"
echo "${BLUE}MMMNl${NORMAL}  ${WHITE}MMMMMMMN       NMMMMMMM${NORMAL}  ${BLUE}JMMMM${NORMAL}"
echo "${BLUE}MMMNl${NORMAL}  ${WHITE}MMMMMMMMMNmmmNMMMMMMMMM${NORMAL}  ${BLUE}JMMMM${NORMAL}"
echo "${BLUE}MMMNI${NORMAL}  ${WHITE}MMMMMMMMMMMMMMMMMMMMMMM${NORMAL}  ${BLUE}jMMMM${NORMAL}"
echo "${BLUE}MMMNI${NORMAL}  ${WHITE}MMMMMMMMMMMMMMMMMMMMMMM${NORMAL}  ${BLUE}jMMMM${NORMAL}"
echo "${BLUE}MMMNI${NORMAL}  ${WHITE}MMMMM   MMMMMMM   MMMMM${NORMAL}  ${BLUE}jMMMM${NORMAL}"
echo "${BLUE}MMMNI${NORMAL}  ${WHITE}MMMMM   MMMMMMM   MMMMM${NORMAL}  ${BLUE}jMMMM${NORMAL}"
echo "${BLUE}MMMNI${NORMAL}  ${WHITE}MMMNM   MMMMMMM   MMMMM${NORMAL}  ${BLUE}jMMMM${NORMAL}"
echo "${BLUE}MMMNI${NORMAL}  ${WHITE}WMMMM   MMMMMMM   MMMM#${NORMAL}  ${BLUE}JMMMM${NORMAL}"
echo "${BLUE}MMMMR${NORMAL}  ${WHITE}?MMNM             MMMMM${NORMAL} ${BLUE}.dMMMM${NORMAL}"
echo "${BLUE}MMMMNm${NORMAL} ${WHITE}?MMM              MMMM${NORMAL}  ${BLUE}dMMMMM${NORMAL}"
echo "${BLUE}MMMMMMN${NORMAL}  ${WHITE}?MM             MM?${NORMAL}  ${BLUE}NMMMMMN${NORMAL}"
echo "${BLUE}MMMMMMMMNe                 JMMMMMNMMM${NORMAL}"
echo "${BLUE}MMMMMMMMMMNm,            eMMMMMNMMNMM${NORMAL}"
echo "${BLUE}MMMMNNMNMMMMMNx        MMMMMMNMMNMMNM${NORMAL}"
echo "${BLUE}MMMMMMMMNMMNMMMMm+..+MMNMMNMNMMNMMNMM${NORMAL}"
echo "                                     ${BLUE}...is now installed!${NORMAL}"
echo ""

#-Done-----------------------------------------------------------------------#

printf "\n${YELLOW}[i]${NORMAL} Don't forget to:"
printf "\n${YELLOW}[i]${NORMAL} Place 'source /usr/local/share/metasploit-framework/config/database.yml' "
printf "line in your shell profile."

exit 0
