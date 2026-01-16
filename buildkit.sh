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

PROJECT_DIR="$(pwd)"

# Fixed Ruby version
DEFAULT_RUBY_VERSION="3.1.0"
# sha256sum ruby-3.1.0.tar.gz
RUBY_TGZ_SHA256="50a0504c6edcb4d61ce6b8cfdbddaa95707195fab0ecd7b5e92654b2a9412854"
# Only for compiler
COMPILE_ROOT="/opt/jekyll-runtime"
RUBY_PREFIX="${COMPILE_ROOT}/ruby-${DEFAULT_RUBY_VERSION}"
RUBY_BIN="${RUBY_PREFIX}/bin/ruby"
# GEM_BIN="${RUBY_PREFIX}/bin/gem"
# BUNDLE_BIN="${RUBY_PREFIX}/bin/bundle"
# JEKYLL_BIN="${RUBY_PREFIX}/bin/jekyll"

# Ruby tar
RUBY_TAR="3.1"
RUBY_TGZ="ruby-${DEFAULT_RUBY_VERSION}.tar.gz"
RUBY_URL="https://cache.ruby-lang.org/pub/ruby/${RUBY_TAR}/${RUBY_TGZ}"

# The dependency of versions for Ruby 3.1.0
RUBYGEMS_VERSION="3.5.22"
BUNDLER_VERSION="2.6.9"
JEKYLL_VERSION="4.4.1"

# Tested on Ubuntu 20.04/22.04.2/23.04 LTS
UBUNTU_VERSION="20.04"

compare_version() {
  perl -e "{if($1>=$2){print 1} else {print 0}}"
}

# Remove RVM on compiled machine
reset_env_on_compiled() {
  # Clean Ruby/RVM/Bundler
  unset GEM_HOME GEM_PATH MY_RUBY_HOME IRBRC RUBYOPT RUBYLIB
  unset rvm_path rvm_prefix rvm_bin_path rvm_version rvm_user_install_flag

  unset BUNDLE_PATH BUNDLE_BIN BUNDLE_GEMFILE
  unset BUNDLE_WITH BUNDLE_WITHOUT BUNDLE_DEPLOYMENT BUNDLE_FROZEN

  export PATH="${RUBY_PREFIX}/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  hash -r
}

# Invoke Ruby to find gem/bundle/jekyll
ruby_gem() {
  "${RUBY_BIN}" -S gem "$@"
}

ruby_bundle() {
  "${RUBY_BIN}" -S bundle "$@"
}

ruby_jekyll() {
  "${RUBY_BIN}" -S jekyll "$@"
}

check_sys() {
  local OS
  OS="$(uname)"
  if ! [[ "${OS}" = "Linux" ]]; then
    abort "$ERROR"
  fi
  if ! [[ $UID == 0 ]]; then
    abort "Try to use root to do the following actions."
  fi
  source '/etc/os-release'

  # Converge to Ubuntu
  if ! [[ "${ID}" = "ubuntu" ]]; then
    abort "Current version is focusing on Ubuntu, and other branches are deprecated."
  fi

  if ! [[ "$(compare_version "${VERSION_ID}" $UBUNTU_VERSION)" == 1 ]]; then
    abort "$ERROR Require Ubuntu >= ${UBUNTU_VERSION}."
  fi
}

# Private repository, username and password required
pull_git() {
  if ! command -v git >/dev/null 2>&1; then
    echo -e "${Green}Git is not installed yet, skip git pull.${NC}"
    return 0
  fi
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
    abort "The Jekyll skeleton has to include the Gemfile and site structure."
  fi
  # Always refresh the gems
  # rm -rf 'Gemfile.lock'
  pull_git
}

install_deps() {
  echo -e "${Green}Installing system dependencies...${NC}"
  apt-get update -y
  apt-get install -y --no-install-recommends \
    ca-certificates curl git build-essential pkg-config \
    libssl-dev libreadline-dev zlib1g-dev libyaml-dev libffi-dev \
    libgdbm-dev libncurses5-dev libncursesw5-dev libdb-dev \
    xz-utils libsqlite3-dev libcurl4-openssl-dev
}

