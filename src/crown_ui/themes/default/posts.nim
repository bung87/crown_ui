
import karax / [karaxdsl, vdom]
import ./layout
import crown_ui/types
import crown_ui/config
import ./partial/pagination

proc renderPosts*(conf: Config; posts: seq[VNode]; pagination: Pagination): Vnode {.cdecl, exportc, dynlib.} =
  let c = buildHtml(tdiv(class = "mt-3")):
    for thePost in posts:
      tdiv(class = "pure-u pure-u-md-1-3"):
        thePost
    renderPagination(conf, pagination)
  renderLayout(conf, c)
