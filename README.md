### nvim
This is configuration of nvim, sync this directory to ~/.config/nvim/ after neovim installed.
Post: [Transform Your Neovim into a IDE: A Step-by-Step Guide](https://martinlwx.github.io/en/config-neovim-from-scratch/)
#### prerequisition
```shell
brew install go gopls
```

#### configuration
```shell
# sync updated nvim config to this repo
rsync -r ~/.config/nvim/ ./nvim/
# sync nvim config from this repo to local
rsync -r ./nvim/ ~/.config/nvim/
```
Backup nvim
```shell
mv ~/.config/nvim{,.bak}
mv ~/.local/share/nvim{,.bak}
mv ~/.local/state/nvim{,.bak}
mv ~/.cache/nvim{,.bak}
```
Cleanup nvim
```shell
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim
```

### tf
Terraform templates.
Currenlty, `v2ray` provision ec2 instances in AWS.
