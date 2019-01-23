### Linux commands ###
# always list hidden files
alias ls="ls -A --color"

# make and change directory
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

### Windows services ###
alias node="node.exe"
alias mongo="mongo.exe"
alias mongodump="mongodump.exe"
alias mongorestore="mongorestore.exe"
alias redis-cli="redis-cli.exe"

### Docker & Docker Compose commands ###
alias d="docker"
alias dcp="docker-compose"

# docker image
alias di="docker image"
alias dils="docker image ls -a"

# docker container
alias dc="docker container"
alias dcls="docker container ls -a"

# docker-compose
alias up="docker-compose up"
alias down="docker-compose down"
