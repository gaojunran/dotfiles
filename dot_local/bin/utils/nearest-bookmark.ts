import { $ } from "bun";

/**
 * 按图距离逐层向上(ancestors(@, depth) 递增)找距离工作副本最近的书签。
 *
 * 不能用 heads(::@ & bookmarks()) 之类的顶层写法:合并 DAG 里一个距离更近的书签
 * 可能被同血脉里距离更远的书签后代遮蔽而淘汰(heads 只认"集合内无书签后代",不认
 * 到 @ 的跳数)。逐层膨胀距离环后,第一个非空环里的书签必然都在最小距离上,因此
 * 任何取其一都正确。找不到(祖先里没有书签)时返回 undefined。
 */
export async function findNearestBookmark(from = "@"): Promise<string | undefined> {
  for (let depth = 1; depth <= 64; depth++) {
    const revset = `ancestors(${from}, ${depth}) & bookmarks()`;
    const name = (await $`jj --ignore-working-copy log -r ${revset} --no-graph -n 1 -T 'if(local_bookmarks, local_bookmarks.first().name(), "")' --no-pager`.text()).trim();
    if (name) return name;
  }
  return undefined;
}