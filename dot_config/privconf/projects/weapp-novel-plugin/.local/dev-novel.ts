#!/usr/bin/env bun
// dn 链：mpflow 构建 dev 插件 → ticket 上传 → 回写 novel app.json → 预览宿主小程序
// flags: --auto 自动预览直推手机（免扫码）；--force 忽略源码未变缓存强制全量
import { $ } from "bun";
import { readdirSync } from "node:fs";
import { resolve } from "node:path";

// 约定从插件仓根目录运行（mise 任务 dir 契约）；宿主目录复用 .env 的 MINIPROGRAM_NOVEL_DIR（绝对或相对插件仓），缺省 ../miniprogram-novel
const PLUGIN_DIR = process.cwd();
const NOVEL_DIR = resolve(PLUGIN_DIR, process.env.MINIPROGRAM_NOVEL_DIR ?? "../miniprogram-novel");
const MINIBUILD = "/Volumes/2tb-ssd/nebula/Work/miniprogram-compiler-rs/target/release/minibuild";
const APP_JSON = `${NOVEL_DIR}/miniprogram/app.json`;
const STATE_FILE = "/tmp/dev-novel-plugin.state";

const flags = new Set(process.argv.slice(2));

// bun 自动加载项目 .env.local（PREVIEW=preview，无效值），构建阶段必须显式归位为 none（禁上传/预览）
process.env.PREVIEW = "none";

/** 插件源码指纹：src 全树 + mpflow.config.js + package.json + project.config.json（路径 + 内容，增删改名都算变化；config 决定上传身份 appid，两个 checkout 共享 state 时防止配置漂移误跳过） */
async function pluginFingerprint(): Promise<string> {
  const files: string[] = [];
  const walk = (dir: string) => {
    for (const e of readdirSync(dir, { withFileTypes: true })) {
      if (e.name === ".DS_Store") continue;
      const p = `${dir}/${e.name}`;
      e.isDirectory() ? walk(p) : files.push(p);
    }
  };
  walk(`${PLUGIN_DIR}/src`);
  files.push(`${PLUGIN_DIR}/mpflow.config.js`, `${PLUGIN_DIR}/package.json`, `${PLUGIN_DIR}/project.config.json`);
  const hasher = new Bun.CryptoHasher("md5");
  for (const p of files.sort()) {
    hasher.update(p);
    hasher.update(await Bun.file(p).arrayBuffer());
  }
  return hasher.digest("hex");
}

// 0. 插件源码未变则跳过构建+上传（宿主-only 迭代 ~11.6s → ~3s）
const fingerprint = await pluginFingerprint();
const state = await Bun.file(STATE_FILE).json().catch(() => null);
let id: string;
if (!flags.has("--force") && state?.hash === fingerprint && state.id) {
  id = state.id;
  console.log(`插件无变化，跳过构建+上传（复用 dev-${id}）`);
} else {
  // 1. mpflow 一次性 dev 构建（直调 bin 省 pnpm 包装 ~0.5s）
  await $`cd ${PLUGIN_DIR} && ./node_modules/.bin/mpflow-service build --dev`;

  // 2. 编译并上传 dev 插件（ticket 链）
  const upload = await $`${MINIBUILD} upload --project ${PLUGIN_DIR} --ticket --version 1.999.999 --desc 开发版本 --out /tmp/plugin-ticket`.nothrow().quiet();
  const log = [upload.stdout, upload.stderr].map(b => b?.toString() ?? "").join("\n");
  console.log(log);
  if (upload.exitCode !== 0) process.exit(1);
  id = /Development Version Plugin ID: (\S+)/.exec(log)?.[1] ?? "";
  if (!id) {
    console.error("未解析到 dev_plugin_id");
    process.exit(1);
  }
  console.log(`dev_plugin_id: ${id}`);
  await Bun.write(STATE_FILE, JSON.stringify({ hash: fingerprint, id }));
}

// 3. 回写 novel app.json 插件开发版 id（幂等）
const app = (await Bun.file(APP_JSON).json()) as any;
app.plugins["novel-plugin"].version = `dev-${id}`;
await Bun.write(APP_JSON, JSON.stringify(app, null, 2) + "\n");
console.log(`app.json 插件版本已更新为 dev-${id}`);

// 4. 编译并预览宿主小程序
const previewArgs = ["--project", NOVEL_DIR, "--private-key", `${NOVEL_DIR}/build/config/key`, "--out", "/tmp/weapp-novel-preview"];
if (flags.has("--auto")) {
  await $`${MINIBUILD} preview ${[...previewArgs, "--auto"]}`;
  console.log("已推送自动预览到手机");
} else {
  await $`${MINIBUILD} preview ${previewArgs}`;
  await $`open /tmp/weapp-novel-preview/qrcode.jpg`;
}
