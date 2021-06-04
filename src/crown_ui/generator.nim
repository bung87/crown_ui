
import karax / [vdom]
import ./ utils
import yaml, json
import regex
import tables
import os, strutils

type PostData = tuple
  title: string
  id: string
  date: string
  cates: seq[string]
  tags: seq[string]
  child: VNode

type Link* = object
  href*: string
  title*: string

proc getMenu*(config: JsonNode): seq[Link] =
  let menuNode = config["menu"].getFields
  for k, v in menuNode.pairs:
    result.add Link(href: v.getStr(), title: k)

type SplitMdResult = tuple
  meta: string
  content: string

proc splitmd*(content: string): SplitMdResult =
  var m: RegexMatch
  let ret = content.find(re"(?ms:-{3,}(.*)-{3,})", m)
  if not ret:
    result.content = content
    return result
  result.content = content[m.boundaries.b + 1 .. ^1]
  result.meta = m.group(0, content)[0]

proc getPostData*(filepath: string): PostData =
  let content = readFile(filepath)
  let splited = splitmd(content)
  var meta: JsonNode = newJObject()
  var parser = initYamlParser(true)
  var ys = parser.parse(splited.meta)
  meta = constructJson(ys)[0]
  let title = meta{"title"}.getStr("")
  let id = meta{"id"}.getStr("")
  var cates = newSeq[string]()
  for e in meta{"categories"}.getElems:
    cates.add e.getStr("")
  let date = meta{"date"}.getStr("")
  var tags = newSeq[string]()
  for e in meta{"tags"}.getElems:
    tags.add e.getStr("")
  let child = verbatim(markdown2html(splited.content))
  result = (title: title, id: id, date: date, cates: cates, tags: tags, child: child)

proc build(cwd = getCurrentDir(), theme = "default"): int =
  ## generate static site
  result = 1 # Of course, real code would have real work here

type TplData = object
  title: string
  date: string

proc parseUntil(s: string, until: string, start = 0): int =
  var i = start
  while i < s.len:
    if until.len > 0 and s[i] == until[0]:
      var u = 1
      while i+u < s.len and u < until.len and s[i+u] == until[u]:
        inc u
      if u >= until.len: break
    inc(i)
  result = i - start

proc getBounds(meta: string): seq[Slice[int]] =
  var i = 0
  let l = meta.len
  while i < l:
    let start = i
    let ll = meta.parseUntil("{{", i)
    if ll == 0:
      break
    i.inc ll + 2
    let ll2 = meta.parseUntil("}}", i)
    if ll2 == 0:
      break
    i.inc ll2
    result.add (start + ll + 2) ..< i

proc scaffold2source*(path: string, data: TplData): string =
  let content = readFile(path)
  let splited = splitMd(content)
  let bounds = getBounds(splited.meta)
  var r = splited.meta
  for k, v in data.fieldPairs:
    for b in bounds:
      if k == splited.meta[b].strip:
        r = replace(r, "{{" & splited.meta[b] & "}}", v)
  result = "---" & r & "---" & splited.content

proc generate(tpl: seq[string]): int =
  ## generate new post or page
  doAssert tpl.len > 0
  doAssert tpl[0] in ["post", "page"]
  let theTpl = tpl[0]
  let title = tpl[1]
  discard

when isMainModule:
  when defined(release):
    import cligen
    dispatchMulti([
      build,
      help = {"cwd": "current working directory", "theme": "theme"}
      ],
      [
      generate,
      cmdName = "new",
      help = {"tpl": "template"}
      ]
      )
  else:

    const exampleDir = currentSourcePath.parentDir.parentDir.parentDir / "example"
    const scaffoldsDir = exampleDir / "scaffolds"
    let postPath = scaffoldsDir / "post.md"
    let data = TplData(title: "a", date: "2020")
    echo scaffold2source(postPath, data)

