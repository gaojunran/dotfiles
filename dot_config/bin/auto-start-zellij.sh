#!/bin/bash
if [[ -z "$ZELLIJ" && $(tty) == /dev/ttys* ]]; then
  zellij attach services --force-run-commands
fi
