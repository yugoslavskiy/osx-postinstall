#!/usr/bin/env bash

# fail exit codes (future stuff):
# - cd: 101
# - rm: 102
# - install when update: 103
# - curl upload: 104
# - git clone: 105
# - git pull: 106
# - link create: 107
# - writing bin file: 108
# - chmod bin file: 109
# - bundle install: 110
# - gem install: 111
# - gem clean: 112
# - tool update itself: 113
# - pip install: 114

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

#source defaults.sh

SRC_DIR=~/src
BIN_DIR=~/bin
GIT_UPDATE=n
LIST_TOOLS=n
TOOL_NAME=all
GIT_TOOLS_DIR=../data/tools/git-tools
VERBOSE=n

usage() {
  echo "${BOLD}Usage:${NORMAL}"
  echo ""
  echo "   ${GREEN}./$(basename "$0")${NORMAL} [${BLUE}--git_tools_dir${NORMAL} <value>] [${BLUE}--tool${NORMAL} <value>] [${BLUE}--src_dir${NORMAL} <value>] [${BLUE}--bin_dir${NORMAL} <value>] [${BLUE}--update${NORMAL}] [${BLUE}--list${NORMAL}] [--verbose]"
  echo ""
  echo "${BOLD}Options:${NORMAL}"
  echo ""
  echo "      ${BLUE}--git_tools_dir${NORMAL}   Path to git tools directory"
  echo ""
  echo "      ${BLUE}--tool${NORMAL}            Tool name (${YELLOW}default: ${BOLD}all${NORMAL})"
  echo ""
  echo "      ${BLUE}--src_dir${NORMAL}         Directory for placing future git-repositories (${YELLOW} default: ${BOLD}${SRC_DIR}${NORMAL})"
  echo ""
  echo "      ${BLUE}--bin_dir${NORMAL}         Directory for placing links to future git-tools executables (${YELLOW}default: ${BOLD}${BIN_DIR}${NORMAL})"
  echo ""
  echo "      ${BLUE}--update${NORMAL}          Update all git-tools (${YELLOW}default: ${BOLD}not${NORMAL})"
  echo ""
  echo "      ${BLUE}--list${NORMAL}            List all existing git-tools (${YELLOW}default: ${BOLD}not${NORMAL})"
  echo ""
  echo "      ${BLUE}--verbose${NORMAL}         Be verbose"
  echo ""
}


##### Read command line arguments
while [[ "${#}" -gt 0 && ."${1}" == .-* ]]; do
  opt="${1}";
  shift;
  case "$(echo ${opt} | tr '[:upper:]' '[:lower:]' | tr '/\n' '\n' )" in
    -|-- ) break 2;;
    --help|-help|-h) usage; exit 0 ;;

    --git_tools_dir|-git_tools_dir ) GIT_TOOLS_DIR="${1}"; shift;;
    --git_tools_dir=*|-git_tools_dir=* ) GIT_TOOLS_DIR="${opt#*=}";;

    --tool|-tool ) TOOL_NAME="${1}"; shift;;
    --tool=*|-tool=* ) TOOL_NAME="${opt#*=}";;

    --src_dir|-src_dir ) SRC_DIR="${1}"; shift;;
    --src_dir=*|-src_dir=* ) SRC_DIR="${opt#*=}";;

    --bin_dir|-bin_dir ) BIN_DIR="${1}"; shift;;
    --bin_dir=*|-bin_dir=* ) BIN_DIR="${opt#*=}";;

    --list|-list ) LIST_TOOLS=y;;
    --update|-update ) GIT_UPDATE=y ;;
    --verbose|-verbose|-v ) VERBOSE=y ;;
     *) printf '\n'${RED}'[!]'${NORMAL}" Unknown option: ${RED} ${opt} ${NORMAL}\n\n" 1>&2 ; usage; exit 1;;
   esac
done


[ -z "${GIT_TOOLS_DIR}" ] && { 
  printf "\n${RED}[!] Error: no ${BLUE}--git_tools${NORMAL} argument provided.${NORMAL}\n\n"
  usage;
  exit 1;
}


if [ $GIT_UPDATE = 'y' ]
then
  ACTION=update && PROCESS=Updating && COMPLETE=updated && FAIL=Updating
elif [ $LIST_TOOLS = 'y' ]
then
  COMPLETE=listed
else
  ACTION=install && PROCESS=Installing && COMPLETE=installed && FAIL=Installation
fi


mkdir -p ${SRC_DIR}
mkdir -p ${BIN_DIR}

cd ${GIT_TOOLS_DIR}

for git_tool in $(ls);
do
  if [ $TOOL_NAME = 'all' ] 
  then
    if [ $LIST_TOOLS != 'y' ]
    then 
      pushd ${git_tool} >& /dev/null
      printf "${GREEN}[+]${NORMAL} ${PROCESS} ${GREEN}${git_tool}${NORMAL} --- ${YELLOW}$(cat description)${NORMAL}\n"
      if [ ${VERBOSE} = "y" ]
      then 
        bash "${ACTION}" "${BIN_DIR}" "${SRC_DIR}" || {
          printf "\n${RED}[!] Error: ${git_tool} ${FAIL} failed.${NORMAL}\n"
        }
      else
        bash "${ACTION}" "${BIN_DIR}" "${SRC_DIR}" >& /dev/null || {
          printf "\n${RED}[!] Error: ${git_tool} ${FAIL} failed.${NORMAL}. Use ${BLUE}--verbose${NORMAL} flag for more info.\n"
        }
      fi
      popd >& /dev/null
    else 
      echo ${git_tool}
    fi
  elif [ $TOOL_NAME = $git_tool ]
  then
    if [ $LIST_TOOLS != 'y' ]
    then
      pushd ${git_tool} >& /dev/null
      printf "${GREEN}[+]${NORMAL} ${PROCESS} ${GREEN}${git_tool}${NORMAL} --- ${YELLOW}$(cat description)${NORMAL}\n"
      if [ ${VERBOSE} = "y" ]
      then 
        bash "${ACTION}" "${BIN_DIR}" "${SRC_DIR}" || {
          printf "\n${RED}[!] Error: ${git_tool} ${FAIL} failed.${NORMAL}\n"
        }
      else
        bash "${ACTION}" "${BIN_DIR}" "${SRC_DIR}" >& /dev/null || {
          printf "\n${RED}[!] Error: ${git_tool} ${FAIL} failed.${NORMAL}. Use ${BLUE}--verbose${NORMAL} flag for more info.\n"
        }
      fi
      popd >& /dev/null
    else
      echo ${git_tool}
    fi
  fi
done

#-Done-----------------------------------------------------------------------#

#printf "\n${GREEN}[+] github / gist / bitbucket${NORMAL} tools are ${COMPLETE}.\n\n"

exit 0
