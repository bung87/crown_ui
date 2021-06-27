# head
# body 
  # header
  # main
  # side 
  # footer

import karax / [karaxdsl, vdom]

import crown_ui / [config, utils]

import partial / [header, footer]

proc renderLayout*(conf: Config; n: VNode = nil): VNode =
  doAssert conf != nil
  let header = PureHeader(conf)
  let footer = PureFooter(conf)
  result = buildHtml(tdiv(class = "layout")):
    header
    # tdiv(class = "content"):
      # tdiv(class = "pure-g"):
        # tdiv(class = "pure-u-18-24"):
    if n != nil: n else: discard
      # tdiv(class = "pure-u-6-24")
    footer
  # Gc_unref(config)

when isMainModule:
  const exampleDir = currentSourcePath.parentDir.parentDir.parentDir
  let conf = parseConfig(exampleDir / "config.yml")
  setRenderer proc(): VNode = renderLayout(conf)
