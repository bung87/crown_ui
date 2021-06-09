import karax / [karaxdsl, vdom]
import ./layout

proc PurePost*(id = ""; title = ""; date = ""; cates: seq[string] = @[]; tags: seq[string] = @[];
    child: VNode = nil): VNode {.cdecl, exportc, dynlib.} =
  let post = buildHtml(tdiv(data-theme = "dark")):
    h4:
      text title
    tdiv(class = "post-meta"):
      span:
        span(class = "far fa-calendar-alt", aria-hidden = "true")
        text date
    child
  PureLayout(post)

when isMainModule:
  import os
  import crown_ui / [generator]

  const sourceDir = currentSourcePath.parentDir.parentDir.parentDir / "source"
  const postDir = sourceDir / "posts"
  const filePath = postDir / "test_post1.md"
  let data = getPostData(filePath)
  setRenderer proc(): VNode = PurePost(data.id, data.title, data.date, data.cates, data.tags, data.child)
