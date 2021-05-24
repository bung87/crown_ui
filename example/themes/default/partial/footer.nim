import karax / [karaxdsl, vdom]
import json
proc PureFooter*(config: JsonNode; n: VNode = nil): VNode =
  buildHtml():
    footer:
      section(class = "content"):
        tdiv(class = "pure-g"):
          tdiv(class = "copyright pure-u-2-3"):
            p:
              text "This website proudly writing in "
              a(href = "https://nim-lang.org/"):
                text "Nim"
              text " (Nim is a statically typed compiled systems programming language.) "
              text " and source code is available on "
              a(href = "#"):
                text "GitHub"
              text " and contributions are welcome."

when isMainModule:
  echo PureFooter()

