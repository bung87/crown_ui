# head
# body 
  # header
  # main
  # side 
  # footer

import karax / [karaxdsl, vdom]
import os, json
# from karax/ karax import setRenderer
import crown_ui / [config, utils]

import partial / [header, footer]

proc renderLayout*(config: Config; n: VNode = nil): VNode =
  result = buildHtml(tdiv):
    PureHeader(config)
    tdiv(class = "content"):
      tdiv(class = "pure-g"):
        tdiv(class = "pure-u-18-24"):
          if n != nil: n else: discard
        tdiv(class = "pure-u-6-24")
    PureFooter(config)

when isMainModule:
  const exampleDir = currentSourcePath.parentDir.parentDir.parentDir
  let conf = parseConfig(exampleDir / "config.yml")
  setRenderer proc(): VNode = renderLayout(conf)

