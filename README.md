# zsh-config

## Dependency

* zsh
* git
* [Zinit](https://github.com/zdharma-continuum/zinit)
* [Starship](https://starship.rs/) (optinal)

## Setup

### Super easy way

```sh
mv ~/.zshrc ~/.zshrc.bk
curl -fsS https://raw.githubusercontent.com/tubo28/zsh-config/main/.zshrc > ~/.zshrc
```

### Normal way

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
mkdir -p "$XDG_CONFIG_HOME"
git clone https://github.com/tubo28/zsh-config.git "$ZDOTDIR"
```

Install Starship (optional):

```sh
curl -sS https://starship.rs/install.sh | sh # or brew install starship
starship preset plain-text-symbols -o ~/.config/starship.toml
starship toggle scala # Disable slow prompt
```
