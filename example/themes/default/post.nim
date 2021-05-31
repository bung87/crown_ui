import karax / [karaxdsl, vdom]
import ./layout

proc PurePost*(title: string = ""; n: VNode = nil): VNode =
  let post = buildHtml(tdiv())
  PureLayout(post)

when isMainModule:
  setRenderer proc(): VNode = PurePost()
