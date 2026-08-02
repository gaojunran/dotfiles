#!/usr/bin/env bun
// CodeBuddy 环境配置安装脚本（单文件，依赖 bun）
// 用法: bun install_env.js
//
// 认证值通过 fnox set 存储为环境变量，opencode.jsonc 通过 {env:VAR} 引用。
//
import { $ } from "bun";
import { applyEdits, modify, parse } from "jsonc-parser";
import {
    existsSync,
    readFileSync,
    writeFileSync,
    realpathSync,
} from "node:fs";
import { homedir } from "node:os";
import { join, dirname } from "node:path";
import * as readline from "node:readline/promises";
import { stdin as input, stdout as output } from "node:process";

const HOME = homedir();
const SCRIPT_DIR = import.meta.dir;
const AUTH_FILE = join(
    HOME,
    "Library/Application Support/CodeBuddyExtension/Data/Public/auth/Tencent-Cloud.coding-copilot.info",
);
const OPENCODE_EXAMPLE = join(SCRIPT_DIR, "opencode.example.json");
const OPENCODE_CONFIG = join(SCRIPT_DIR, "opencode.jsonc");

// --- helpers ---

function readJson(path) {
    return JSON.parse(readFileSync(path, "utf8"));
}

function writeJson(path, obj) {
    writeFileSync(path, JSON.stringify(obj, null, 4) + "\n");
}

// 通过 fnox set 将认证值存储为环境变量（stdin 传递，避免暴露在 ps 输出中）
async function fnoxSet(key, value) {
    const proc = Bun.spawn(["fnox", "set", key], {
        stdin: new TextEncoder().encode(value),
        stdout: "inherit",
        stderr: "inherit",
    });
    const exitCode = await proc.exited;
    if (exitCode !== 0) {
        throw new Error(`fnox set ${key} 失败 (exit ${exitCode})`);
    }
    console.log(`[CodeBuddy] fnox: 已设置 ${key}`);
}

function mergeCodeBuddyProvider(path, codebuddy) {
    const content = readFileSync(path, "utf8");
    const errors = [];
    parse(content, errors, { allowTrailingComma: true, disallowComments: false });
    if (errors.length > 0) {
        throw new Error(`${path} 不是有效的 JSONC 配置`);
    }

    const edits = modify(content, ["provider", "codebuddy"], codebuddy, {
        formattingOptions: {
            insertSpaces: true,
            tabSize: 2,
            eol: "\n",
        },
    });
    writeFileSync(path, applyEdits(content, edits));
}

// --- CodeBuddy Code 安装路径查找 ---

async function findInstallPath() {
    const candidates = [
        "/opt/homebrew/lib/node_modules/@tencent-ai/codebuddy-code",
        "/usr/local/lib/node_modules/@tencent-ai/codebuddy-code",
    ];
    try {
        const root = (await $`npm root -g`.text()).trim();
        if (root) candidates.unshift(join(root, "@tencent-ai", "codebuddy-code"));
    } catch {}
    const bin = Bun.which("codebuddy");
    if (bin) {
        // which 返回的可能是符号链接，解析真实路径后上溯两级
        const realBin = realpathSync(bin);
        candidates.unshift(dirname(dirname(realBin)));
    }
    return candidates.find((p) => existsSync(join(p, "product.json"))) ?? null;
}

function productFileFor(env) {
    if (env === "ioa") return "product.ioa.json";
    if (env === "internal") return "product.internal.json";
    return "product.json";
}

// product.json 滞后于后端实际可用模型：部分模型（如 gpt-5.6 系列）已由 CodeBuddy 后端
// 提供（已通过 copilot.tencent.com/v2 验证），但未写入本地 product 文件。这里按 product
// 的 schema 补充这些模型，syncModels 会经 convertModel 统一转换；若 product.json 之后补上
// 同 id 模型，则以 product.json 为准（不覆盖）。
const EXTRA_BACKEND_MODELS = [
    {
        id: "gpt-5.6-sol",
        name: "GPT-5.6 Sol",
        supportsToolCall: true,
        supportsImages: true,
        supportsReasoning: true,
        maxInputTokens: 1050000,
        maxOutputTokens: 128000,
    },
    {
        id: "gpt-5.6-terra",
        name: "GPT-5.6 Terra",
        supportsToolCall: true,
        supportsImages: true,
        supportsReasoning: true,
        maxInputTokens: 1050000,
        maxOutputTokens: 128000,
    },
    {
        id: "gpt-5.6-luna",
        name: "GPT-5.6 Luna",
        supportsToolCall: true,
        supportsImages: true,
        supportsReasoning: true,
        maxInputTokens: 1050000,
        maxOutputTokens: 128000,
    },
];

// product.json 模型 → opencode 模型格式
function convertModel(m) {
    if (m.tags?.some((t) => t === "text-to-image" || t === "image-to-image")) return null;
    const result = {
        name: m.name + " (CodeBuddy)",
        tool_call: m.supportsToolCall !== false,
        reasoning: false,
        attachment: m.supportsImages !== false,
        temperature: true,
    };
    if (m.supportsImages) {
        result.modalities = { input: ["text", "image"], output: ["text"] };
    }
    if (m.maxInputTokens || m.maxOutputTokens) {
        result.limit = {};
        if (m.maxInputTokens) result.limit.context = m.maxInputTokens;
        if (m.maxOutputTokens) result.limit.output = m.maxOutputTokens;
    }
    if (m.supportsReasoning) {
        result.variants = {
            low: { reasoningEffort: "low", reasoningSummary: "auto" },
            high: { reasoningEffort: "high", reasoningSummary: "auto" },
        };
    }
    return result;
}

