# dotfiles

## Install

```shell
bash <(curl -fsLS chezmoi.io/get) -b ~/.local/bin -- init --apply --verbose mgoodness
```

## Update

```shell
chezmoi update
```

## Windows

1. In Administrator PowerShell
 
    ```powershell
    choco install -y firacodenf git gnupg microsoft-windows-terminal putty.install starship vscode
    ```

1. In User PowerShell

    ```powershell
    New-Item -Path $env:APPDATA/gnupg -ItemType Directory -Force
    Add-Content -Path $env:APPDATA/gnupg/gpg-agent.conf -Value "enable-putty-support`r`nenable-ssh-support"
    
    gpg --card-edit
    gpg/card> fetch
    
    gpg --edit-key 4A31C228815AA553
    gpg> trust
    
    # C:\Users\Michael Goodness\.gitconfig
    git config --global core.sshcommand 'plink -agent'
    git config --global gpg.program "c:\Program Files (x86)\GnuPG\bin\gpg.exe"
    git config --global user.email "mgoodness@gmail.com"
    git config --global user.name "Michael Goodness"
    git config --global user.signingkey 4A31C228815AA553
    git config --global commit.gpgsign true
    ```
    
    {{- if (eq .chezmoi.os "linux") -}}
{{- if (.chezmoi.kernel.osrelease | lower | contains "microsoft") -}}
#!/usr/bin/env bash
{{- if (eq .chezmoi.osRelease.id "ubuntu") }}

sudo apt update
sudo apt install -y socat wget
{{- end }}

mkdir -p ~/.ssh
curl -s https://api.github.com/repos/BlackReloaded/wsl2-ssh-pageant/releases/latest \
  | jq -r '.assets[].browser_download_url' \
  | wget -qO ~/.ssh/wsl2-ssh-pageant.exe -
chmod +x ~/.ssh/wsl2-ssh-pageant.exe
{{- end }}
{{- end }}
