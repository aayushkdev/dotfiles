if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Created by `pipx` on 2025-07-27 21:02:19
set PATH $PATH /home/aayush/.local/bin

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
