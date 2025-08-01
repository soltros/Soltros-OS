export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH
export PATH="/var/home/linuxbrew/.linuxbrew/bin:$PATH"
export PATH="/var/home/linuxbrew/.linuxbrew/sbin:$PATH"
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="terminalparty"
plugins=(git
zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh
export LANG=en_US.UTF-8
alias fastfetch="fastfetch -l linux"
alias helper="sh /usr/share/soltros/bin/helper.sh"
alias nixmanager="sh ~/scripts/nixmanager.sh"

# Show welcome message only in interactive shells if reminder not disabled
if [[ $- == *i* ]] && [[ ! -f ~/.no-helper-reminder ]]; then
  echo "🌟 Welcome to SoltrOS! Type 'helper' to view all available system commands and operations."
fi

# Alias to turn off the welcome reminder
alias helper-off='touch ~/.no-helper-reminder && echo "Helper reminder turned OFF. You can delete ~/.no-helper-reminder to enable it again."'
