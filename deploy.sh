#!/bin/bash

set -e

RED='\033[0;31m'
NC='\033[0m'
Blue='\033[0;34m'
Green='\033[0;32m'
ERROR="Not supported on current system."

abort() {
  printf "${RED}%s${NC}\n" "$@"
  exit 1
}

DEFAULT_STABLE_VERSION="3.1.0"
INSTALL_TYPE="dnf"
# Tested on Ubuntu 20.04/22.04.2 LTS/23.04
UBUNTU_VERSION="20.04"
# Keys reference to https://rvm.io/rvm/security#install-our-keys
RVM_KEYS="--recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB"

change_keys() {
  GPG="gpg --keyserver hkp://keyserver.ubuntu.com $RVM_KEYS"
}

compare_version() {
  perl -e "{if($1>=$2){print 1} else {print 0}}"
}

check_sys() {
  OS="$(uname)"
  if ! [[ "${OS}" = "Linux" ]]; then
    abort "$ERROR"
  fi
  if ! [[ $UID == 0 ]]; then
      abort "Try to use root to do the following actions."
  fi
  source '/etc/os-release'
  if [[ "${ID}" = "centos" && "${VERSION_ID}" == 8 ]]; then
    GPG2="gpg2 --keyserver keys.openpgp.org $RVM_KEYS"
    INSTALL_TYPE="yum"
  elif [[ "${ID}" = "centos" && "${VERSION_ID}" == 7 ]]; then
    change_keys
    INSTALL_TYPE="yum"
  elif [[ "${ID}" = "ubuntu" ]] && [[ "$(compare_version "${VERSION_ID}" $UBUNTU_VERSION)" == 1 ]]; then
    INSTALL_TYPE="apt"
    change_keys
  else
    abort "$ERROR"
  fi
}

# Private repository, username and password required
pull_git() {
  read -rp "Would like to keep the Git repository up to date (y/n)? " update
  case "$update" in
  y | Y)
    git pull
    ;;
  *)
    echo "User canceled Git update, continuing."
    ;;
  esac
}

check_dir() {
  if ! [[ -e "Gemfile" ]]; then
    abort "Please place it in the Jekyll skeleton."
  fi
  # Always refresh the gems
  # rm -rf 'Gemfile.lock'
  pull_git
}

check_rvm_env() {
  check_dir
  check_sys

  if ! [[ -f "/usr/local/rvm/bin/rvm" ]]; then
    if [[ "$INSTALL_TYPE" = "yum" || "$INSTALL_TYPE" = "apt" ]]; then
      $GPG
    else
      $GPG2
    fi
    curl -sSL https://get.rvm.io | bash -s stable
  fi
  source '/etc/profile.d/rvm.sh'

  if ! [[ -f "/usr/local/rvm/rubies/ruby-$DEFAULT_STABLE_VERSION/bin/ruby" ]]; then
    echo -e "${Green}Starting install Ruby ${DEFAULT_STABLE_VERSION}...${NC}"
    rvm install $DEFAULT_STABLE_VERSION
  fi

  rvm use $DEFAULT_STABLE_VERSION
  echo -e "${Green}Using Ruby ${DEFAULT_STABLE_VERSION} override current environment.${NC}"

  # Compatible with Ruby 3.1.0
  gem update --system 3.5.22 || true

  # Compatible with Ruby 3.1.0
  gem install bundler -v "~> 2.4" --no-document || true
  gem install jekyll  -v "~> 4.4" --no-document || true

}

reload_bundle() {
  bundle config set --local path vendor/bundle
  # Keep the stable dependencies in the skeleton
  if [[ -f "Gemfile.lock" ]]; then
    bundle config set --local deployment true
    bundle install
  else
    echo -e "${Blue}First time compiling the Gems.${NC}"
    bundle install
  fi
}

build_posted() {
  if [[ $INSTALL_TYPE = "apt" ]]; then
    rm -rf /var/www/html/*
    mv "_site"/* "/var/www/html/"
    elif [[ $INSTALL_TYPE = "yum" ]] || [[ $INSTALL_TYPE = "dnf" ]]; then
      rm -rf /usr/share/nginx/html/*
      mv "_site"/* "/usr/share/nginx/html/"
         if [[ $INSTALL_TYPE = 'dnf' ]]; then
              chcon -Rt httpd_sys_content_t "/usr/share/nginx/html/"
         fi
  else
    abort "$ERROR"
  fi
  sudo systemctl start nginx
}

# curl -4/-6
preview_url() {
  # Internal IP
  # ipv4=$(ip route get 1 | sed 's/^.*src \([^ ]*\).*$/\1/;q')
  external_ipv4=$(curl -4 -s icanhazip.com || true)
  preview="http://"$external_ipv4
}

check_nginx() {
  if [[ -f "/usr/sbin/nginx" ]]; then
    echo -e "${Green}Nginx is detected as installed, skip it.${NC}"
  else
    if [[ "${ID}" = "centos" && "${VERSION_ID}" == 7 ]]; then
      echo -e "${Green}Updating EPEL package due to detected is centos 7...${NC}"
      sudo $INSTALL_TYPE install epel-release
    fi
    echo -e "${Green}Starting install Nginx...${NC}"
    if [[ $INSTALL_TYPE = "apt" ]] || [[ $INSTALL_TYPE = "yum" ]]; then
        sudo $INSTALL_TYPE install nginx
        sudo $INSTALL_TYPE install firewalld
        sudo systemctl enable firewalld
        sudo systemctl start firewalld
    else
        sudo $INSTALL_TYPE install nginx
    fi
    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --permanent --add-service=https
    sudo firewall-cmd --reload
    sudo systemctl enable nginx
  fi
  build_posted
}

build_pre() {
  echo -e "${Green}Starting build Jekyll...${NC}"
  rm -rf _site/
  reload_bundle
  bundle exec jekyll build --source "$HOME"/"${PWD##*/}"
  if pgrep -x "nginx" >/dev/null; then
    sudo pkill -9 nginx
  fi
}

build_jekyll() {
  echo -e "${Green}Checking for Jekyll related dependencies.${NC}"
  check_rvm_env
  build_pre
  check_nginx
  preview_url
  echo -e "${Green}==> Jekyll blog has been successfully deployed.${NC}"
  echo -e "${Blue}==> Preview URL (ipv4): ${NC}\e[4m$preview\e[0m"
}

build_jekyll
