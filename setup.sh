#!/usr/bin/env bash
set -euo pipefail

echo "=== Update & deps ==="
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y curl iptables build-essential git wget lz4 jq make gcc nano \
  automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev tar clang \
  bsdmainutils ncdu unzip libleveldb-dev libclang-dev ninja-build apt-transport-https \
  ca-certificates software-properties-common gnupg lsb-release

echo "=== Install Docker ==="
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update -y
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  sudo systemctl enable docker
  sudo systemctl start docker
fi
docker --version

echo "=== Clone Boundless ==="
if [ ! -d "boundless" ]; then
  git clone https://github.com/boundless-xyz/boundless
fi
cd boundless
git checkout release-0.13 || true

echo "=== Rust toolchain (rustup) ==="
if ! command -v rustup >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  # make rustup available in this session
  if [ -f "$HOME/.cargo/env" ]; then
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
  fi
fi
rustup update || true

echo "=== Ensure cargo available ==="
sudo apt install -y cargo || true
cargo --version || true

echo "=== Install RISC Zero (rzup) ==="
curl -L https://risczero.com/install | bash || true

# Source common shell startup files (best-effort)
for rc in "$HOME/.bashrc" "$HOME/.profile" "$HOME/.bash_profile" "/etc/profile"; do
  if [ -f "$rc" ]; then
    # shellcheck source=/dev/null
    source "$rc" || true
  fi
done

# Ensure PATH includes likely rzup/cargo locations for rest of this script
for d in "$HOME/.rzup/bin" "$HOME/.local/bin" "$HOME/.cargo/bin" "/usr/local/bin" "/usr/bin"; do
  if [ -x "$d/rzup" ] || [ -f "$d/rzup" ]; then
    export PATH="$d:$PATH"
    break
  fi
done

# As a fallback search under $HOME
if ! command -v rzup >/dev/null 2>&1; then
  found=$(find "$HOME" -maxdepth 4 -type f -name rzup -perm /111 2>/dev/null | head -n1 || true)
  if [ -n "$found" ]; then
    dir=$(dirname "$found")
    export PATH="$dir:$PATH"
    echo "Found rzup at $found; added $dir to PATH"
  fi
fi

if ! command -v rzup >/dev/null 2>&1; then
  echo "ERROR: rzup not found in PATH after installer. Please restart your shell or run: source \"$HOME/.bashrc\""
  exit 1
fi

rzup --version || rzup --help

echo "=== Install RISC Zero cargo helpers ==="
rzup install rust || true
cargo install cargo-risczero -y || true
rzup install cargo-risczero || true

echo "=== Install just ==="
if ! command -v just >/dev/null 2>&1; then
  cargo install just || true
fi
just --version || true

echo "=== Install Boundless CLI(s) ==="
cargo install --locked --git https://github.com/boundless-xyz/boundless bento-client --branch release-1.0 --bin bento_cli || true
cargo install --locked --git https://github.com/boundless-xyz/boundless boundless-cli --branch release-1.0 --bin boundless || true

echo "=== Done ==="
