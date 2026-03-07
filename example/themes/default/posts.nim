
import karax / [karaxdsl, vdom]
import ./layout
import crown_uipkg/types
import crown_uipkg/config
import ./partial/pagination

proc renderPosts*(conf: Config; posts: seq[VNode]; pagination: Pagination): Vnode =
  let c = buildHtml(tdiv(class = "mt-3")):
    for i, p in posts:
      tdiv(class = "pure-u pure-u-md-1-3"):
        p
    renderPagination(conf, pagination)
  result = renderLayout(conf, c)
