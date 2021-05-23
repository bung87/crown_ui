# head
# body 
  # header
  # main
  # side 
  # footer

import karax / [karaxdsl, vdom]
when defined(js):
  include karax / prelude

proc render*(n: VNode = nil): VNode =
  result = buildHtml(tdiv):
    tdiv(class = "content"):
      tdiv(class = "pure-g"):
        tdiv(class = "pure-u-18-24"):
          if n != nil: n else: discard
        tdiv(class = "pure-u-6-24")
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
  when defined(js):
    setRenderer proc(data: RouterData): VNode = render()
  else:
    echo render()
