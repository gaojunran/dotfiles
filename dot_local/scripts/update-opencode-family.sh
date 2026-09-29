# omo slim
bunx oh-my-opencode-slim@latest install

# opencode v2（mise npm backend，registry 尚未跟进 v2 的 GitHub releases）
pkill -f opencode
mise use -fg npm:@opencode/cli@latest
# 注意：mise 的 npm 后端走 aube，新注册的 npm 包会要求人工确认
# （如 "is newly registered, continue adding?"）。脚本内无法交互时安装会失败，
# 此时手动执行 mise use -g npm:@opencode/cli@latest 并确认即可。
# 另一个坑：aube 会禁用 install script，平台二进制靠 postinstall 落盘；
# 若安装后 opencode --version 不对，手动补跑：
#   node "$(ls -d ~/.cache/aube/virtual-store/@opencode+cli@*/node_modules/@opencode/cli | tail -1)/postinstall.mjs"

# magic-context
# curl -fsSL https://raw.githubusercontent.com/cortexkit/magic-context/master/scripts/install.sh | bash

# openchamber
curl -fsSL https://raw.githubusercontent.com/openchamber/openchamber/main/scripts/install.sh | bash
openchamber restart
