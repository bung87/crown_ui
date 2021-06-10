
import karax / [vdom]
import ./ utils
import yaml, json
import regex
import tables
import os, strutils, times
import ./ datetime_utils
import dynlib
import ./config
import ./html_utils
import osproc
import chronicles
import ./format_utils
import ./types
import fusion / [htmlparser, htmlparser/xmltree]
import unicode except strip, escape
import sequtils

const libThemeName = when defined(windows):
    "theme.dll"
  elif defined(macosx):
    "libtheme.dylib"
  else:
    "libtheme.so"

const MaxDescriptionLen = 200

type
  RenderPost = proc(config: Config; id = ""; title = ""; date = ""; cates: seq[string] = @[]; tags: seq[string] = @[];
    child: VNode = nil): VNode {.gcsafe, stdcall.}

  SplitMdResult = tuple
    meta: string
    content: string
  TplData = object
    title: string
    date: string

proc splitmd*(content: string): SplitMdResult =
  var m: RegexMatch
  let ret = content.find(re"(?ms:-{3,}(.*)-{3,})", m)
  if not ret:
    result.content = content
    return result
  result.content = content[m.boundaries.b + 1 .. ^1]
  result.meta = m.group(0, content)[0]

proc getPostData*(filepath: string; base: string): PostData =
  doAssert isAbsolute(base)
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
  result = (title: title, id: id, date: date, cates: cates, tags: tags, child: child, filepath: filepath,
      relpath: filepath.relativePath(base))

proc parseUntil(s: string; until: string; start = 0): int =
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

proc scaffold2source*(path: string; data: TplData): string =
  let content = readFile(path)
  let splited = splitMd(content)
  let bounds = getBounds(splited.meta)
  var r = splited.meta
  for k, v in data.fieldPairs:
    for b in bounds:
      if k == splited.meta[b].strip:
        r = replace(r, "{{" & splited.meta[b] & "}}", v)
  result = "---" & r & "---" & splited.content


proc generatePriv(config: JsonNode; tpl: string; title: string; cwd: string = getCurrentDir()): string =
  # let config = parseConfig(cwd / "config.yml")
  let dateFormat = config{"date_format"}.getStr("YYYY-MM-DD")
  let scaffoldsDir = cwd / "scaffolds"
  if isMomentFormat(dateFormat):
    let date = now().format(toNimFormat(dateFormat))
    let postPath = scaffoldsDir / tpl & ".md"
    let data = TplData(title: title, date: date)
    result = scaffold2source(postPath, data)

proc generatePriv(tpl: string; title: string; cwd: string = getCurrentDir()): string =
  let config = parseYamlConfig(cwd / "config.yml")
  result = generatePriv(config, tpl, title, cwd)

proc generate(config: Config; cwd = getCurrentDir(); dest = getCurrentDir() / "source" / "drafts"; tpl: seq[string]): int =
  ## generate new post or page
  doAssert tpl.len > 0
  doAssert tpl[0] in ["post", "page"]
  let theTpl = tpl[0]
  let title = tpl[1]
  var privDest = dest
  if not dest.isRelativeTo(cwd):
    privDest = cwd / (if config.source_dir.len > 0: config.source_dir else: "source") / "drafts"
  let content = generatePriv(theTpl, title, cwd = expandTilde(cwd))
  writeFile(privDest / title & ".md", content)

proc myInnerText*(n: XmlNode): string =
  ## Gets the inner text of `n`:
  proc worker(res: var string; n: XmlNode) =
    case n.kind
    of xnText, xnEntity:
      res.add(n.text)
    of xnElement:
      if n.tag notin ["pre", "code"]:
        for sub in n:
          worker(res, sub)
    else:
      discard

  result = ""
  worker(result, n)

proc generatePosts(config: Config; libTheme: LibHandle; cwd = getCurrentDir(); dest = getCurrentDir() / "build") =
  var privDest = dest
  if not dest.isRelativeTo(cwd):
    privDest = cwd / "build"
  let sourceDir = (if config.source_dir.len > 0: config.source_dir else: "source") / "posts"
  let sources = cwd / sourceDir / "*.md"
  let render = cast[RenderPost](libTheme.symAddr("renderPost"))
  doAssert render != nil
  for f in walkFiles(sources):
    let data = getPostData(f, cwd / sourceDir)
    let name = getPermalinkOf(data, config.permalink, config)
    let post = render(config, data.id, data.title, data.date, data.cates, data.tags, data.child)
    if not dirExists(privDest / name):
      createDir(privDest / name)
    let outfile = privDest / name / "index.html"
    info "Generate post", file = f.relativePath(cwd), to = outfile.relativePath(cwd)
    var textContent = myInnerText(parseHtml($data.child)).replace('\n', ' ').strip()
    var runes = if textContent.len > 0: textContent.toRunes() else: data.title.toRunes()
    let runeLen = runes.len
    let b = min(MaxDescriptionLen, runeLen)
    let description = if textContent.len > 0: xmltree.escape($runes[0 ..< b]) else: xmltree.escape($runes[0 ..< b])
    let content = renderHtml($post, pageTitle = data.title & " | " & config.title, title = data.title, url = "",
        siteName = config.title, description = description)
    writeFile(outfile, content)

proc build(cwd = getCurrentDir()): int =
  ## generate static site
  result = 1
  let config = parseConfig(cwd / "config.yml")
  let theme = if config.theme.len > 0: config.theme else: "default"
  # compile theme
  let themeFile = cwd / "themes" / theme / "theme.nim"
  info "Theme", status = "Compiling", file = themeFile.relativePath(cwd)
  doAssert execCmdEx("nim c -d:release --app:lib " & themeFile).exitCode == 0
  let themePath = cwd / "themes" / theme / libThemeName
  info "Theme", status = "Compiled", file = themeFile.relativePath(cwd)
  let libTheme = loadLib(themePath)
  doAssert libTheme != nil
  generatePosts(config, libTheme, cwd)
  unloadLib(libTheme)
  result = 0

when isMainModule:
  when defined(release):
    import cligen
    dispatchMulti([
      build,
      help = {"cwd": "current working directory"}
      ],
      [
      generate,
      cmdName = "new",
      help = {"tpl": "template"}
      ]
      )
  else:

    const exampleDir = currentSourcePath.parentDir.parentDir.parentDir / "example"
    # discard generate(cwd = exampleDir, tpl = @["post", "tt"])
    discard build(exampleDir)


