import karax / [karaxdsl, vdom]
import json, tables, sequtils
import crown_ui/config


proc PureFooter*(config: Config): VNode =
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
              let (k, v) = toSeq(config.theme_config{"source_link"}.getFields.pairs)[0]
              text " and source code is available on "
              a(href = v.getStr()):
                text k
              text " and contributions are welcome."


