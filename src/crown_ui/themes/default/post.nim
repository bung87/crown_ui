import karax / [karaxdsl, vdom]
import ./layout
import crown_ui/config
import crown_ui/types
import crown_ui/format_utils

proc renderPostPartial*(conf: Config; data: PostMeta;
    child: VNode = nil): VNode =
  doAssert conf != nil
  result = buildHtml(tdiv(data-theme = "dark")):
    h4:
      a(href = data.permalink):
        text data.title
    tdiv(class = "post-meta"):
      span:
        span(class = "far fa-calendar-alt", aria-hidden = "true")
        text data.date
    child

proc renderPost*(conf: Config; data: PostMeta;
    child: VNode = nil): VNode  =
  let post = renderPostPartial(conf, data, child)
  result = renderLayout(conf, post)

when isMainModule:
  import os
  import crown_ui / [generator]
  
  import crown_ui/gen_macros
  const exampleDir = currentSourcePath.parentDir.parentDir.parentDir
  let conf = parseConfig(exampleDir / "config.yml")
  const sourceDir = exampleDir / "source"
  const postDir = sourceDir / "posts"
  const filePath = postDir / "Under development.md"
  let data = getPostData(filePath, postDir)
  setRenderer proc(): VNode = renderPost(conf, data, data.child)
