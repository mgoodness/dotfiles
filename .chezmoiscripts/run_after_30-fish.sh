#!/bin/bash
# shellcheck shell=bash

shell=$(command -v fish)
if ! grep -q "$shell" /etc/shells; then
  echo "Updating login shell..."
  echo "$shell" | sudo tee -a /etc/shells
  chsh -s "$shell"
fi