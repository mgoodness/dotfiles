# Ref: https://github.com/marlonrichert/zsh-launchpad/blob/main/.config/zsh/rc.d/07-opts.zsh
# Ref: https://zsh.sourceforge.io/Doc/Release/Options-Index.html

##
# Shell options that don't fit in any other file.
#
# Set these after sourcing plugins, because those might set options, too.
#

# Enable the use of Ctrl-Q and Ctrl-S for keyboard shortcuts.
setopt NO_FLOW_CONTROL

  # AUTO_CD \
setopt \
  AUTO_PUSHD \
  CHASE_LINKS \
  PUSHD_IGNORE_DUPS \
  PUSHD_MINUS

setopt \
  EXTENDED_GLOB \
  GLOB_STAR_SHORT \
  NO_CASE_GLOB \
  NUMERIC_GLOB_SORT

setopt \
  C_PRECEDENCES \
  INTERACTIVE_COMMENTS \
  MARK_DIRS \
  NO_AUTO_PARAM_SLASH \
  NO_COMPLETE_ALIASES

setopt \
  NO_BEEP \
  NO_HIST_BEEP \
  NO_LIST_BEEP
