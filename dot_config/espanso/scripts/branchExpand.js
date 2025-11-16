// Deno script for Espanso Branch Expansion

const type = Deno.env.get("ESPANSO_FORM1_KIND") ?? "";
const issue = Deno.env.get("ESPANSO_FORM1_ISSUE") ?? "";
const modulesRaw = Deno.env.get("ESPANSO_FORM1_MODULES") ?? "";

// 输出前缀
let output = `${type}-${issue}`;

// 逐行处理模块名
const modules = modulesRaw.split(/\r?\n/);

for (const mod of modules) {
  const name = mod.trim();
  if (!name) continue;

  output += ` [${name}](https://git.woa.com/wxweb/${name}/tree/${type}-${issue})`;
}

console.log(output);