install_fixed_ruby() {
  check_dir
  check_sys

  mkdir -p "${COMPILE_ROOT}"
  # For compiled machine
  install_deps

  if [[ -x "${RUBY_BIN}" ]]; then
    echo -e "${Green}Ruby ${DEFAULT_RUBY_VERSION} already installed at ${RUBY_PREFIX}.${NC}"
  else
    echo -e "${Green}Installing Ruby ${DEFAULT_RUBY_VERSION} as detected in the initial environment...${NC}"
    cd /tmp
    rm -rf "ruby-${DEFAULT_RUBY_VERSION}" "${RUBY_TGZ}"*
    curl -fsSLO "${RUBY_URL}"

    # Verify
    echo "${RUBY_TGZ_SHA256}  ${RUBY_TGZ}" | sha256sum -c - >/dev/null 2>&1 ||
      abort "Ruby tarball SHA256 mismatch."

    # Compiling
    tar -xzf "${RUBY_TGZ}"
    cd "ruby-${DEFAULT_RUBY_VERSION}"

    ./configure --prefix="${RUBY_PREFIX}" --disable-install-doc
    make -j"$(nproc)"
    make install

    cd /
    rm -rf "/tmp/ruby-${DEFAULT_RUBY_VERSION}" "/tmp/${RUBY_TGZ}"
  fi

  # Reset RVM on compiled machine
  reset_env_on_compiled

  echo -e "${Green}Using Ruby ${DEFAULT_RUBY_VERSION} from ${RUBY_PREFIX}.${NC}"
  # Compatible with Ruby 3.1.0
  ruby_gem update --system "${RUBYGEMS_VERSION}" || true
  ruby_gem install bundler -v "${BUNDLER_VERSION}" --no-document
  ruby_gem install jekyll -v "${JEKYLL_VERSION}" --no-document

  # Output the fixed versions
  echo -e "${Blue}===> Installed manifests:${NC}"
  cd /
  echo -n "ruby    : " && "${RUBY_BIN}" -v
  echo -n "rubygems: " && ruby_gem -v
  echo -n "bundler : " && ruby_bundle -v
  echo -n "jekyll  : " && ruby_jekyll -v
  echo -e "${Blue}===> Installed manifests end.${NC}"
  cd "${PROJECT_DIR}"
}

reload_bundle() {
  cd "${PROJECT_DIR}"
  # Clean
  reset_env_on_compiled

  # Dependencies of each skeleton
  ruby_bundle config set --local path vendor/bundle

  # Keep the stable dependencies in the skeleton
  if [[ -f "Gemfile.lock" ]]; then
    ruby_bundle config set --local deployment true
    ruby_bundle config set --local without "development test" || true
    ruby_bundle install
  else
    ruby_bundle config set --local deployment false || true
    echo -e "${Green}First time compiling the Gems.${NC}"
    ruby_bundle install
  fi
}

build_posted() {
  rm -rf /var/www/html/*
  mv "_site"/* "/var/www/html/"
}

check_firewall() {
  if command -v firewall-cmd >/dev/null 2>&1; then
    echo -e "${Green}Configuring firewall...${NC}"
    firewall-cmd --permanent --add-service=http || true
    firewall-cmd --permanent --add-service=https || true
    firewall-cmd --reload || true
  elif command -v ufw >/dev/null 2>&1; then
    echo -e "${Green}Configuring ufw...${NC}"
    ufw allow OpenSSH || true
    ufw allow 80/tcp || true
    ufw allow 443/tcp || true
    ufw --force enable || true
  else
    echo -e "${Blue}No initiated firewall tools detected (firewalld or ufw). Skipping...${NC}"
  fi
}

# curl -4/-6
preview_url() {
  # Internal IP
  local ipv4
  ipv4="$(ip route get 1 2>/dev/null | sed 's/^.*src \([^ ]*\).*$/\1/;q' || true)"

  if [[ -z "${ipv4}" ]]; then
    ipv4="$(hostname -I 2>/dev/null | awk '{print $1; exit}' || true)"
  fi
  if [[ -z "${ipv4}" ]]; then
    ipv4="$(curl -4 -s icanhazip.com 2>/dev/null || true)"
  fi
  preview="http://${ipv4}"
}

check_nginx() {
  if command -v nginx >/dev/null 2>&1; then
    echo -e "${Green}Nginx is detected as installed, skip it.${NC}"
  else
    echo -e "${Green}Starting install Nginx...${NC}"
    apt-get update -y
    apt-get install -y nginx
    systemctl enable nginx
  fi

  check_firewall
  build_posted
  systemctl reload nginx || systemctl restart nginx
}

build_pre() {
  echo -e "${Green}Starting build Jekyll...${NC}"
  rm -rf _site/
  reload_bundle
  reset_env_on_compiled

  ruby_bundle exec jekyll build --source "$PWD"
  # if pgrep -x "nginx" >/dev/null; then
  #  systemctl stop nginx || true
  # fi
}

build_jekyll() {
  echo -e "${Green}Checking for Jekyll related dependencies.${NC}"
  install_fixed_ruby
  build_pre
  check_nginx
  preview_url
  echo -e "${Green}==> Jekyll blog has been successfully deployed.${NC}"
  echo -e "${Blue}==> Preview URL (ipv4): ${NC}\e[4m$preview\e[0m"
}

build_jekyll
