# always list hidden files
alias ls="ls -A --color"

# make and change to directory
mkcd(){ mkdir -p -- "$1" && cd -P -- "$1"; }

# fast change directories
alias ..="cd .."
alias ...="cd ../.."

# find files with name
alias fn="find . -name $1"

# determine file size or directory size
fs(){
  if du -b /dev/null > /dev/null 2>&1; then
    local arg=-sbh
  else
    local arg=-sh
  fi
  if [[ -n "$@" ]]; then
    du $arg -- "$@";
  else
    du $arg .[^.]* ./*;
  fi;
}

# load other aliases
if [ -f ~/.win_aliases ]; then
  . ~/.win_aliases
fi
if [ -f ~/.git_aliases ]; then
  . ~/.git_aliases
fi
if [ -f ~/.docker_aliases ]; then
 . ~/.docker_aliases
fi
