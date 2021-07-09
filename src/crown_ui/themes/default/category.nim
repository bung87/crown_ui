
import karax / [karaxdsl, vdom]
import ./layout
import crown_ui/config
import crown_ui/gen_macros

proc renderCategories*(conf: Config; posts: seq[VNode]): Vnode {.exportTheme, cdecl, exportc, dynlib.} =
  let c = buildHtml(tdiv(class = "mt-3")):
    for thePost in posts:
      tdiv(class = "pure-u pure-u-md-1-3"):
        thePost
  result = renderLayout(conf, c)
