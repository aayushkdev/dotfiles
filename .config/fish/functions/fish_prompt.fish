function fish_prompt
    set_color green
    echo -n "┌──("
    set_color brblue
    echo -n (whoami)"@"(prompt_hostname)
    set_color green
    echo -n ")-["
    set_color --bold cyan
    echo -n (prompt_pwd)
    set_color green
    echo "]"
    echo -n "╰─"
    set_color brblue
    echo -n '$ '
    set_color normal
end
