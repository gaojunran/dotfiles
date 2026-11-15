// 把 fnox 的 secrets 按"命令实际所在的目录"注入 agent 的 shell，而不是沿用
// opencode 进程启动时那份 $HOME 快照。
//
// 同时注册两个入口：
//   - V2 ctx.shell.hook("create.before")：opencode 原生 shell/terminal
//   - V1 "shell.env"：AFT 的 bash 工具通过 plugin.trigger 调它
// 任一入口生效即可，重复注入是幂等的。
//
// 注入 AGENT_SHELL_ENV=1 作为存活标记：~/.config/shell/agent-bash-env.sh 只在
// 看不到这个标记时才回退到自己跑 fnox，所以插件没加载时行为与之前一致。

import { execFile } from "node:child_process";
import { statSync } from "node:fs";
import { dirname, join } from "node:path";
import { promisify } from "node:util";

const run = promisify(execFile);
const MARKER = "AGENT_SHELL_ENV";
const CONFIG_NAMES = ["fnox.toml", ".fnox.toml"];

// AFT 拒绝这些名字出现在单次调用的 env 里（会整条命令失败），
// 所以即使 fnox 里写了也要挡掉。
const BLOCKED_NAMES = new Set([
  "PATH", "HOME", "SHELL", "BASH_ENV", "ENV", "IFS", "SHELLOPTS", "BASHOPTS",
  "PROMPT_COMMAND", "PS4", "NODE_OPTIONS", "NODE_PATH", "PYTHONSTARTUP",
  "PYTHONPATH", "PYTHONHOME", "PYTHONUSERBASE", "PERL5OPT", "PERL5LIB",
  "PERLLIB", "PERL5DB", "RUBYOPT", "RUBYLIB", "JAVA_TOOL_OPTIONS",
  "_JAVA_OPTIONS", "JDK_JAVA_OPTIONS", "TMPDIR", "TMP", "TEMP", "COMSPEC",
  "PATHEXT", "SYSTEMROOT", "PSMODULEPATH", "USERPROFILE", "APPDATA",
  "LOCALAPPDATA", "CARGO_HOME", "RUSTUP_HOME", "GIT_DIR", "GIT_WORK_TREE",
  "GIT_SSH", "GIT_SSH_COMMAND", "GIT_ASKPASS", "SSH_ASKPASS",
  "RUSTC_WRAPPER", "RUST_TEST_THREADS", "NEXTEST_TEST_THREADS",
  "DBUS_SESSION_BUS_ADDRESS",
]);
const BLOCKED_PREFIXES = [
  "LD_", "DYLD_", "BASH_FUNC_", "GIT_CONFIG", "AFT_", "SUBC_", "CORTEXKIT_",
  "CORTEX_", "CK_", "SCCACHE_", "XDG_",
];

// cwd → 该目录下算出的 secrets，配置 mtime/size 一变就重算
const cache = new Map();

function blocked(name) {
  const upper = name.toUpperCase();
  return BLOCKED_NAMES.has(upper) || BLOCKED_PREFIXES.some((prefix) => upper.startsWith(prefix));
}

function findConfig(start) {
  let dir = start;
  for (;;) {
    for (const name of CONFIG_NAMES) {
      const candidate = join(dir, name);
      try {
        if (statSync(candidate).isFile()) return candidate;
      } catch {
        // 不存在就继续往上找
      }
    }
    const parent = dirname(dir);
    if (parent === dir) return undefined;
    dir = parent;
  }
}

async function secretsFor(cwd) {
  const config = findConfig(cwd);
  if (!config) return {};
  let key;
  try {
    const stat = statSync(config);
    key = `${config}:${stat.mtimeMs}:${stat.size}`;
  } catch {
    return {};
  }
  const hit = cache.get(cwd);
  if (hit && hit.key === key) return hit.env;

  try {
    const { stdout } = await run("fnox", ["export", "-f", "json"], {
      cwd,
      timeout: 10_000,
      maxBuffer: 8 << 20,
    });
    const parsed = JSON.parse(stdout);
    const env = {};
    for (const [name, value] of Object.entries(parsed?.secrets ?? {})) {
      if (typeof value === "string" && !blocked(name)) env[name] = value;
    }
    cache.set(cwd, { key, env });
    return env;
  } catch {
    // 解密失败、key 缺失、fnox 不在 PATH：都不该影响命令执行
    return {};
  }
}

async function apply(cwd, env) {
  if (!cwd || !env) return;
  env[MARKER] = "1";
  Object.assign(env, await secretsFor(cwd));
}

export default {
  id: "agent-shell-env",
  async setup(ctx) {
    try {
      await ctx?.shell?.hook?.("create.before", (event) => apply(event.cwd, event.env));
    } catch {
      // 宿主没有 V2 shell 域时静默跳过，交给 V1 入口
    }
  },
  // AFT 的 bash 工具按名字触发 "shell.env"（V1 形态）
  async server() {
    return {
      "shell.env": async (input, output) => {
        try {
          await apply(input?.cwd, output?.env);
        } catch {
          // 注入失败也要让命令跑
        }
        return output;
      },
    };
  },
};
