import yaml, streams
import json
import packages/docutils/highlite
import packages/docutils/rstgen
import strutils
include nmark
include nmark / insertMarker
import htmlgen
import tables

proc parseYaml*(s: Stream): seq[JsonNode] =
  var parser = initYamlParser(true)
  var ys = parser.parse(s)
  result = constructJson(ys)

proc parseYaml*(s: string): seq[JsonNode] =
  var parser = initYamlParser(true)
  var ys = parser.parse(s)
  result = constructJson(ys)

proc parseConfig*(path: string): JsonNode =
  let s = readFile path
  let res = parseYaml(s)
  result = if res.len > 0: res[0] else: newJObject()


proc dispA(target: OutputTarget; dest: var string;
           xml, tex: string; args: varargs[string]) =
  if target != outLatex: addf(dest, xml, args)
  else: addf(dest, tex, args)

proc renderCodeLang*(result: var string; lang: SourceLanguage; code: string;
                     target: OutputTarget) =
  var g: GeneralTokenizer
  initGeneralTokenizer(g, code)
  while true:
    getNextToken(g, lang)
    case g.kind
    of gtEof: break
    of gtNone, gtWhitespace:
      add(result, substr(code, g.start, g.length + g.start - 1))
    else:
      dispA(target, result, "<span class=\"$2\">$1</span>", "\\span$2{$1}", [
        esc(target, substr(code, g.start, g.length+g.start-1)),
        tokenClassToStr[g.kind]])
  deinitGeneralTokenizer(g)

proc markdown2html*(lines: string): string =
  let seqAst = lines.mdToAst

  var linkSeq: seq[Block]
  for e in seqAst:
    if e.kind == BlockKind.linkRef:
      linkSeq.add(e)
    elif e.kind == BlockKind.containerBlock:
      for c in e.children:
        if c.kind == BlockKind.linkRef:
          linkSeq.add(c)
    else:
      continue
  var isTight = false
  for ast in seqAst:
    case ast.kind
      of fencedCode:
        if ast.codeText == "":
          if ast.codeAttr != "":
            var code: string
            renderCodeLang(code, getSourceLanguage(ast.codeAttr.insertInline(linkSeq)), ast.codeText,
                OutputTarget.outHtml)
            var t = pre(class = "highlight", code(code)) & "\p"
            result.add t.replace("<code>", "<code class=\"language-" & ast.codeAttr.insertInline(linkSeq) & "\">")
          else:
            var code: string
            renderCodeLang(code, getSourceLanguage(ast.codeAttr.insertInline(linkSeq)), ast.codeText,
                OutputTarget.outHtml)
            result.add pre(class = "highlight", code(code)) & "\p"

        else:
          if ast.codeAttr != "":
            var code: string
            renderCodeLang(code, getSourceLanguage(ast.codeAttr.insertInline(linkSeq)), ast.codeText,
                OutputTarget.outHtml)
            var t = pre(class = "highlight", code(code & "\p")) & "\p"
            result.add t.replace("<code>", "<code class=\"language-" & ast.codeAttr.insertInline(linkSeq) & "\">")
          else:
            var code: string
            renderCodeLang(code, getSourceLanguage(ast.codeAttr.insertInline(linkSeq)), ast.codeText,
                OutputTarget.outHtml)
            result.add pre(class = "highlight", code(code & "\p")) & "\p"
      else:
        result.add(ast.astToHtml(isTight, linkseq))

  return result

type Link* = object
  href*: string
  title*: string

proc getMenu*(config: JsonNode): seq[Link] =
  let menuNode = config["menu"].getFields
  for k, v in menuNode.pairs:
    result.add Link(href: v.getStr(), title: k)
