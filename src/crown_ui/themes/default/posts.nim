
import karax / [karaxdsl, vdom]
import ./layout
import crown_ui/types
import crown_ui/config
import ./partial/pagination
import crown_ui/gen_macros

proc renderPosts*(conf: Config; posts: seq[VNode]; pagination: Pagination): Vnode {.exportTheme, cdecl, exportc, dynlib.} =
  let c = buildHtml(tdiv(class = "mt-3")):
    for i, p in posts:
      echo i, p.kind
      tdiv(class = "pure-u pure-u-md-1-3"):
        p
    renderPagination(conf, pagination)
  result = renderLayout(conf, c)
