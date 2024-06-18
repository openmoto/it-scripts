#!/bin/bash

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Installing Docker..."
    
    # Update the package list
    sudo apt-get update
    
    # Install prerequisite packages
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker's official APT repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update the package list again
    sudo apt-get update
    
    # Install Docker
    sudo apt-get install -y docker-ce
    
    echo "Docker installed successfully."
else
    echo "Docker is already installed."
fi

# Get the current username
USER_NAME=$(whoami)

# Get the default shell for the user
SHELL_PATH=$(getent passwd $USER_NAME | cut -d: -f7)

# Determine the shell configuration file
if [[ "$SHELL_PATH" == */bash ]]; then
    SHELL_RC="$HOME/.bashrc"
elif [[ "$SHELL_PATH" == */zsh ]]; then
    SHELL_RC="$HOME/.zshrc"
else
    echo "Unsupported shell: $SHELL_PATH"
    exit 1
fi

# Add NOPASSWD line to sudoers file
SUDOERS_LINE="$USER_NAME ALL=(ALL) NOPASSWD: /usr/bin/dockerd"

if ! sudo grep -q "$SUDOERS_LINE" /etc/sudoers; then
    echo "$SUDOERS_LINE" | sudo EDITOR='tee -a' visudo
fi

# Define Docker startup commands
DOCKER_STARTUP_COMMANDS='
# Start Docker daemon automatically when logging in if not running.
RUNNING=`ps aux | grep dockerd | grep -v grep`
if [ -z "$RUNNING" ]; then
    sudo dockerd > /dev/null 2>&1 &
    disown
fi
'

# Add Docker startup commands to the shell configuration file if not already present
if ! grep -q "Start Docker daemon automatically" "$SHELL_RC"; then
    echo "$DOCKER_STARTUP_COMMANDS" >> "$SHELL_RC"
fi

# Add Docker startup commands to .profile if not already present
PROFILE_FILE="$HOME/.profile"
if ! grep -q "Start Docker daemon automatically" "$PROFILE_FILE"; then
    echo "$DOCKER_STARTUP_COMMANDS" >> "$PROFILE_FILE"
fi

echo "Configuration complete. Please restart your terminal or run 'source $SHELL_RC' and 'source $PROFILE_FILE' to apply the changes."
