uv := require("uv")

alias b := build
alias r := run
alias i := install
alias f := fmt
alias m := main

default:
    @just --list

# install the uv package manager
[linux]
[macos]
deps:
    curl -LsSf https://astral.sh/uv/install.sh | sh

# install the uv package manager
[windows]
deps:
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

# Install all dependencies
install:
    uv sync

build:
    uv build

run:
    uv run

main:
    uv run main.py

fmt:
    uv tool run ruff check --fix
    uv tool run ruff format

publish:
    uv publish





