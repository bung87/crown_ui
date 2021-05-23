# head
# body 
  # header
  # main
  # side 
  # footer

import karax / [karaxdsl, vdom]
when defined(js):
  include karax / prelude
import partial / [header, footer]
proc render*(n: VNode = nil): VNode =
  result = buildHtml(tdiv):
    PureHeader()
    tdiv(class = "content"):
      tdiv(class = "pure-g"):
        tdiv(class = "pure-u-18-24"):
          if n != nil: n else: discard
          h4(id = "participating-as-an-audience"):
            text "Participating as an audience"
          p:
            text "All talks will be streamed and recorded for later viewing. Watching the talks live will allow you to ask questions and participate in the discussions with other viewers and the speakers."
        tdiv(class = "pure-u-6-24")
    PureFooter()

when isMainModule:
  when defined(js):
    setRenderer proc(data: RouterData): VNode = render()
  else:
    echo render()
