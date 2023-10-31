# zsh-config

## Setup

```sh
cd ~
curl -sS https://starship.rs/install.sh | sh
curl -L git.io/antigen > ~/.antigen.zsh
starship preset plain-text-symbols -o ~/.config/starship.toml # Disable scala manually for performance issue.
```

```sh
ghq get git@github.com/tubo28/zsh-config.git
cd ~
ln -s ~/ghq/github.com/tubo28/zsh-config .zsh
```
