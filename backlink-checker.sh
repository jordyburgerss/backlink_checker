#!/bin/bash
# Script to check backlinks on multiple search engines and social media platforms

# Maximum timeout in seconds
TOTAL_TIMEOUT="10"

# Number of retries if connection fails
WEB_RETRIES="3"

# SCRIPT VARS
E_WGET=$(type -P wget)
E_GREP=$(type -P grep)
SUCCESS_COUNT=0
FAIL_COUNT=0
LOG_COUNT=0
VERBOSE_LOG=0

bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)

purple=$(tput setaf 171)
red=$(tput setaf 1)
green=$(tput setaf 76)
tan=$(tput setaf 3)
blue=$(tput setaf 38)

# Function to print headers
e_header() {
  printf "\n${bold}${purple}==========  %s  ==========${reset}\n" "$@"
}

# Function to print success messages
e_success() {
  printf "${green}✔ %s${reset}\n" "$@"
}

# Function to print error messages
e_error() {
  printf "${red}✖ %s${reset}\n" "$@"
}

# Function to print warning messages
e_warning() {
  printf "${tan}➜ %s${reset}\n" "$@"
}

# Function to save logs
SaveToLog() {
  if [[ -z $1 ]] || [[ -z $2 ]]; then
    echo "Internal error. Invalid parameters in save log function."
    return 1
  fi

  unset FILENAME

  case $1 in
  "SUCCESS")
    FILENAME=$SUCCESS_FILE
    ((SUCCESS_COUNT++))
    ;;
  "FAIL")
    FILENAME=$FAILURE_FILE
    ((FAIL_COUNT++))
    ;;
  "LOG")
    FILENAME=$OUTPUT_FILE
    ((LOG_COUNT++))
    ;;
  *)
    echo "Internal error. Invalid log type."
    return 1
    ;;
  esac

  if [[ -z $FILENAME ]]; then
    return 0
  fi

  echo "$2" >>"$FILENAME"
  return 0
}

# Function to check website for URL
CheckWebsiteForURL() {
  if [[ -z $1 ]]; then
    echo "Internal error. No server specified."
    return 1
  fi
  if [[ $VERBOSE_LOG -gt 0 ]]; then
    echo "Checking $1"
  fi

  RESPONSE=$($E_WGET -O- -nv -q --timeout=$TOTAL_TIMEOUT --tries=$WEB_RETRIES "$1" 2>&1)
  THE_STATUS=$?
  if [[ $THE_STATUS != 0 ]]; then
    SaveToLog "LOG" "$1 failed to download. Error code $THE_STATUS. Response: $RESPONSE"
    return 1
  fi
  SEARCH_RESULT=$(echo "$RESPONSE" | $E_GREP -o "$SEARCH_URL" 2>&1)
  if [[ -n $SEARCH_RESULT ]]; then
    COUNT=$(echo "$SEARCH_RESULT" | wc -l)
    SaveToLog "LOG" "$1 contains $COUNT occurrences of $SEARCH_URL"
    echo "$1: $COUNT occurrences"
    return 0
  fi
  SaveToLog "LOG" "$1 does not contain $SEARCH_URL"
  return 1
}

# Main code
for ((i = 1; i <= $#; i++)); do
  case ${!i} in
  "-v")
    VERBOSE_LOG=1
    ;;
  "-input")
    ((i++))
    URLS_FILE=${!i}
    ;;
  "-log")
    ((i++))
    OUTPUT_FILE=${!i}
    ;;
  "-url")
    ((i++))
    SEARCH_URL=${!i}
    ;;
  *)
    e_warning "Unknown argument ${!i}"
    exit 1
    ;;
  esac
done

if [[ -z $URLS_FILE ]] || [[ -z $SEARCH_URL ]]; then
  e_error "Required arguments missing."
  echo "${bold}SYNOPSIS${reset}"
  echo -e "\t${bold}$0${reset} ${bold}-input${reset} ${underline}FILE${reset} ${bold}-url${reset} ${underline}URL${reset} [OPTIONS]"
  exit 1
fi

if [[ ! -f $E_WGET ]]; then
  e_error "Failed to find wget. Please, install the related package."
  exit 1
fi
if [[ ! -f $E_GREP ]]; then
  e_error "Failed to find grep. Please, install the related package."
  exit 1
fi
if [[ ! -f $URLS_FILE ]]; then
  e_error "The specified file $URLS_FILE not found"
  exit 1
fi

TOTAL_URLS=$(wc -l < "$URLS_FILE")
CURRENT_URL=0

while IFS= read -r line; do
  if [[ -n $line ]]; then
    ((CURRENT_URL++))
    CheckWebsiteForURL "$line"
    THE_STATUS=$?

    if [[ $THE_STATUS != 0 ]]; then
      SaveToLog "FAIL" "$line"
      e_warning "$line does not contain $SEARCH_URL"
    else
      SaveToLog "SUCCESS" "$line"
      e_success "$line contains $SEARCH_URL"
    fi
  fi
done < <($E_GREP "" $URLS_FILE)

echo -ne "\nScanning complete. Processed $CURRENT_URL out of $TOTAL_URLS URLs.\n"

if [[ $VERBOSE_LOG -gt 0 ]]; then
  echo "All operations complete"
fi
exit 0
