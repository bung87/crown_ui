
import karax / [karaxdsl, vdom]
import ./layout
import crown_ui/config
import tables
import crown_ui/gen_macros

proc renderTag*(config: Config; tagCount: Table[string, int]): Vnode {.exportTheme, cdecl, exportc, dynlib.} =
  let c = buildHtml(tdiv(class = "mt-3")):
    for tag, count in tagCount:
      tdiv:
        tdiv(class = "pure-u-1"):
          h2:
            text $tag
  result = renderLayout(config, c)
