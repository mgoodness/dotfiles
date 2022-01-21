# Ref: https://github.com/marlonrichert/zsh-launchpad/blob/main/.config/zsh/rc.d/01-hist.zsh

##
# History settings
#
# Always set these first, so history is preserved, no matter what happens.
#

if [[ $VENDOR == apple ]]; then
  HISTFILE=~/Library/Mobile\ Documents/com\~apple\~CloudDocs/zsh_history
else
  HISTFILE=${XDG_DATA_HOME:=~/.local/share}/zsh/history
fi

[[ -d $HISTFILE:h ]] || mkdir -p $HISTFILE:h

# Max number of entries to keep in history file.
SAVEHIST=$(( 100 * 1000 ))

# Max number of history entries to keep in memory.
HISTSIZE=$(( 1.2 * SAVEHIST ))  # Zsh recommended value

setopt \
  HIST_FCNTL_LOCK \
  HIST_IGNORE_ALL_DUPS \
  HIST_IGNORE_SPACE \
  HIST_NO_FUNCTIONS \
  HIST_NO_STORE \
  HIST_REDUCE_BLANKS \
  HIST_SAVE_NO_DUPS \
  HIST_VERIFY \
  SHARE_HISTORY
