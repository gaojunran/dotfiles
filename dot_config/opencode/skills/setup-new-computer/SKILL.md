---
name: setup-new-computer
description: 用户要求配置一个新的主机或云主机环境时使用。
---

## 基本原则

1. 我使用 fish。但 Agent 偏好使用 bash，所以 shell hook 需要在两边同时配置。
2. 所有开发工具都用 mise 配置，例如 chezmoi, eza, zoxide 等。版本敏感的开发工具，如 node，需要在全局 pin 一个 LTS 版本；项目需要特定版本时再在项目里 pin 项目特定版本。
3. 我使用 chezmoi 来同步配置。后续非本机特定的配置都要同步到 chezmoi 仓库并推送。
4. 我不用 Windows PowerShell。 配置 Windows 的第一步就是装 WSL。
