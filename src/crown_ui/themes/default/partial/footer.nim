import karax / [karaxdsl, vdom]
import json, tables, sequtils
import crown_ui/config


proc PureFooter*(conf: Config): VNode =
  doAssert conf != nil
  result = buildHtml(footer()):
    section(class = "content"):
      tdiv(class = "pure-g"):
        tdiv(class = "copyright pure-u-2-3"):
          p():
            text "This website proudly writing in "
            a(href = "https://nim-lang.org/"):
              text "Nim"
            text " (Nim is a statically typed compiled systems programming language.) "
            if conf.theme_config != nil:
              if conf.theme_config.hasKey("source_link"):
                var fields = conf.theme_config{"source_link"}.getFields()
                if fields.len > 0:
                  let s = toSeq(fields.pairs)
                  if s.len > 0:
                    let (k, v) = s[0]
                    text " and source code is available on "
                    a(href = v.getStr("")):
                      text k
                    text " and contributions are welcome."

