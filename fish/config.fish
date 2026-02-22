# Base OS config
source /usr/share/cachyos-fish-config/cachyos-config.fish

# Editor
set -Ux EDITOR nvim

# NPM global path
set -Ua fish_user_paths (npm prefix -g)/bin

# Lazyman NVIM profile
set -gx NVIM_APPNAME nvim-LazyVim

# Aliases
alias c='clear'

# Zoxide
#if type -q zoxide
#    zoxide init fish | source
#    alias cd='z'
#end

# FZF
if type -q fzf
    set -Ux FZF_DEFAULT_COMMAND 'fd --type f'
    set -Ux FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
    set -Ux FZF_CTRL_T_OPTS "--preview 'bat --style=numbers --color=always {} | head -500'"
end

# direnv
if type -q direnv
    direnv hook fish | source
end

# History size (Fish handles history smartly but you can still tune it)
set -g fish_history_limit 50000

# Nice Ctrl+D
function fish_exit
    echo "Goodbye, Professor."
end

# eza aliases
alias ls="eza --icons --git"
alias ll="eza -l --icons --git"
alias la="eza -la --icons --git"
alias lt="eza --tree --level=2 --icons"

# Git aliases
alias g="git"
alias gst="git status"
alias gd="git diff"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gco="git checkout"
alias gb="git branch"

# Terraform
alias tp="terraform plan"
alias ti="terraform init"
alias ta="terraform apply"
alias taa="terraform apply --auto-approve"

source "$HOME/.cargo/env.fish"

# Misc
alias pbc="wl-copy"

# Directory navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# TRISMEGISTUS III
alias tris="cd ~/.local/share/trismegistus && claude"

# opencode
fish_add_path /home/snek/.opencode/bin
set -gx BROWSER chromium

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# OpenClaw Completion (generated at ~/.config/fish/completions/openclaw.fish)

# VPN shortcuts
alias vpn-up='sudo systemctl start openvpn-client@client_config_file'
alias vpn-down='sudo systemctl stop openvpn-client@client_config_file'
alias vpn-status='sudo systemctl status openvpn-client@client_config_file'

# Entire CLI shell completion
entire completion fish | source
