
import karax / [karaxdsl, vdom]
import ./layout
import crown_ui/config
import tables

proc renderTag*(config: Config; tagCount: Table[string, int]): Vnode {.cdecl, exportc, dynlib.} =
  let c = buildHtml(tdiv(class = "mt-3")):
    for tag, count in tagCount:
      tdiv:
        tdiv(class = "pure-u-1"):
          h2:
            text $tag
  renderLayout(config, c)
