## LANG
export LANG="en_US.UTF-8"

# ディレクトリが存在するかつまだ追加されていない場合のみPATHに追加
zsh_add_path() {
    if [[ -d $1 ]] && [[ ! $PATH =~ (^|:)$1(:|$) ]]; then
        export PATH="$1:$PATH"
    fi
}

command_exists() { command -v "$1" > /dev/null 2>&1; }

## History
HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt share_history
## 直前と同じコマンドをヒストリに追加しない
setopt hist_ignore_dups
## ヒストリに追加されるコマンド行が古いものと同じなら古いものを削除
setopt hist_ignore_all_dups
## 余分な空白は詰めて記録
setopt hist_reduce_blanks
## zshプロセス終了時ではなく毎コマンド終了時に書き込む
setopt appendhistory
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

## Misc of zsh
## cd 時に自動で push
setopt auto_pushd
## 同じディレクトリを pushd しない
setopt pushd_ignore_dups

## Ctrl+S/Ctrl+Q によるフロー制御を使わないようにする
setopt NO_flow_control
## コマンドラインでも # 以降をコメントと見なす
setopt interactive_comments
## ファイル名の展開でディレクトリにマッチした場合末尾に / を付加する
setopt mark_dirs
## 最後のスラッシュを自動的に削除しない
setopt noautoremoveslash

## Emacsライクキーバインド設定
bindkey -e

# 色有効
autoload -U colors
colors

## 色を使う
setopt prompt_subst

## 補完機能の有効
autoload -Uz compinit
compinit
## TAB で順に補完候補を切り替える
setopt auto_menu
## サスペンド中のプロセスと同じコマンド名を実行した場合はリジューム
setopt auto_resume
## 補完候補を一覧表示
setopt auto_list
## カッコの対応などを自動的に補完
setopt auto_param_keys
## ディレクトリ名の補完で末尾の / を自動的に付加し、次の補完に備える
setopt auto_param_slash
## 補完候補のカーソル選択を有効に
zstyle ':completion:*:default' menu select=1
## 補完候補の色づけ
if command_exists dircolors; then
    eval `dircolors`
    export ZLS_COLORS=$LS_COLORS
elif command_exists gdircolors; then
    eval `gdircolors`
    export ZLS_COLORS=$LS_COLORS
fi

zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
## 補完候補一覧でファイルの種別をマーク表示
setopt list_types
## 補完候補を詰めて表示
setopt list_packed
# 可能な限り曖昧に多くの候補を列挙
zstyle ':completion:*' completer _expand _complete _match _prefix _approximate _list

## fzf
fzf-select-history() {
    BUFFER=$(history -n -r 1 | fzf --query "$LBUFFER")
    CURSOR=$#BUFFER
    zle reset-prompt
}
zle -N fzf-select-history
bindkey '^r' fzf-select-history

fzf-ghq() {
  local target_dir=$(ghq list -p | fzf --query="$LBUFFER")

  if [ -n "$target_dir" ]; then
    BUFFER="cd ${target_dir}"
    zle accept-line
  fi

  zle reset-prompt
}
zle -N fzf-ghq
bindkey "^g" fzf-ghq

# https://zenn.dev/yamo/articles/5c90852c9c64ab
function select-git-switch() {
  target_br=$(
    git branch -a --sort=-committerdate |
      fzf --preview-window="right,65%" --preview="echo {} | tr -d ' *' | xargs git log --color=always" |
        head -n 1 |
        perl -pe "s/\s//g; s/\*//g; s/remotes\/origin\///g"
  )
  if [ -n "$target_br" ]; then
    BUFFER="git switch $target_br"
    zle accept-line
  fi
}
zle -N select-git-switch
bindkey "^b" select-git-switch

## Alias
alias ls="ls --color=auto"
alias l="ls"
alias k="l"
alias s="l"
alias ks="l"
alias sl="l"
alias la="l -a"
alias ll="l -lh"
alias lla="l -lah"

alias cp="cp -r"
alias mv="mv -i"
alias rm="rm -ri"

alias c="cd"
alias u="cd .."

alias f='fg'
alias fgfg='f'

alias g="git"
alias t="tig"

alias d="docker"

# Always no-window mode on WSL
[[ -f /proc/version ]] && grep -qi microsoft /proc/version && alias emacs='emacs -nw'

## Util functions
# ghq get and cd
ggcd() {
    echo "ghq get $@"
    local tmp=$(mktemp)
    ghq get $@ 2>&1 | tee $tmp
    # sed for remove color
    local dir=$(cat $tmp | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | perl -ne 'for (split) { print $_ and exit, last if -d $_ }')
    rm -f $tmp
    cd $dir || return 2
}

