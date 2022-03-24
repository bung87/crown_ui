import karax / [karaxdsl, vdom]

import crown_ui / [config]
import partial / [header, footer]

proc renderLayout*(conf: Config; n: VNode = nil): VNode =
  doAssert conf != nil
  result = buildHtml(tdiv(class = "layout", data-theme = "dark")):
    PureHeader(conf)
    # tdiv(class = "content"):
      # tdiv(class = "pure-g"):
        # tdiv(class = "pure-u-18-24"):
    if n != nil: n else: discard
      # tdiv(class = "pure-u-6-24")
    PureFooter(conf)


