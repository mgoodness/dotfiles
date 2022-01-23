##
# GnuPG
#

# Replace Linux SSH socket with link to wsl2-ssh-pageant socket
export SSH_AUTH_SOCK=~/.ssh/agent.sock
ss -a | grep -q $SSH_AUTH_SOCK
if [ $? -ne 0 ]; then
    rm -f $SSH_AUTH_SOCK
    setsid nohup \
      socat \
        UNIX-LISTEN:$SSH_AUTH_SOCK,fork \
        EXEC:~/.ssh/wsl2-ssh-pageant.exe \
      >/dev/null 2>&1 &
fi

# Replace Linux GPG socket with link to wsl2-ssh-pageant GPG socket
export GPG_AGENT_SOCK=~/.gnupg/S.gpg-agent
ss -a | grep -q $GPG_AGENT_SOCK
if [ $? -ne 0 ]; then
    rm -rf $GPG_AGENT_SOCK
    setsid nohup \
      socat \
        UNIX-LISTEN:$GPG_AGENT_SOCK,fork \
        EXEC:"~/.ssh/wsl2-ssh-pageant.exe --gpg S.gpg-agent" \
      >/dev/null 2>&1 &
fi
