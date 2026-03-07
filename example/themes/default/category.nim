
import karax / [karaxdsl, vdom]
import ./layout
import crown_uipkg/config

proc renderCategories*(conf: Config; posts: seq[VNode]): Vnode =
  let c = buildHtml(tdiv(class = "mt-3")):
    for thePost in posts:
      tdiv(class = "pure-u pure-u-md-1-3"):
        thePost
  result = renderLayout(conf, c)
