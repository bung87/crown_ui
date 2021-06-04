
import karax / [vdom]
import ./ utils
import yaml, json
import regex
import tables

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

proc getPostData*(filepath: string): PostData =
  let content = readFile(filepath)
  var prob = 0
  var pra: string

  var m: RegexMatch
  let ret = content.find(re"(?ms:-{3,}(.*)-{3,})", m)
  if not ret:
    return result
  let restContent = content[m.boundaries.b + 1 .. ^1]
  pra = m.group(0, content)[0]
  var meta: JsonNode = newJObject()

  var parser = initYamlParser(true)
  var ys = parser.parse(pra)
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
  let child = verbatim(markdown2html(restContent))
  result = (title: title, id: id, date: date, cates: cates, tags: tags, child: child)
