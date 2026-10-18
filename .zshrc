## LANG
export LANG="en_US.UTF-8"

# Prepend dirs (globs allowed; pass them quoted) to PATH in the given order, skipping missing ones
typeset -U path
path_prepend() {
    setopt local_options no_mark_dirs
    path=(${~^@}(N-/) $path)
}

manpath_prepend() {
    setopt local_options no_mark_dirs
    local -a dirs=(${~^@}(N-/))
    # Not `typeset -U manpath`: it drops the trailing empty entry that makes man also search the system default dirs
    manpath=($dirs ${manpath:|dirs} "")
}

command_exists() { command -v "$1" > /dev/null 2>&1; }

## History
HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
## 毎コマンド終了時に書き込み、他のセッションの履歴も取り込む
## Not INC_APPEND_HISTORY: zshoptions(1) says it should be off when SHARE_HISTORY is on
setopt share_history
## ヒストリに追加されるコマンド行が古いものと同じなら古いものを削除
setopt hist_ignore_all_dups
## 余分な空白は詰めて記録
setopt hist_reduce_blanks

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
dircolors_bin=${commands[dircolors]:-$commands[gdircolors]}
if [[ -n $dircolors_bin ]]; then
    eval "$($dircolors_bin)"
    export ZLS_COLORS=$LS_COLORS
fi
unset dircolors_bin

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
  local history_file=$HOME/.ghq_history
  [[ -e $history_file ]] || touch $history_file
  local target_dir=$({ tail -n 10 $history_file | tac; ghq list -p } | uniq2 | fzf --query="$LBUFFER")
  if [[ -n $target_dir ]]; then
    local recent=$({ cat $history_file; print -r -- $target_dir } | uniq3 | tail -n 10)
    print -r -- $recent > $history_file

    BUFFER="cd ${target_dir}"
    zle accept-line
  fi

  zle reset-prompt
}
zle -N fzf-ghq
bindkey "^g" fzf-ghq

# https://zenn.dev/yamo/articles/5c90852c9c64ab
function select-git-switch() {
  # Not `git branch -a`: its decorations (*, +, "HEAD -> ...") have to be scraped off
  local target_br=$(
    git for-each-ref --sort=-committerdate --format='%(refname)' refs/heads refs/remotes |
      grep -v '^refs/remotes/[^/]*/HEAD$' |
      sed -E 's#^refs/heads/##; s#^refs/##' |
      fzf --preview-window="right,65%" --preview="git log --color=always {} --" |
      head -n 1 |
      sed -E 's#^remotes/[^/]+/##'
  )
  if [ -n "$target_br" ]; then
    BUFFER="git switch $target_br"
    zle accept-line
  fi
}
zle -N select-git-switch
bindkey "^s" select-git-switch

## Alias
alias mv="mv -i"

alias cp="cp -r"
alias l="ls"
alias la="l -a"
alias ll="l -lh"
alias lla="l -lah"
alias ls="ls --color=auto"
alias rm="rm -ri"
alias u="cd .."

alias t="tig"
alias c="claude"

# Always no-window mode on WSL
[[ -f /proc/version ]] && grep -qi microsoft /proc/version && alias emacs='emacs -nw'

## Util functions
# ghq get and cd
ggcd() {
    echo "ghq get $@"
    # ghq prints progress to stderr and the got repo paths to stdout
    local dir=$(ghq get "$@" | head -n 1)
    [[ -d $dir ]] && cd "$dir" || return 2
}

# generate random string
if [[ -f "$ZDOTDIR/randstr.pl" ]]; then
    randstr() {
        local result=$(perl "$ZDOTDIR/randstr.pl" "$@")
        if [[ ! -z "$result" ]]; then
            echo $result
            echo $result >> "$HOME/.randstr"
        fi
    }
fi

# uniq but keep order
uniq2() { perl -ne 'print if !$u{$_}++' }
# uniq2と同じだが後ろのものを保持し前のものを削除
uniq3() { perl -ne 'push @a, $_; $h{$_} = $.; END { for $i (sort { $h{$a} <=> $h{$b} } keys %h) { print $i } }' }

# URL encode and decode
urlencode() { perl -MURI::Escape -nle 'print uri_escape($_)' }
urldecode() { perl -MURI::Escape -nle 'print uri_unescape($_)' }

