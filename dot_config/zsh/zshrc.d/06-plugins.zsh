# Ref: https://github.com/marlonrichert/zsh-launchpad/blob/main/.config/zsh/rc.d/06-plugins.zsh

##
# Plugins
#

# Initialize zsh-vi-mode at sourcing
ZVM_INIT_MODE='sourcing'

local -a plugins=(
  Aloxaf/fzf-tab # Load before zsh-completions & fast-syntax-highlighting
  djui/alias-tips
  jeffreytse/zsh-vi-mode
  marlonrichert/zcolors
  paulirish/git-open
  zdharma-continuum/fast-syntax-highlighting
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-completions
)

local -a omz_paths=(
  lib/git \
  plugins/command-not-found \
  plugins/fzf \
  plugins/git \
  plugins/gnu-utils \
  plugins/gpg-agent \
  plugins/vscode
)

# Speed up the first startup by cloning all plugins in parallel.
# This won't clone plugins that we already have.
znap clone ohmyzsh/ohmyzsh $plugins

# Load each plugin, one at a time.
local p=
for p in $plugins; do
  znap source $p
done

for p in $omz_paths; do
  znap source ohmyzsh/ohmyzsh $p
done

# Ref: https://github.com/marlonrichert/zcolors
znap eval zcolors "zcolors ${(q)LS_COLORS}"

# In-line suggestions
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=()
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=( forward-char forward-word end-of-line )
ZSH_AUTOSUGGEST_STRATEGY=( history )
ZSH_AUTOSUGGEST_HISTORY_IGNORE=$'(*\n*|?(#c80,)|*\\#:hist:push-line:)'

# Command-line syntax highlighting
ZSH_HIGHLIGHT_HIGHLIGHTERS=( main brackets )
