#!/bin/bash
# shellcheck shell=bash

echo "Prompting for sudo password..."
sudo --validate
while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done &>/dev/null &
