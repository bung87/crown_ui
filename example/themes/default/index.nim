import karax / [karaxdsl, vdom]
import ./layout
import crown_ui/config

proc renderIndex*(config: Config; posts: seq[VNode]): Vnode {.cdecl, exportc, dynlib.} =
  let c = buildHtml(tdiv(class = "mt-3")):
    for p in posts:
      p
  renderLayout(config, c)

