export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"
export PATH=$PATH:$HOME/go/bin

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/scripts:$PATH"

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# eza
alias ls='eza --icons'
alias ll='eza --icons --long'
alias la='eza --icons --long --all'
alias lt='eza --icons --tree --level=2'

. "$HOME/.atuin/bin/env"
export ATUIN_NOBIND="true"
eval "$(atuin init zsh)"
bindkey '^r' atuin-search
bindkey '^[[A' up-line-or-history
bindkey '^[OA' up-line-or-history

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="/Library/TeX/texbin:$PATH"

# Machine-local overrides: work aliases, per-employer identity, anything that
# should not live in a synced repo. See .zshrc.local.example.
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
