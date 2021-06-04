import karax / [karaxdsl, vdom]
import ./layout
import packages/docutils/highlite
import packages/docutils/rstgen
import strutils
include nmark #, nmark / [mdToAst,astToHtml, def]
include nmark / insertMarker
import htmlgen
proc PurePost*(title = ""; id = ""; date = ""; cates: seq[string] = @[]; tags: seq[string] = @[];
    child: VNode = nil): VNode =
  let post = buildHtml(tdiv(data-theme = "dark")):
    h4:
      text title

    tdiv(class = "post-meta"):
      span:
        span(class = "far fa-calendar-alt", aria-hidden = "true")
        text date
    child
  PureLayout(post)

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

proc markdown2html(lines: string): string =
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

when isMainModule:

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
  let htmlContent = verbatim(markdown2html(restContent))
  setRenderer proc(): VNode = PurePost(title, id, date, cates, tags, child = htmlContent)
