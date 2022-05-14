# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Set up the prompt

autoload -Uz promptinit
promptinit
prompt adam1

setopt histignorealldups sharehistory

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history

# Use modern completion system
autoload -Uz compinit
compinit

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# ---------------
# Custom settings
# ---------------

source ~/.zsh-theme-and-plugins/powerlevel10k/powerlevel10k.zsh-theme
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.zsh-theme-and-plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Shortcuts to move between words.
# https://stackoverflow.com/questions/12382499/looking-for-altleftarrowkey-solution-in-zsh
bindkey "^[[1;3C" forward-word # Alt + ->(right arrow)
bindkey "^[[1;3D" backward-word # Alt + <-(left arrow)

export PATH="$PATH:$HOME/bin:$HOME/.local/bin"

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox}'
    alias fgrep='fgrep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox}'
    alias egrep='egrep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox}'

    alias diff='diff --color=auto'
fi

alias ll='ls -lFh'
alias gdb='gdb --quiet'
alias ipy='ipython -i -c "from pwn import *"'
# alias ld223='~/work/glibc-versions/2.23/x64_notcache/lib/ld-2.23.so'
# alias ld227='~/work/glibc-versions/2.27/x64_tcache/lib/ld-2.27.so'

# Really clear the tmux panel
# https://stackoverflow.com/questions/10543684/how-can-i-clear-scrollback-buffer-in-tmux
if [[ $TMUX ]]; then
    alias clear='clear && tmux clear-history'
fi

# Proxy setting function
setproxy() {
    export http_proxy="http://172.17.0.1:8080"
    export https_proxy="$http_proxy"
    echo "Proxy is set to $http_proxy."
}
unsetproxy() {
    unset http_proxy
    unset https_proxy
    echo "Proxy is unset."
}

# Uncomment to enable proxy by default
# setproxy > /dev/null

# if [ -x "$(command -v tmux)" ] && [ -z "${TMUX}" ]; then
#     { exec tmux new -As main; } >/dev/null 2>&1
# fi