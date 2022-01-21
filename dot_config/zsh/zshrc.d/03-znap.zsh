# Ref: https://github.com/marlonrichert/zsh-launchpad/blob/main/.config/zsh/rc.d/03-znap.zsh

##
# Plugin manager
#

local znap=$ZDOTDIR/zsh-snap/znap.zsh

if ! [[ -r $znap ]]; then
  git -C $ZDOTDIR clone --depth 1 -- \
    https://github.com/marlonrichert/zsh-snap.git
fi

zstyle ':znap:*' repos-dir $ZDOTDIR/plugins
. $znap
