
import karax / [karaxdsl, vdom]
import ./layout
import crown_ui/config

proc renderCategories*(config: Config; posts: seq[VNode]): Vnode {.cdecl, exportc, dynlib.} =
  let c = buildHtml(tdiv(class = "mt-3")):
    for thePost in posts:
      tdiv(class = "pure-u pure-u-md-1-3"):
        thePost
  renderLayout(config, c)
