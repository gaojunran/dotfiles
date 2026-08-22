# omo slim
bunx oh-my-opencode-slim@latest install

# opencode
pkill -f opencode
mise use -fg opencode@latest

# magic-context
# curl -fsSL https://raw.githubusercontent.com/cortexkit/magic-context/master/scripts/install.sh | bash

# openchamber
curl -fsSL https://raw.githubusercontent.com/openchamber/openchamber/main/scripts/install.sh | bash
openchamber restart
