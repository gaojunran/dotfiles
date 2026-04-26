# dotfiles

我（[@gaojunran](https://github.com/gaojunran)）的个人 dotfiles，使用 [chezmoi](https://www.chezmoi.io/) 管理，跨 macOS / Windows。

> README 由 LLM 生成并维护。可能过时。建议以仓库现状为准。

## 个人偏好

### 基本原则

- 论证严密，表达简洁。不使用 emoji，不用破折号。
- 代码质量第一位：清晰、简洁、易于理解和维护。
- 不过度设计、不过度抽象；相同的简单模式重复两三次是可以接受的。
- 不编写不可能存在的异常边界；不做冗余的错误处理。
- 大胆重构现有代码以适应新需求，同时保证依赖方正常工作。
- 使用地道的、现代的语法特性。

### Shell 与命令行

- 终端模拟器使用 `ghostty`（JetBrains Mono，18pt，85% 背景不透明度，快速终端在右侧）。
- 使用 `rg` 代替 `grep`，`fd` 代替 `find`；目的明确的代码检索用 `ast-grep`。
- 使用 `bat` 代替 `cat`，`eza` 代替 `ls`，`zoxide` 代替 `cd`。
- 文件管理器使用 `yazi`，压缩/解压用 `ouch`，磁盘分析用 `dua`。
- 剪贴板统一使用 `clipboard` (`cb`) 命令。
- 系统信息使用 `fastfetch` / `onefetch`，进程查看使用 `bottom` (`btm`)。
- 终端复用使用 `zellij`。

### 编辑器与 IDE

- 日常编辑器：VSCode（`code`）。
- 轻量编辑器：Zed（主题 One Light / Vitesse Refined Black，Copilot 补全）。
- AI 编程助手：Claude Code、CodeBuddy。
- 在探索任务中倾向写 Node.js 脚本而非复杂 Shell 脚本。

### 版本管理

- 主要使用 [`jj`](https://github.com/jj-vcs/jj)（Jujutsu）管理 Git 仓库；辅助使用 `hj` 做 push/pull 与克隆。
- 不使用 `lazygit`。
- 默认分支名 `main`；`core.autocrlf = input`。

### 工具链管理

- 项目级工具版本使用 [`mise`](https://mise.jdx.dev/) 管理（Node、Go、Java、Gradle、Maven、Bun、just、watchexec 等均交给 mise）。
- 敏感环境变量（token、work 账户等）使用 [`fnox`](https://github.com/jdx/fnox) + `age` 加密管理。
- 后台守护进程使用 [`pitchfork`](https://github.com/jdx/pitchfork) 管理。
- Python 包管理使用 `uv`，索引走阿里云镜像。
- macOS 软件安装使用 Homebrew；Homebrew Cask 安装到 `~/Applications`。

### 编码风格

- 变量命名在**当前作用域内**明确且有描述性，不做冗余前缀。
- 类型优先、避免 `any`；新文件优先 TypeScript；能内联类型就不单独起别名。
- 偏爱函数式、不变优于可变：三元表达式优于 if/else 赋值，链式调用优于中间变量。
- 注释谨慎使用，需要时用简洁中文说明。
- 复杂、不确定的逻辑多打日志。
- JS/TS 偏爱 `?.` / `??` / `??=`、解构、扩展运算符、模板字符串、`Map`、`async/await`。

### 目录布局

- `~/Playground` 临时实验（`cdp`，`mc` 随机命名）。
- `~/Projects` 个人项目（`cdi`）。
- `~/Work` 工作项目（`cdw`，使用独立的 `JJ_USER` / `JJ_EMAIL`）。

## 仓库里有什么

本仓库由 chezmoi 驱动，源路径约定请参考 [chezmoi 文档](https://www.chezmoi.io/reference/source-state-attributes/)。

### Shell 与终端

- [`dot_config/fish/`](dot_config/fish/) — fish 的 `config.fish`（prompt、别名、`y` / `mc` 函数）与 `conf.d/10-source.fish`（PATH、brew、zoxide、pitchfork、fnox 的初始化）。
- [`dot_config/ghostty/`](dot_config/ghostty/) — Ghostty 终端配置。
- [`.chezmoitemplates/pwsh-profile.ps1`](.chezmoitemplates/pwsh-profile.ps1) — PowerShell profile 模板。
- [`Documents/WindowsPowerShell/`](Documents/WindowsPowerShell/) — Windows 上的 PowerShell profile 落地点。

### 版本管理与 Git

- [`dot_config/git/`](dot_config/git/) — git 的 `config` 与 `exclude`。
- [`dot_config/jj/`](dot_config/jj/) — jj 全局配置。
- [`dot_config/hj/`](dot_config/hj/) — hj（个人 Git 助手）配置。

### 工具链与环境

- [`dot_config/mise/config.toml`](dot_config/mise/config.toml) — mise 全局工具（`pitchfork`、`fnox`）与 env 文件约定。
- [`fnox.toml`](fnox.toml) — 由 fnox 管理的加密 secrets（GitHub / Cargo / NPM / 工作账号等）。
- [`dot_config/fnox/config.toml`](dot_config/fnox/config.toml) — fnox 的 age provider 配置。
- [`dot_config/pitchfork/config.toml`](dot_config/pitchfork/config.toml) — pitchfork 守护进程（自动同步 `fnox.toml`）。
- [`dot_config/uv/uv.toml`](dot_config/uv/uv.toml) — uv 包索引（阿里云镜像）。
- [`dot_npmrc`](dot_npmrc) — npm 配置。
- [`dot_gradle/init.gradle.kts`](dot_gradle/init.gradle.kts) — Gradle 全局 init 脚本。
- [`Work/mise.toml`](Work/mise.toml) — `~/Work` 专用的 mise env（工作账号）。

### 安装清单

- [`dot_config/setup/brew-deps`](dot_config/setup/brew-deps) — Homebrew 包清单（Brewfile 格式）。
- [`dot_config/setup/brew-apps`](dot_config/setup/brew-apps) — Homebrew Cask 应用清单。

### 文件管理器与编辑器

- [`dot_config/yazi/`](dot_config/yazi/) — yazi 配置：`yazi.toml`、`keymap.toml`、`theme.toml`、`package.toml`，以及 `flavors/`（dracula）与 `plugins/`（ouch）。
- [`dot_config/zed/settings.json`](dot_config/zed/settings.json) — Zed 编辑器设置。
- [`.chezmoitemplates/vscode-settings.json`](.chezmoitemplates/vscode-settings.json) — VSCode 设置模板。
- [`AppData/Roaming/Code/User/`](AppData/Roaming/Code/User/) — Windows VSCode 落地点。
- [`Library/Application Support/Code/User/`](Library/Application%20Support/Code/User/) — macOS VSCode 落地点。

### 文本扩展

- [`dot_config/espanso/`](dot_config/espanso/) — espanso 全局配置、通用/JS/LLM/工作场景片段，以及 `scripts/branchExpand.js`。

### AI 编程助手

- [`dot_claude/CLAUDE.md`](dot_claude/CLAUDE.md) — Claude Code 的个人偏好说明（基本原则、Shell、Coding Style）。
- [`dot_claude/references/javascript.md`](dot_claude/references/javascript.md) — JS/TS 编码风格参考。
- [`dot_codebuddy/`](dot_codebuddy/) — CodeBuddy 对应的 `AGENTS.md` 与 `references`（symlink 至 `dot_claude`）。

### chezmoi 自身

- [`.chezmoi.toml.tmpl`](.chezmoi.toml.tmpl) — chezmoi 初始化模板。
- [`.chezmoiignore`](.chezmoiignore) — chezmoi 忽略规则。
- [`dot_config/chezmoi/chezmoi.toml`](dot_config/chezmoi/chezmoi.toml) — chezmoi 运行时配置。

### 目录占位

- `Playground/`、`Projects/`、`Work/`、`Documents/` 下的 `.keep` 文件用于创建空目录骨架。
