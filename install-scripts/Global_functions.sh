#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Global Functions for Scripts #

set -e

# Set some colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

# Create Directory for Install Logs
if [ ! -d Install-Logs ]; then
    mkdir Install-Logs
fi

# Function that would show a progress
show_progress() {
    local pid=$1
    local package_name=$2
    local spin_chars=("●○○○○○" "○●○○○○" "○○●○○○" "○○○●○○" "○○○○●○" "○○○○○●" \
                      "○○○○●○" "○○○●○○" "○○●○○○" "○●○○○○")  # Growing & Shrinking Dots
    local i=0

    tput civis  # Hide cursor
    printf "\r${NOTE} Installing ${YELLOW}%s${RESET} ..." "$package_name"

    while ps -p $pid &> /dev/null; do
        printf "\r${NOTE} Installing ${YELLOW}%s${RESET} %s" "$package_name" "${spin_chars[i]}"
        i=$(( (i + 1) % 10 ))  
        sleep 0.3  
    done

    printf "\r${NOTE} Installing ${YELLOW}%s${RESET} ... Done!%-20s\n" "$package_name" ""
    tput cnorm  
}


# Function to install packages with pacman
install_package_pacman() {
  # Check if package is already installed
  if pacman -Q "$1" &>/dev/null ; then
    echo -e "${OK} ${MAGENTA}$1${RESET} is already installed. Skipping..."
    printf "\n%.0s" {1..1}
  else
    # Run pacman and redirect all output to a log file
    (
      stdbuf -oL sudo pacman -S --noconfirm --needed "$1" 2>&1
    ) >> "$LOG" 2>&1 &
    PID=$!
    show_progress $PID "$1" 

    # Double check if package is installed
    if pacman -Q "$1" &>/dev/null ; then
      echo -e "${OK} Package ${YELLOW}$1${RESET} has been successfully installed!"
    else
      echo -e "\n${ERROR} ${YELLOW}$1${RESET} failed to install. Please check the $LOG. You may need to install manually."
      exit 1
    fi
  fi
}

ISAUR=$(command -v yay || command -v paru)

# Function to install packages with either yay or paru
install_package() {
  # Checking if package is already installed
  if $ISAUR -Q "$1" &>> /dev/null ; then
    echo -e "${OK} ${MAGENTA}$1${RESET} is already installed. Skipping..."
    printf "\n%.0s" {1..1}
  else
    # Run yay/paru and redirect all output to a log file
    (
      stdbuf -oL $ISAUR -S --noconfirm --needed "$1" 2>&1
    ) >> "$LOG" 2>&1 &
    PID=$!
    show_progress $PID "$1"  
    
    # Double check if package is installed
    if $ISAUR -Q "$1" &>> /dev/null ; then
      echo -e "${OK} Package ${YELLOW}$1${RESET} has been successfully installed!"
    else
      # Something is missing, exiting to review log
      echo -e "\n${ERROR} ${YELLOW}$1${RESET} failed to install :( , please check the install.log. You may need to install manually! Sorry I have tried :("
      exit 1
    fi
  fi
}

# Function for uninstalling packages
uninstall_package() {
  local pkg="$1"

  # Checking if package is installed
  if pacman -Qi "$pkg" &>> /dev/null ; then
    # Package is installed
    echo -e "${NOTE} Uninstalling $pkg ..."
    sudo pacman -R --noconfirm "$pkg" 2>&1 | tee -a "$LOG" | grep -v "error: target not found"
    # Check if the package was uninstalled
    if ! pacman -Qi "$pkg" &>> /dev/null ; then
      echo -e "\e[1A\e[K${OK} $pkg was uninstalled."
    else
      echo -e "\e[1A\e[K${ERROR} $pkg failed to uninstall. Please check the log."
      return 1 
    fi
  fi
  return 0 
}