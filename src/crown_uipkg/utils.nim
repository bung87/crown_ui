import json
import packages/docutils/highlite
import packages/docutils/rstgen
import strutils
include nmark
include nmark / insertMarker
import htmlgen
import nyml

proc parseYamlConfigFile*(path: string): JsonNode =
  let s = readFile path
  var yml = Nyml.init(contents = s)
  result = yml.toJson().contents

proc parseYamlConfig*(s: string): JsonNode =
  var yml = Nyml.init(contents = s)
  result = yml.toJson().contents


proc dispA(target: OutputTarget; dest: var string;
           xml, tex: string; args: varargs[string]) =
  if target != outLatex: addf(dest, xml, args)
  else: addf(dest, tex, args)

proc renderCodeLang*(result: var string; lang: SourceLanguage; code: string;
                     target: OutputTarget) =
  if lang == SourceLanguage.langNone:
    result = code
    return
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
        let lang = getSourceLanguage(ast.codeAttr.insertInline(linkSeq))
        if ast.codeText == "":
          if ast.codeAttr != "":
            var code: string
            renderCodeLang(code, lang, ast.codeText,
                OutputTarget.outHtml)
            var t = pre(class = "highlight", code(code)) & "\p"
            result.add t.replace("<code>", "<code class=\"language-" & ast.codeAttr.insertInline(linkSeq) & "\">")
          else:
            var code: string
            renderCodeLang(code, lang, ast.codeText,
                OutputTarget.outHtml)
            result.add pre(class = "highlight", code(code)) & "\p"

        else:
          if ast.codeAttr != "":
            var code: string
            renderCodeLang(code, lang, ast.codeText,
                OutputTarget.outHtml)
            var t = pre(class = "highlight", code(code & "\p")) & "\p"
            result.add t.replace("<code>", "<code class=\"language-" & ast.codeAttr.insertInline(linkSeq) & "\">")
          else:
            var code: string
            renderCodeLang(code, lang, ast.codeText,
                OutputTarget.outHtml)
            result.add pre(class = "highlight", code(code & "\p")) & "\p"
      else:
        result.add(ast.astToHtml(isTight, linkseq))

  return result

