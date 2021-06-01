import karax / [karaxdsl, vdom]
import ./layout


proc PurePost*(title: string = ""; n: VNode = nil): VNode =
  let post = buildHtml(tdiv())
  PureLayout(post)

when isMainModule:
  import nmark / [mdToAst, def]
  import os
  import yaml, json
  const sourceDir = currentSourcePath.parentDir.parentDir.parentDir / "source"
  const postDir = sourceDir / "posts"
  const filePath = postDir / "test_post1.md"
  const content = staticRead(postDir / "test_post1.md")
  let seqAst = content.mdToAst


  for node in seqAst:
    if node.kind == BlockKind.leafBlock:
      if node.leafType == paragraph:
        var parser = initYamlParser(true)
        var ys = parser.parse(node.raw)
        echo constructJson(ys)[0]
  setRenderer proc(): VNode = PurePost()