// 同步 product.json 模型到 opencode.example.json（保持 {env:VAR} 占位符模板）
async function syncModels(internetEnv) {
    if (!existsSync(OPENCODE_EXAMPLE)) {
        console.error("[CodeBuddy] 警告: opencode.example.json 不存在，跳过模型同步");
        return;
    }
    const installPath = await findInstallPath();
    if (!installPath) {
        console.error("[CodeBuddy] 警告: 未找到 CodeBuddy Code，跳过模型同步");
        return;
    }
    const productPath = join(installPath, productFileFor(internetEnv));
    if (!existsSync(productPath)) {
        console.error(`[CodeBuddy] 警告: ${productPath} 不存在，跳过模型同步`);
        return;
    }
    const product = readJson(productPath);
    if (!Array.isArray(product.models)) {
        console.error("[CodeBuddy] 警告: product 配置无 models 数组");
        return;
    }
    const models = {};
    for (const m of product.models) {
        const c = convertModel(m);
        if (c) models[m.id] = c;
    }
    // 补充 product.json 漏列、但后端实际可用的模型
    for (const m of EXTRA_BACKEND_MODELS) {
        if (models[m.id]) continue;
        const c = convertModel(m);
        if (c) models[m.id] = c;
    }
    const config = readJson(OPENCODE_EXAMPLE);
    if (config.provider?.codebuddy) {
        config.provider.codebuddy.models = models;
        writeJson(OPENCODE_EXAMPLE, config);
        console.error(
            `[CodeBuddy] 已同步 ${Object.keys(models).length} 个模型到 opencode.example.json`,
        );
    }
}

// 把 example 的 codebuddy provider（保留 {env:VAR} 占位符）合并到实际 opencode JSONC 配置
async function applyOpencode(envValues) {
    if (!existsSync(OPENCODE_EXAMPLE)) {
        console.error(`[CodeBuddy] 警告: ${OPENCODE_EXAMPLE} 不存在，跳过`);
        return;
    }
    const example = readJson(OPENCODE_EXAMPLE);
    if (!example.provider?.codebuddy) {
        console.error("[CodeBuddy] 错误: example 中无 codebuddy provider");
        return;
    }

    // 通过 fnox 设置环境变量
    for (const [key, value] of Object.entries(envValues)) {
        await fnoxSet(key, value);
    }

    // 直接使用 example 中的 codebuddy provider（保留 {env:VAR} 占位符和 env 声明）
    const codebuddy = structuredClone(example.provider.codebuddy);

    if (!existsSync(OPENCODE_CONFIG)) {
        const newConfig = structuredClone(example);
        newConfig.provider = newConfig.provider || {};
        newConfig.provider.codebuddy = codebuddy;
        writeJson(OPENCODE_CONFIG, newConfig);
        console.log(`[CodeBuddy] 已创建: ${OPENCODE_CONFIG}`);
    } else {
        mergeCodeBuddyProvider(OPENCODE_CONFIG, codebuddy);
        console.log(`[CodeBuddy] 已更新 codebuddy provider: ${OPENCODE_CONFIG}`);
    }
    console.log("[CodeBuddy] 提示: 如果 OpenCode 正在运行，请重启以加载新配置");
}

// --- 主流程 ---

if (!existsSync(AUTH_FILE)) {
    console.error("[CodeBuddy] 警告: 认证文件不存在，请先通过 CodeBuddy 登录");
    console.error(`  ${AUTH_FILE}`);
    process.exit(1);
}

const auth = readJson(AUTH_FILE);
const domain = auth.auth.domain || auth.account?.sso?.domain || "";

// internetEnv 仅用于选 product 文件，不写入 opencode 配置
let internetEnv = process.env.CODEBUDDY_INTERNET_ENVIRONMENT || "";
if (!internetEnv && domain) {
    if (domain.includes("ioa") || domain.includes("tencent.sso")) internetEnv = "ioa";
    else if (domain.includes("copilot.tencent.com")) internetEnv = "internal";
}

// 环境变量名与对应的认证值
const envValues = {
    CODEBUDDY_ACCESS_TOKEN: auth.auth.accessToken,
    CODEBUDDY_USER_ID: String(auth.account.uid),
    CODEBUDDY_ENTERPRISE_ID: String(auth.account.enterpriseId),
    CODEBUDDY_DOMAIN: domain,
};

// 1. 同步模型列表到 example（保持占位符模板）
await syncModels(internetEnv);

// 2. 交互确认
const rl = readline.createInterface({ input, output });
const answer = await rl.question("[CodeBuddy] 是否配置 OpenCode? (y/N) ");
rl.close();

if (answer.trim().toLowerCase().startsWith("y")) {
    // 3. 通过 fnox 设置环境变量，并合并 provider 配置（保留 {env:VAR} 占位符）
    await applyOpencode(envValues);
    console.log(`\n[CodeBuddy] 完成。认证值已通过 fnox 设置，opencode.jsonc 使用 {env:VAR} 引用。`);
} else {
    console.log("[CodeBuddy] 跳过工具配置");
}
