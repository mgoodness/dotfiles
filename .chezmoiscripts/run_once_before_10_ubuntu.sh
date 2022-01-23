{{- if (eq .chezmoi.os "linux") -}}
{{- if (eq .chezmoi.osRelease.id "ubuntu") -}}
#!/usr/bin/env bash

echo "## Updating & upgrading system packages"
sudo apt update
sudp apt upgrade -y

echo "## Installing Zsh"
sudo apt install -y zsh
sudo usermod -s /usr/bin/zsh $(whoami)
{{- end }}
