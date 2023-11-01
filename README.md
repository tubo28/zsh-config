# zsh-config

## Dependency

* Zsh
* [Zinit](https://github.com/zdharma-continuum/zinit)
* [Starship](https://starship.rs/)

## Setup

Append this to `.zshenv`:

```zsh
# https://wiki.archlinux.org/title/XDG_Base_Directory
[[ -z $XDG_CACHE_HOME ]]  && export XDG_CACHE_HOME="${HOME}/.cache"
[[ -z $XDG_CONFIG_HOME ]] && export XDG_CONFIG_HOME="${HOME}/.config"
[[ -z $XDG_DATA_HOME ]]   && export XDG_DATA_HOME="${HOME}/.local/share"
[[ -z $XDG_STATE_HOME ]]  && export XDG_STATE_HOME="${HOME}/.local/state"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
```

Place config files:

```sh
cd "$XDG_CONFIG_HOME"
ghq get git@github.com/tubo28/zsh-config.git
mv zsh zsh.bk
ln -s ~/ghq/github.com/tubo28/zsh-config zsh
```

Install Starship:

```sh
curl -sS https://starship.rs/install.sh | sh # or brew install starship
starship preset plain-text-symbols -o ~/.config/starship.toml
```

Disable slow prompt.

```toml
[scala]
disabled = true
```
