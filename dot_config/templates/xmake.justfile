xmake := require("xmake")

# install xmake
[linux]
[macos]
deps:
    curl -fsSL https://xmake.io/shget.text | bash

# install xmake
[windows]
deps:
    Invoke-Expression (Invoke-Webrequest 'https://xmake.io/psget.text' -UseBasicParsing).Content


default:
    @just --list

build:
    xmake build

run:
    xmake run

clean:
    xmake clean



