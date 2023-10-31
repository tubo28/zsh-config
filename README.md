# zsh-config

## Dependency

* Zsh
* [Antigen](https://github.com/zsh-users/antigen)
* [Starship](https://starship.rs/)

## Setup

```sh
cd ~

curl -sS https://starship.rs/install.sh | sh
curl -L git.io/antigen > ~/.antigen.zsh
starship preset plain-text-symbols -o ~/.config/starship.toml

ghq get git@github.com/tubo28/zsh-config.git
mv .zsh .zsh.bk
ln -s ~/ghq/github.com/tubo28/zsh-config .zsh

mv .zshrc .zshrc.bk
echo 'source ~/.zsh/main.zsh' > .zshrc
```

遅いプロンプトは無効化する

```toml
[scala]
disabled = true
```
