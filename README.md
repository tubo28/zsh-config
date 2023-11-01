# zsh-config

## Dependency

* Zsh
* [Antigen](https://github.com/zsh-users/antigen)
* [Starship](https://starship.rs/)

## Setup

```zsh
# ~/.zshenv
export XDG_CONFIG_HOME="$HOME/.config"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
```

```sh
curl -sS https://starship.rs/install.sh | sh
# or brew install starship

starship preset plain-text-symbols -o ~/.config/starship.toml

curl -L git.io/antigen > "$XDG_CONFIG_HOME/antigen.zsh"
```

```sh
cd "$XDG_CONFIG_HOME"
ghq get git@github.com/tubo28/zsh-config.git
mv zsh zsh.bk
ln -s ~/ghq/github.com/tubo28/zsh-config zsh
```

Disable slow prompt.

```toml
[scala]
disabled = true
```
