这里可以放置自定义脚本和自定义 CLI。

通常建议使用 [Bun Shell](https://bun.com/docs/runtime/shell) 搭配 [Usage Script](https://usage.jdx.dev/cli/scripts) 来使用，来获得：

- 最直观的脚本写法（类似 zx）；
- 较好的性能（主流用法中仅次于 Rust Script，强于 Node / Python / Bash）；
- 开箱即用的 --help，参数提示等。

## 开发

如果需要开发脚本，则需要依赖类型提示。运行 `bun install` 来安装依赖。

## 解析参数

对于简单的脚本，使用 [Usage Script](https://usage.jdx.dev/cli/scripts) 来解析参数，并使用注入的环境变量来获取参数，例如：

```js
#!/usr/bin/env -S usage exec bun
//USAGE flag "-f --force" help="Overwrite existing <file>"
//USAGE flag "-u --user <user>" help="User to run as"
//USAGE arg "<file>" help="The file to write" default="file.txt"
const { usage_user, usage_force, usage_file } = process.env;
```

对于接受数组参数的脚本，或更复杂逻辑的命令行工具，可以使用命令行框架。
