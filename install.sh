#!/usr/bin/env bash
set -e

# Goal: Script which automatically sets up a new Debian Machine after installation

# Test to see if user is running with root privileges.
# if [[ "${UID}" -ne 0 ]]
# then
#  echo 'Must execute with sudo or root' >&2
#  exit 1
# fi

# Ensure system is up to date
echo 'Atualizando lista de pacotes...'
sudo apt-get -y update --fix-missing 

# Upgrade the system
sudo apt-get -y upgrade

# Install packages
echo 'Instalando pacotes...'
sudo apt-get install -f -y openssh-server unattended-upgrades ufw fail2ban apt-transport-https git git-lfs zsh tmux neofetch traceroute speedtest-cli fonts-firacode ffmpeg libavcodec-extra 

# Enable Firewall
echo 'Habilitando porta 22...'
sudo ufw allow 22
echo 'Habilitando firewall...'
sudo ufw --force enable 

# configure the firewall
sudo ufw allow OpenSSH

# Disabling root login 
sudo echo "PermitRootLogin no" >> sudo /etc/ssh/sshd_config 
sudo echo "PermitEmptyPasswords no" sudo /etc/ssh/sshd_config

# Automatic downloads of security updates (package: unattended-upgrades)
sudo echo "Unattended-Upgrade::Allowed-Origins {
#   "${distro_id}:${distro_codename}-security";
#//  "${distro_id}:${distro_codename}-updates";
#//  "${distro_id}:${distro_codename}-proposed";
#//  "${distro_id}:${distro_codename}-backports";
#Unattended-Upgrade::Automatic-Reboot "true"; 
#}; " >> sudo /etc/apt/apt.conf.d/50unattended-upgrades

# Fail2Ban install (package: fail2ban)
echo 'Configurando fail2Ban...'
sudo systemctl start fail2ban
sudo systemctl enable fail2ban

sudo echo "
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 4
" >> sudo /etc/fail2ban/jail.local

# Git
echo 'Instalando git-lfs...'
sudo git-lfs install

# ZShell install
 echo 'Instalando zsh...'
# chsh -s $(which zsh)
grep zsh /etc/shells

# Oh-My-Zsh install
echo 'Instalando e configurando oh-my-zsh...'
echo 'y' | sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
zsh 

# Spaceship theme install
sudo git clone https://github.com/denysdovhan/spaceship-prompt.git "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt" --depth=1
sudo ln -s "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/spaceship.zsh-theme" 

# Fast-syntax-highlight
git clone https://github.com/zdharma/fast-syntax-highlighting.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
  
# Auto-suggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# zsh-better-npm-completion
git clone https://github.com/lukechilds/zsh-better-npm-completion ~/.oh-my-zsh/custom/plugins/zsh-better-npm-completion

# Zsh-completions
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions

# Create .zshrc
sudo rm $HOME/.zshrc
curl https://gist.githubusercontent.com/CrisMorgantee/23d22693037449cb4d9c0baff6b02b9f/raw/fd0c5ddc0ffdb0f4d76507c8dda6be012f09a8c7/.zshrc > $HOME/.zshrc
source ~/.zshrc

# Vim configs
echo 'Configurando vim...'
# Create .vimrc
echo "Criando pasta ~/.vim/plugin/"
mkdir -p ~/.vim/plugin/

echo "Criando pasta ~/.vim/autoload/"
mkdir -p  ~/.vim/autoload/

echo "Criando arquivo ~/.vimrc"
curl https://gist.githubusercontent.com/CrisMorgantee/1feac714c7dde1ca85f23940e3f8adf2/raw/ce1cf910398d7fdecd9a7ed3e1a8ff21d0e98b48/.vimrc > $HOME/.vimrc

# Dracula
mkdir -p ~/.vim/pack/themes/opt
cd ~/.vim/pack/themes/opt
git clone https://github.com/dracula/vim.git dracula

# Emmet
git clone https://github.com/mattn/emmet-vim.git
cd emmet-vim/
cp plugin/emmet.vim ~/.vim/plugin/
cp autoload/emmet.vim ~/.vim/autoload/
cp -a autoload/emmet ~/.vim/autoload/

# Auto Pairs
git clone https://github.com/jiangmiao/auto-pairs.git
cd auto-pairs/
cp plugin/auto-pairs.vim ~/.vim/plugin/

# Close Tag
git clone https://github.com/alvan/vim-closetag.git
cd vim-closetag
cp plugin/closetag.vim ~/.vim/plugin/

#NERDTree
git clone https://github.com/preservim/nerdtree.git ~/.vim/pack/vendor/start/nerdtree
#vim -u NONE -c "helptags ~/.vim/pack/vendor/start/nerdtree/doc" -c q

# NVM/Node install
echo 'Instalando node via nvm...'
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | zsh
source ~/.zshrc
nvm install --lts

# Yarn install
echo 'Instalando yarn...'
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install --no-install-recommends yarn

# SFTP Server / FTP server that runs over ssh
echo 'Configurando SFTP Server...'
sudo echo "
Match group sftp
ChrootDirectory /home
X11Forwarding no
AllowTcpForwarding no
ForceCommand internal-sftp
" >> sudo /etc/ssh/sshd_config

sudo service ssh restart

# Cleanup
echo 'Removendo pacotes não utilizados...'
sudo apt-get autoremove
sudo apt-get clean 

exit 0
