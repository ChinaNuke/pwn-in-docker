set -gx EDITOR nvim

fish_add_path ~/.local/bin

source $HOME/.venv/bin/activate.fish

abbr -a -- cp 'cp --reflink=auto'
abbr -a -- ipy 'ipython --no-confirm-exit'
abbr -a -- gdb 'gdb --quiet'
abbr -a -- less 'less -Mr'
abbr -a -- vim 'nvim'

if set -q TMUX
	function clear
		command clear
		tmux clear-history
	end
end

# set -x XZ_OPT "-T12"