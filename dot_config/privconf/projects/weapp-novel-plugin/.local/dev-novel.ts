#!/usr/bin/env bun
// dn 链：mpflow 构建 dev 插件 → ticket 上传 → 回写 novel app.json → 预览宿主小程序
// flags: --auto 自动预览直推手机（免扫码）；--force 忽略源码未变缓存强制全量
import { $ } from "bun";
import { readdirSync } from "node:fs";
import { resolve } from "node:path";

// 约定从插件仓根目录运行（mise 任务 dir 契约）；宿主目录复用 .env 的 MINIPROGRAM_NOVEL_DIR（绝对或相对插件仓），缺省 ../miniprogram-novel
const PLUGIN_DIR = process.cwd();
const NOVEL_DIR = resolve(PLUGIN_DIR, process.env.MINIPROGRAM_NOVEL_DIR ?? "../miniprogram-novel");
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

/**
 * mpflow 一次性 dev 构建（直调 bin 省 pnpm 包装 ~0.5s）+ ticket 链上传，返回 dev_plugin_id 并写缓存
 *
 * Changelog:
 * - 1. 抽成可复用函数，供缓存失效时二次上传 (1 shots by deepseek-v4.1-flash-official)
 */
async function buildAndUpload(fingerprint: string): Promise<string> {
  await $`cd ${PLUGIN_DIR} && ./node_modules/.bin/mpflow-service build --dev`;

  const upload = await $`minidev upload --project ${PLUGIN_DIR} --ticket --version 1.999.999 --desc 开发版本 --out /tmp/plugin-ticket`.nothrow().quiet();
  const log = [upload.stdout, upload.stderr].map(b => b?.toString() ?? "").join("\n");
  console.log(log);
  if (upload.exitCode !== 0) process.exit(1);

  const id = /Development Version Plugin ID: (\S+)/.exec(log)?.[1] ?? "";
  if (!id) {
    console.error("未解析到 dev_plugin_id");
    process.exit(1);
  }
  console.log(`dev_plugin_id: ${id}`);
  await Bun.write(STATE_FILE, JSON.stringify({ hash: fingerprint, id }));
  return id;
}

/** 回写 novel app.json 插件开发版 id（幂等） */
async function writeAppJson(id: string) {
  const app = (await Bun.file(APP_JSON).json()) as any;
  app.plugins["novel-plugin"].version = `dev-${id}`;
  await Bun.write(APP_JSON, JSON.stringify(app, null, 2) + "\n");
  console.log(`app.json 插件版本已更新为 dev-${id}`);
}

/** 编译并预览宿主小程序（ticket 链，免私钥）；捕获输出以识别失效的开发版 id */
async function preview() {
  const args = ["--project", NOVEL_DIR, "--ticket", "--out", "/tmp/weapp-novel-preview"];
  if (flags.has("--auto")) args.push("--auto");

  const result = await $`minidev preview ${args}`.nothrow().quiet();
  const log = [result.stdout, result.stderr].map(b => b?.toString() ?? "").join("\n");
  console.log(log);
  return { ok: result.exitCode === 0, log };
}

// 0. 插件源码未变则跳过构建+上传（宿主-only 迭代 ~16s → ~1s）
const fingerprint = await pluginFingerprint();
const state = await Bun.file(STATE_FILE).json().catch(() => null);
const cached: string = !flags.has("--force") && state?.hash === fingerprint && state.id ? state.id : "";
if (cached) console.log(`插件无变化，跳过构建+上传（复用 dev-${cached}）`);
let id = cached || (await buildAndUpload(fingerprint));
await writeAppJson(id);

let result = await preview();
// 开发版 id 只在「本开发者最后一次上传」前有效：期间在开发者工具/CI 传过新版本就会失效（-80403），重传一次即可
if (!result.ok && /开发版插件未找到|-80403/.test(result.log)) {
  console.log("缓存的开发版插件已被新上传覆盖，重新构建并上传...");
  id = await buildAndUpload(fingerprint);
  await writeAppJson(id);
  result = await preview();
}
if (!result.ok) process.exit(1);

if (flags.has("--auto")) console.log("已推送自动预览到手机");
else await $`open /tmp/weapp-novel-preview/qrcode.jpg`;
