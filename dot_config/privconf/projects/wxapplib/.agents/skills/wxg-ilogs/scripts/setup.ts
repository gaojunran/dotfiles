// Setup script for ilogs skill
// TENCENT_WXG_ILOGS_TOKEN must be set — obtain it from https://mmac.woa.com/wego/weacllmagentweb/mcp?svr_name=ilogs&option_type=my_token

import { execSync } from "node:child_process";

const ILOGS_TOKEN_OBTAIN_URL = "https://mmac.woa.com/wego/weacllmagentweb/mcp?svr_name=ilogs&option_type=my_token";
const ILOGS_MCP_ENDPOINT = "http://transfer.mmacmcpproxy.polaris:8080/mcp/ilogs";
const TOKEN = process.env.TENCENT_WXG_ILOGS_TOKEN;

// ── helpers ──────────────────────────────────────────────────────────────────

function run(cmd: string, opts = {}) {
  return execSync(cmd, { stdio: "inherit", ...opts });
}

function tryRun(cmd: string) {
  try {
    return execSync(cmd, { stdio: "pipe" }).toString().trim();
  } catch {
    return null;
  }
}

function hasMcporter() {
  return tryRun("mcporter --version") !== null;
}

// ── main ─────────────────────────────────────────────────────────────────────

console.log("Setting up iLogs MCP Skill...\n");

// 1. Ensure mcporter is installed
if (!hasMcporter()) {
  console.log("mcporter not found — installing via npm...");
  run("npm install -g mcporter");
  console.log("mcporter installed.\n");
} else {
  console.log("mcporter already installed.\n");
}

// 2. Token is required — it is NOT auto-provided by the runtime for this skill
if (!TOKEN) {
  console.error(
    "Error: TENCENT_WXG_ILOGS_TOKEN is not set.\n" +
      `Obtain your token at: ${ILOGS_TOKEN_OBTAIN_URL}` +
      "Then set it with:\n" +
      "  openclaw config set env.TENCENT_WXG_ILOGS_TOKEN <your-token>\n",
  );
  process.exit(1);
}

// 3. Register the Tencent iLogs MCP endpoint
// Note: header key must be Authorization (not token/auth/X-Token)
console.log("Configuring mcporter...");
run(
  `mcporter config add ilogs "${ILOGS_MCP_ENDPOINT}" ` +
    `--header "X-Ac-Token=${TOKEN}" ` +
    `--transport http ` +
    `--scope home`,
);
console.log("");

// 4. Verify
console.log("Verifying configuration...");
const list = tryRun("mcporter list");
if (list && list.includes("ilogs")) {
  console.log("Configuration verified.\n");
} else {
  console.warn(
    "Warning: 'ilogs' not found in mcporter list. " +
      "Check your network or token and re-run if needed.\n",
  );
}

console.log("Setup complete.");
