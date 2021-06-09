# head
# body 
  # header
  # main
  # side 
  # footer

import karax / [karaxdsl, vdom]
import os, json
# from karax/ karax import setRenderer
import crown_ui / [utils]

import partial / [header, footer]
const exampleDir = currentSourcePath.parentDir.parentDir.parentDir

proc renderLayout*(n: VNode = nil): VNode =
  # const configPath = exampleDir / "config.yml"
  # let config = parseConfig(configPath)

  result = buildHtml(tdiv):
    # PureHeader(title = config["title"].getStr(), menu = getMenu(config))
    PureHeader()
    tdiv(class = "content"):
      tdiv(class = "pure-g"):
        tdiv(class = "pure-u-18-24"):
          if n != nil: n else: discard

        tdiv(class = "pure-u-6-24")
    PureFooter()

when isMainModule:
  setRenderer proc(): VNode = renderLayout()

