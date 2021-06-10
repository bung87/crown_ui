import karax / [karaxdsl, vdom]
import ./layout
import crown_ui/config
import crown_ui/types
import crown_ui/format_utils

proc renderPostPartial*(conf: Config; data: PostData;
    child: VNode = nil): VNode {.cdecl, exportc, dynlib.} =
  doAssert conf != nil
  result = buildHtml(tdiv(data-theme = "dark")):
    h4:
      a(href = getPermalinkOf(data, conf)):
        text data.title
    tdiv(class = "post-meta"):
      span:
        span(class = "far fa-calendar-alt", aria-hidden = "true")
        text data.date
    child

proc renderPost*(config: Config; data: PostData;
    child: VNode = nil): VNode {.cdecl, exportc, dynlib.} =
  let post = renderPostPartial(config, data, child)
  result = renderLayout(config, post)

when isMainModule:
  import os
  import crown_ui / [generator]
  const exampleDir = currentSourcePath.parentDir.parentDir.parentDir
  let conf = parseConfig(exampleDir / "config.yml")
  const sourceDir = exampleDir / "source"
  const postDir = sourceDir / "posts"
  const filePath = postDir / "test_post1.md"
  let data = getPostData(filePath, postDir)
  setRenderer proc(): VNode = renderPost(conf, data, data.child)