# generate random string
if [[ -f "$ZDOTDIR/randstr.pl" ]]; then
    randstr() {
        result=$(perl "$ZDOTDIR/randstr.pl" "$@")
        if [[ ! -z "$result" ]]; then
            echo $result
            echo $result >> "$HOME/.randstr"
        fi
    }
fi

# uniq but keep order
uniq2() { perl -ne 'print if !$u{$_}++' }

## PATH

# Homebrew
# homebrew によってインストールしたもの
if [[ -f "/usr/local/bin/brew" ]]; then
    BREW_BIN="/usr/local/bin/brew"
elif [[ -f "/opt/homebrew/bin/brew" ]]; then # M1 Mac or later
    BREW_BIN="/opt/homebrew/bin/brew"
    # https://zenn.dev/tet0h/articles/a92651d52bd82460aefb
    if [[ -o interactive ]]; then
        # Commands to run in interactive sessions can go here
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

if command_exists $BREW_BIN; then
    BREW_PREFIX=$($BREW_BIN --prefix)
    for bindir in $BREW_PREFIX/opt/*/libexec/gnubin; do
        zsh_add_path "$bindir"
    done
    # GNU のコマンドが存在する場合に優先的に使う
    for bindir in $BREW_PREFIX/opt/*/bin; do
        zsh_add_path "$bindir"
    done
    for mandir in $BREW_PREFIX/opt/*/libexec/gnuman; do
        export MANPATH="$mandir:$MANPATH"
    done
    for mandir in $BREW_PREFIX/opt/*/share/man/man1; do
        export MANPATH="$mandir:$MANPATH"
    done
fi

zsh_add_path "/Applications/IntelliJ IDEA.app/Contents/MacOS"
zsh_add_path "/snap/bin"
zsh_add_path "/usr/local/opt/ruby/bin"

# Ruby
command_exists ruby && command_exists gem && zsh_add_path "$(ruby -e 'puts Gem.bindir')"

# Perl
zsh_add_path "$HOME/.plenv/bin"
command_exists plenv && eval "$(plenv init -)"

# Go
command_exists go || zsh_add_path "/usr/local/go/bin"
command_exists go || zsh_add_path "/usr/local/opt/go/bin"
# Bins installed by `go install`
command_exists go && zsh_add_path "$(go env GOPATH)/bin"

# Rust
zsh_add_path "$HOME/.cargo/bin"

# Zig
zsh_add_path "/usr/local/zig"

# My bin
if [[ -d ~/.local/bin ]]; then
    zsh_add_path "$HOME/.local/bin"
    export LD_LIBRARY_PATH="$HOME/.local/lib:$HOME/.local/lib64:$LD_LIBRARY_PATH"
fi

# Private file
[[ -f ~/.private ]] && source ~/.private

# Editor
command_exists nano && export EDITOR=nano

# fzf
export FZF_DEFAULT_COMMAND="find -type d -name .git -prune -o -print"
export FZF_DEFAULT_OPTS="--exact --multi --cycle --reverse --history=$HOME/.fzf_history --bind=ctrl-p:up,ctrl-n:down,ctrl-j:accept,ctrl-k:kill-line --no-sort --no-mouse"

# gcloud
if command_exists brew && [[ -d "$(brew --prefix)/share/google-cloud-sdk/" ]]; then
    source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc" # This may need to be adjusted if the gcloud init script isn't directly translatable to zsh.
    source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
fi

# Sdkman
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Scala
zsh_add_path "$HOME/Library/Application Support/Coursier/bin"

# kubectl
command_exists kubectl && source <(kubectl completion zsh)

## Starship
if command_exists starship; then
    eval "$(starship init zsh)"
else
    # Starship is not installed https://github.com/starship/starship"
    # Fallback to simple PROMPT
    # https://dev.to/cassidoo/customizing-my-zsh-prompt-3417
    autoload -Uz vcs_info
    precmd() { vcs_info }
    zstyle ':vcs_info:git:*' formats '%b '
    setopt PROMPT_SUBST
    PROMPT='%F{green}%*%f %F{cyan}%~%f %F{red}${vcs_info_msg_0_}%f$ '
fi

# Install zinit
if command_exists git; then
    # https://github.com/zdharma-continuum/zinit#manual
    ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
    [ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
    [ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
    source "${ZINIT_HOME}/zinit.zsh"

    autoload -Uz _zinit
    (( ${+_comps} )) && _comps[zinit]=_zinit

    # Install plugins
    zinit load z-shell/F-Sy-H
    zinit load zsh-users/zsh-autosuggestions
    zinit load zsh-users/zsh-completions
    zinit load agkozak/zsh-z
    zinit snippet https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker
else
    echo "failed to initialize zinit; git is not installed" 2>&1
fi
