---
name: create-github-repo
description: 当需要创建一个新的 GitHub 仓库的时候使用。这里包含了用户偏好的默认仓库配置。
---

新建一个 github 仓库，需要满足以下要求（用户显式要求时则覆盖这些规则）：

1. 仓库名必须事先和用户确认。可以给用户提供几个备选。
2. 需要包含 `README.md`（默认英文，另需一个中文的 README 并在主 README 下挂一个链接）。README 内容应该简洁，不应该包含过多项目实现的细节，它们应该放到 docs/ 下。
3. 需要包含 `AGENTS.md`。用户没有额外要求的时候，默认包含以下内容：

## `AGENTS.md` 默认内容

```
1. 保持 README 简洁而精致。项目的细节需要同步到 docs/ 中，而不是直接放到 README 里。仓库中同时有中英文 README，修改 README 的时候需要同步修改。
2. 每次修改完一波代码后，都应该把实现细节同步到 docs/ 中，以便后续审阅。
```

4. 需要包含 linter / formatter 配置。如果仓库中现在没有的话需要配置。TS / JS 项目默认使用 oxlint。
5. 需要包含 mise.toml 配置。如果仓库中现在没有的话需要配置。
6. 需和用户确认是否需要 GitHub Action CI 配置、以及 release 流水线。
