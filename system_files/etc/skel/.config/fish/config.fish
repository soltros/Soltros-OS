# No greeting
set -g fish_greeting ""

# Prompt Configuration
function fish_prompt
    set_color white; echo -n (whoami)
    set_color normal; echo -n ':'
    set_color cyan; echo -n (pwd)
    set_color normal; echo -n ' '
end

# Aliases
alias helper="sh /usr/share/soltros/bin/helper.sh"