# Convert UNIX timestamp to ISO8601
timeat() { perl -MTime::Piece -nle 'print localtime($_)->strftime("%Y-%m-%dT%H:%M:%S%z")' }

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
    # `brew shellenv` already sets HOMEBREW_PREFIX; avoid spawning brew again (~30ms each)
    BREW_PREFIX=${HOMEBREW_PREFIX:-$($BREW_BIN --prefix)}
    # GNU のコマンドが存在する場合に優先的に使う
    path_prepend "$BREW_PREFIX/opt/*/bin" "$BREW_PREFIX/opt/*/libexec/gnubin"
    manpath_prepend "$BREW_PREFIX/opt/*/share/man/man1" "$BREW_PREFIX/opt/*/libexec/gnuman"
fi

path_prepend "/usr/local/opt/ruby/bin" "/snap/bin" "/Applications/IntelliJ IDEA.app/Contents/MacOS"

# Ruby
command_exists rbenv || path_prepend ~/.rbenv/bin
command_exists rbenv && eval "$(rbenv init - zsh)"

# Perl
command_exists plenv || path_prepend ~/.plenv/bin
command_exists plenv && eval "$(plenv init -)"

# Go
command_exists go || path_prepend /usr/local/go/bin
command_exists go || path_prepend /usr/local/opt/go/bin
# Bins installed by `go install`
command_exists go && path_prepend "$(go env GOPATH)/bin"

# Rust
if [[ -f "$HOME/.cargo/env" ]]; then
    . "$HOME/.cargo/env"
fi

# Zig
path_prepend "/usr/local/zig"

# Python
export PYENV_ROOT="$HOME/.pyenv"
command_exists pyenv || path_prepend "$PYENV_ROOT/bin"
command_exists pyenv && eval "$(pyenv init -)"

# Node
# fnm https://github.com/Schniz/fnm
for fnm_dir in /opt/homebrew/opt/fnm/bin ~/.local/share/fnm; do
    if [[ -d $fnm_dir ]]; then
        path_prepend $fnm_dir
        eval "$(fnm env)"
        break
    fi
done
unset fnm_dir

# jenv
if command_exists jenv; then
    # Not `eval "$(jenv init -)"`: it spends ~1s per shell (init ~600ms, rehash ~400ms, refresh-plugins ~150ms).
    # Shims are rehashed by `jenv add` anyway, so cache the init script and drop the per-shell maintenance commands.
    jenv_init_cache="$XDG_CACHE_HOME/zsh/jenv-init.zsh"
    if [[ ! -s $jenv_init_cache || ${commands[jenv]:A} -nt $jenv_init_cache ]]; then
        mkdir -p "${jenv_init_cache:h}"
        jenv init - --no-rehash zsh | grep -v '^jenv refresh-plugins' > "$jenv_init_cache"
    fi
    source "$jenv_init_cache"
    unset jenv_init_cache
fi

# My bin
if [[ -d ~/.local/bin ]]; then
    path_prepend "$HOME/.local/bin"
    export LD_LIBRARY_PATH="$HOME/.local/lib:$HOME/.local/lib64:$LD_LIBRARY_PATH"
fi

# Private file
if [[ -f ~/.private ]]; then
    source ~/.private
fi

# Editor
if command_exists nano; then
    export EDITOR=nano
    export GIT_EDITOR="$EDITOR"
fi

# fzf
export FZF_DEFAULT_COMMAND="find -type d -name .git -prune -o -print"
export FZF_DEFAULT_OPTS="--exact --multi --cycle --reverse --history=$HOME/.fzf_history --bind=ctrl-p:up,ctrl-n:down,ctrl-j:accept,ctrl-k:kill-line --no-sort --no-mouse"

# gcloud
if [[ -n $BREW_PREFIX && -d "$BREW_PREFIX/share/google-cloud-sdk/" ]]; then
    source "$BREW_PREFIX/share/google-cloud-sdk/path.zsh.inc"
    source "$BREW_PREFIX/share/google-cloud-sdk/completion.zsh.inc"
fi

# Scala coursier
path_prepend "$HOME/Library/Application Support/Coursier/bin" # macOS
path_prepend "$HOME/.local/share/coursier/bin" # Linux

# Sdkman (eval after coursier to prioritize sdkman)
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# kubectl
command_exists kubectl && source <(kubectl completion zsh)

# tfenv
# https://github.com/tfutils/tfenv
path_prepend "$HOME/.tfenv/bin"

# direnv
command_exists direnv && eval "$(direnv hook zsh)"

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
    echo "failed to initialize zinit; git is not installed" >&2
fi
