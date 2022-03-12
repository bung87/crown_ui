# head
# body 
  # header
  # main
  # side 
  # footer

import karax / [karaxdsl, vdom]

import crown_ui / [config]
import partial / [header, footer]

proc renderLayout*(conf: Config; n: VNode = nil): VNode =
  doAssert conf != nil
  result = buildHtml(tdiv(class = "layout")):
    PureHeader(conf)
    # tdiv(class = "content"):
      # tdiv(class = "pure-g"):
        # tdiv(class = "pure-u-18-24"):
    if n != nil: n else: discard
      # tdiv(class = "pure-u-6-24")
    PureFooter(conf)
  # Gc_unref(config)

when isMainModule:
  import os
  import crown_ui / [config_parser]
  const exampleDir = currentSourcePath.parentDir.parentDir.parentDir
  let conf = parseConfig(exampleDir / "config.yml")
  setRenderer proc(): VNode = renderLayout(conf)

