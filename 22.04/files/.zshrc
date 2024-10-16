# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=20000
SAVEHIST=$HISTSIZE
#setopt SHARE_HISTORY # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS # Delete old recorded entry if new entry is a duplicate.
setopt HIST_SAVE_NO_DUPS # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS # Remove superfluous blanks before recording entry.

bindkey -e
# End of lines configured by zsh-newuser-install

# The following lines were added by compinstall
zstyle :compinstall filename '/home/ctf/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

# ---------------
# Custom settings
# ---------------

# Zsh themes and plugins
source ~/.zsh-theme-and-plugins/powerlevel10k/powerlevel10k.zsh-theme
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.zsh-theme-and-plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Key bindings
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down
bindkey -M emacs '^P' history-substring-search-up
bindkey -M emacs '^N' history-substring-search-down

export PATH="$PATH:$HOME/bin:$HOME/.local/bin"

# Command colors
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

# Command alias
alias ll='ls -lFh'
alias less='less -M'
alias gdb='gdb --quiet'
alias ipy='ipython --no-confirm-exit -i -c "from pwn import *"'
alias rg='rg --no-ignore --text'
# alias ld223='~/work/glibc-versions/2.23/x64_notcache/lib/ld-2.23.so'
# alias ld227='~/work/glibc-versions/2.27/x64_tcache/lib/ld-2.27.so'

# Really clear the tmux panel
# https://stackoverflow.com/questions/10543684/how-can-i-clear-scrollback-buffer-in-tmux
if [[ $TMUX ]]; then
    alias clear='clear && tmux clear-history'
fi

# Proxy setting function
setproxy() {
    export http_proxy="http://172.17.0.1:7890"
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

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# if [ -n "${SSH_TTY}" ] && [ -x "$(command -v tmux)" ] && [ -z "${TMUX}" ]; then
#     { exec tmux new -As main; } >/dev/null 2>&1
# fi
