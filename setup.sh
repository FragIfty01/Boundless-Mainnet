#!/bin/bash
set -e  # Exit if any command fails

echo "=== Updating and upgrading system ==="
sudo apt update && sudo apt upgrade -y

echo "=== Installing dependencies ==="
sudo apt install -y curl iptables build-essential git wget lz4 jq make gcc nano \
    automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev tar clang \
    bsdmainutils ncdu unzip libleveldb-dev libclang-dev ninja-build

echo "=== Cloning Boundless repo ==="
if [ ! -d "boundless" ]; then
    git clone https://github.com/boundless-xyz/boundless
fi
cd boundless
git checkout release-0.13
cd ..

echo "=== Installing Rust (rustup) ==="
if ! command -v rustup &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
fi
rustup update

echo "=== Installing Cargo ==="
sudo apt install -y cargo
cargo --version

echo "=== Installing RISC Zero rzup ==="
curl -L https://risczero.com/install | bash
source ~/.bashrc
rzup --version

echo "=== Installing RISC Zero Rust Toolchain ==="
rzup install rust

echo "=== Installing cargo-risczero ==="
cargo install cargo-risczero || true
rzup install cargo-risczero

rustup update

echo "=== Installing Just ==="
if ! command -v just &> /dev/null; then
    cargo install just
fi
just --version

echo "=== Installing Boundless CLI tools ==="
cargo install --locked --git https://github.com/boundless-xyz/boundless bento-client \
    --branch release-1.0 --bin bento_cli

cargo install --locked --git https://github.com/boundless-xyz/boundless boundless-cli \
    --branch release-1.0 --bin boundless

echo "=== Setup completed successfully ==="
