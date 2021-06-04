import karax / [karaxdsl, vdom]
import ./layout


proc PurePost*(title = ""; id = ""; date = ""; cates: seq[string] = @[]; tags: seq[string] = @[];
    child: VNode = nil): VNode =
  let post = buildHtml(tdiv()):
    h4:
      text title

    tdiv(class = "post-meta"):
      span:
        span(class = "far fa-calendar-alt", aria-hidden = "true")
        text date
    child
  PureLayout(post)

when isMainModule:
  import nmark, nmark / [mdToAst, def]
  import os
  import yaml, json
  import regex
  const sourceDir = currentSourcePath.parentDir.parentDir.parentDir / "source"
  const postDir = sourceDir / "posts"
  const filePath = postDir / "test_post1.md"
  const content = staticRead(postDir / "test_post1.md")
  let seqAst = content.mdToAst

  var prob = 0
  var pra: string
  # for i,node in seqAst:
  #   if prob == 2 and node.kind == BlockKind.containerBlock:
  #     echo repr node.children
  #   if node.kind == BlockKind.leafBlock:
  #     if (i == 0 or prob > 1) and node.leafType == thematicBreak :
  #       inc prob
  #     elif i == 1 and node.leafType == paragraph:
  #       pra = node.raw
  #       inc prob
  var m: RegexMatch
  let ret = content.find(re"(?ms:-{3,}(.*)-{3,})", m)
  let restContent = content[m.boundaries.b + 1 .. ^1]
  pra = m.group(0, content)[0]
  var meta: JsonNode = newJObject()

  var parser = initYamlParser(true)
  var ys = parser.parse(pra)
  meta = constructJson(ys)[0]
  echo meta

  let title = meta{"title"}.getStr("")
  let id = meta{"id"}.getStr("")
  var cates = newSeq[string]()
  for e in meta{"categories"}.getElems:
    cates.add e.getStr("")
  let date = meta{"date"}.getStr("")
  var tags = newSeq[string]()
  for e in meta{"tags"}.getElems:
    tags.add e.getStr("")
  let htmlContent = verbatim(restContent.markdown)
  setRenderer proc(): VNode = PurePost(title, id, date, cates, tags, child = htmlContent)
