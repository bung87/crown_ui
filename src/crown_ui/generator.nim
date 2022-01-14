
import std/[os, json, algorithm, strutils, times, sequtils, osproc, dynlib, tables]
import fusion / [htmlparser, htmlparser/xmltree]
import unicode except strip, escape
import karax / [vdom]
import ./ utils
import yaml, regex
import ./ datetime_utils
import ./config
import ./html_utils
import chronicles
import ./format_utils
import ./types
import ./io_utils
import uri
import segfaults
import sugar

const libThemeName = when defined(windows):
    "theme.dll"
  elif defined(macosx):
    "libtheme.dylib"
  else:
    "libtheme.so"

const MaxDescriptionLen = 200

type
  RenderPost = proc(conf: Config; data: PostMeta; child: VNode = nil): VNode {.gcsafe, cdecl.}
  RenderPostPartial = proc(conf: Config; data: PostMeta; child: VNode = nil): VNode {.gcsafe, cdecl.}
  RenderIndex = proc(conf: Config; posts: seq[VNode]; pagination: Pagination): VNode {.gcsafe, cdecl.}
  RenderPosts = proc(conf: Config; posts: seq[VNode]; pagination: Pagination): VNode {.gcsafe, cdecl.}
  RenderArchive = proc(conf: Config; archives: Table[int, seq[VNode]]): VNode{.gcsafe, cdecl.}
  RenderCategories = proc(conf: Config; posts: seq[VNode]): VNode{.gcsafe, cdecl.}
  RenderTag = proc(conf: Config; tagCount: Table[string, int]): VNode {.gcsafe, cdecl.}
  SplitMdResult = tuple
    meta: string
    content: string
  TplData = object
    title: string
    date: string

proc splitmd*(content: string): SplitMdResult =
  var m: RegexMatch
  let ret1 = content.find(re"-{3,}", m)
  let metaBegin = m.boundaries.b
  let ret2 = content.find(re"-{3,}", m, metaBegin)
  let metaEnd = m.boundaries.a
  result.meta = content[metaBegin + 1 ..< metaEnd]
  result.content = content[m.boundaries.b + 1 .. ^1]

proc getPostData*(filepath: string; sourceDir: string): PostMeta =
  ## filepath: post md file path
  ## sourceDir: sourceDir absolute path
  doAssert isAbsolute(sourceDir)
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

  result = (title: title, id: id, date: date, cates: cates, tags: tags, filepath: filepath,
      relpath: filepath.relativePath(sourceDir))

proc getContentNode*(pm: PostMeta): VNode =
  let content = readFile(pm.filepath)
  let splited = splitmd(content)
  result = verbatim(markdown2html(splited.content))

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


proc generatePriv(conf: JsonNode; tpl: string; title: string; cwd: string = getCurrentDir()): string =
  # let conf = parseConfig(cwd / "conf.yml")
  let dateFormat = conf{"date_format"}.getStr("YYYY-MM-DD")
  let scaffoldsDir = cwd / "scaffolds"
  if isMomentFormat(dateFormat):
    let date = now().format(conf.getDateTimeFormat())
    let postPath = scaffoldsDir / tpl & ".md"
    let data = TplData(title: title, date: date)
    result = scaffold2source(postPath, data)

proc generatePriv(tpl: string; title: string; cwd: string = getCurrentDir()): string =
  let conf = parseYamlConfig(cwd / "conf.yml")
  result = generatePriv(conf, tpl, title, cwd)

proc generate*(cwd = getCurrentDir(); dest = getCurrentDir() / "source" / "drafts"; tpl: seq[string]): int =
  ## generate new post or page
  let conf = parseConfig(cwd / "conf.yml")
  doAssert tpl.len > 0
  doAssert tpl[0] in ["post", "page"]
  let theTpl = tpl[0]
  let title = tpl[1]
  var privDest = dest
  if not dest.isRelativeTo(cwd):
    privDest = cwd / (if conf.source_dir.len > 0: conf.source_dir else: "source") / "drafts"
  let content = generatePriv(theTpl, title, cwd = expandTilde(cwd))
  writeFile(privDest / title & ".md", content)


proc generatePosts(conf: Config; libTheme: LibHandle; posts: seq[PostMeta]; cwd = getCurrentDir();
    dest = getCurrentDir() / "build"; cssHtml = "") =
  ## generate all posts
  var privDest = dest
  if not dest.isRelativeTo(cwd):
    privDest = cwd / "build"

  let renderPost = cast[RenderPost](libTheme.symAddr("renderPost"))
  doAssert renderPost != nil
  var
    name: string
    postNode: VNode
    textContent: string
    description: string
    content: string
    outfile: string
    contentNode: VNode
  for data in posts:
    contentNode = getContentNode(data)
    name = getPermalinkOf(data, conf)
    postNode = renderPost(conf, data, contentNode)
    if not dirExists(privDest / name):
      createDir(privDest / name)
    outfile = privDest / name / "index.html"
    info "Generate post", file = data.relpath, to = outfile.relativePath(cwd)
    textContent = innerText(contentNode, MaxDescriptionLen, @["pre", "code"]).replace('\n', ' ').strip()
    description = if textContent.len > 0: xmltree.escape(textContent) else: xmltree.escape(data.title)
    content = renderHtml($postNode, pageTitle = data.title & " | " & conf.title, title = data.title, url = "",
        siteName = conf.title, description = description, cssHtml = cssHtml)
    writeFile(outfile, content)

proc generateIndex(conf: Config; libTheme: LibHandle; posts: seq[PostMeta]; cwd = getCurrentDir();
    dest = getCurrentDir() / "build"; cssHtml = "") =
  ## generate posts index page
  var privDest = dest
  if not dest.isRelativeTo(cwd):
    privDest = cwd / "build"
  let homePageDir = privDest
  let index_generator = conf.index_generator
  if index_generator.path.len > 0:
    privDest = privDest / index_generator.path
  let renderPosts = cast[RenderPosts](libTheme.symAddr("renderPosts"))
  let renderIndex = cast[RenderIndex](libTheme.symAddr("renderIndex"))
  let renderPostsProc = if renderPosts == nil: renderIndex else: renderPosts
  doAssert renderPostsProc != nil
  doAssert renderIndex != nil
  let renderPostPartial = cast[RenderPostPartial](libTheme.symAddr("renderPostPartial"))
  doAssert renderPostPartial != nil

  let rootUrl = parseUri(conf.url)
  let prefix = rootUrl / index_generator.path / index_generator.pagination_dir
  let outDir = privDest / index_generator.pagination_dir

  let perPage = index_generator.per_page
  let postsLen = posts.len
  var m = postsLen mod perPage
  let pages = if m != 0: postsLen div perPage + 1 else: postsLen div perPage
  var i = 0
  var
    name: string
    postNode: VNode
    textContent: string
    description: string
    content: string
    outfile: string
    pagination: Pagination
    indexNode: VNode
    privOutDir: string
    pagePosts: seq[PostMeta]
  var postsNodes = newSeq[VNode]()
  while i < pages:
    pagePosts = posts[i * perPage ..< min(postsLen, (i + 1) * perPage)]
    name = if i == 0: "" else: $(i + 1)
    pagination = Pagination(pageSize: perPage, totalPages: pages, currentPage: i+1)
    privOutDir = if i == 0: privDest else: outDir
    postsNodes.setLen(0)
    for data in pagePosts:
      textContent = innerText(data.getContentNode(), MaxDescriptionLen, @["pre", "code"])
      let p = renderPostPartial(conf, data, verbatim(textContent))
      postsNodes.add p
    if renderPosts != nil and i == 0:
      # render homepage
      indexNode = renderIndex(conf, postsNodes, pagination)
      outfile = homePageDir / "index.html"
      info "Generate homepage", to = outfile.relativePath(cwd)
      description = xmltree.escape(conf.description)
      content = renderHtml($indexNode, pageTitle = conf.title, title = conf.title, url = conf.url,
          siteName = conf.title, description = description, cssHtml = cssHtml)
      writeFile(outfile, content)

    indexNode = renderPostsProc(conf, postsNodes, pagination)

    if not dirExists(privOutDir / name):
      createDir(privOutDir / name)
    outfile = privOutDir / name / "index.html"
    info "Generate posts page", page = i + 1, to = outfile.relativePath(cwd)
    description = xmltree.escape(conf.description)
    content = renderHtml($indexNode, pageTitle = conf.title, title = conf.title, url = $(prefix / name),
        siteName = conf.title, description = description, cssHtml = cssHtml)
    writeFile(outfile, content)
    inc i

proc generateArchive(conf: Config; libTheme: LibHandle; posts: seq[PostMeta]; cwd = getCurrentDir();
    dest = getCurrentDir() / "build"; cssHtml = "") =
  var privDest = dest
  if not dest.isRelativeTo(cwd):
    privDest = cwd / "build"

  let renderArchive = cast[RenderArchive](libTheme.symAddr("renderArchive"))
  doAssert renderArchive != nil
  let renderPostPartial = cast[RenderPostPartial](libTheme.symAddr("renderPostPartial"))
  doAssert renderPostPartial != nil
  let index_generator = conf.index_generator
  let rootUrl = parseUri(conf.url)
  let prefix = rootUrl / index_generator.path / index_generator.pagination_dir
  let outDir = privDest / conf.archive_dir / index_generator.pagination_dir

  let perPage = index_generator.per_page
  let postsLen = posts.len
  var m = postsLen mod perPage
  let pages = if m != 0: postsLen div perPage + 1 else: postsLen div perPage
  var i = 0
  var archives: Table[int, seq[VNode]]
  var
    name: string
    postNode: VNode
    textContent: string
    description: string
    content: string
    outfile: string
    pagePosts: seq[PostMeta]
    pagination: Pagination
    postNodes: seq[VNode]
    indexNode: VNode
    postPartialNode: VNode
    privOutDir: string
  while i < pages:
    pagePosts = posts[i * perPage ..< min(postsLen, (i + 1) * perPage)]
    name = if i == 0: "" else: $(i + 1)
    privOutDir = if i == 0: privDest / conf.archive_dir else: outDir
    for data in pagePosts:
      textContent = innerText(data.getContentNode(), MaxDescriptionLen, @["pre", "code"])
      let year = data.datetime(conf).year
      postNode = renderPostPartial(conf, data, verbatim(textContent))
      if archives.hasKey(year):
        archives[year].add postNode
      else:
        archives[year] = @[postNode]

    indexNode = renderArchive(conf, archives)

    if not dirExists(privOutDir / name):
      createDir(privOutDir / name)
    outfile = privOutDir / name / "index.html"
    info "Generate archive", page = i + 1, to = outfile.relativePath(cwd)
    description = xmltree.escape(conf.description)
    content = renderHtml($indexNode, pageTitle = conf.title, title = conf.title, url = $(prefix / name),
        siteName = conf.title, description = description, cssHtml = cssHtml)
    writeFile(outfile, content)
    archives.clear
    inc i

proc generateCategory(conf: Config; libTheme: LibHandle; posts: seq[PostMeta]; cwd = getCurrentDir();
    dest = getCurrentDir() / "build"; cssHtml = "") =
  ## generate categories
  var privDest = dest
  if not dest.isRelativeTo(cwd):
    privDest = cwd / "build"

  let renderCategories = cast[RenderCategories](libTheme.symAddr("renderCategories"))
  doAssert renderCategories != nil
  let renderPostPartial = cast[RenderPostPartial](libTheme.symAddr("renderPostPartial"))
  doAssert renderPostPartial != nil
  let index_generator = conf.index_generator
  let rootUrl = parseUri(conf.url)

  var catedPosts: Table[string, seq[PostMeta]]
  let defaultCate = conf.default_category
  for p in posts:
    if p.cates.len == 0:
      if catedPosts.hasKey(defaultCate):
        catedPosts[defaultCate].add p
      else:
        catedPosts[defaultCate] = @[p]
    else:
      for c in p.cates:
        if catedPosts.hasKey(c):
          catedPosts[c].add p
        else:
          catedPosts[c] = @[p]
  var
    name: string
    postNode: VNode
    textContent: string
    description: string
    content: string
    outfile: string
    pagePosts: seq[PostMeta]
    pagination: Pagination
    postNodes: seq[VNode]
    indexNode: VNode
    postPartialNode: VNode
    privOutDir: string

  for cate, posts in catedPosts:
    let prefix = rootUrl / conf.category_dir / cate / index_generator.pagination_dir
    let outDir = privDest / conf.category_dir / cate / index_generator.pagination_dir
    let perPage = index_generator.per_page
    let postsLen = posts.len
    var m = postsLen mod perPage
    let pages = if m != 0: postsLen div perPage + 1 else: postsLen div perPage
    var i = 0

    while i < pages:
      pagePosts = posts[i * perPage ..< min(postsLen, (i + 1) * perPage)]
      name = if i == 0: "" else: $(i + 1)
      privOutDir = if i == 0: privDest / conf.category_dir / cate else: outDir
      postNodes.setLen(0)
      for data in pagePosts:
        textContent = innerText(data.getContentNode(), MaxDescriptionLen, @["pre", "code"])
        postPartialNode = renderPostPartial(conf, data, verbatim(textContent))
        postNodes.add(postPartialNode)

      indexNode = renderCategories(conf, postNodes)
      if not dirExists(privOutDir / name):
        createDir(privOutDir / name)
      outfile = privOutDir / name / "index.html"
      info "Generate category", page = i + 1, to = outfile.relativePath(cwd)
      description = xmltree.escape(conf.description)
      content = renderHtml($indexNode, pageTitle = conf.title, title = conf.title, url = $(prefix / name),
          siteName = conf.title, description = description, cssHtml = cssHtml)
      writeFile(outfile, content)
      inc i

proc generateTag(conf: Config; libTheme: LibHandle; posts: seq[PostMeta]; cwd = getCurrentDir();
    dest = getCurrentDir() / "build"; cssHtml = "") =
  ## generate tag page
  var privDest = dest
  if not dest.isRelativeTo(cwd):
    privDest = cwd / "build"

  let renderPostPartial = cast[RenderPostPartial](libTheme.symAddr("renderPostPartial"))
  doAssert renderPostPartial != nil
  let index_generator = conf.index_generator
  let rootUrl = parseUri(conf.url)

  var tagedPosts: Table[string, seq[PostMeta]]
  let renderPosts = cast[RenderPosts](libTheme.symAddr("renderPosts"))
  let renderIndex = cast[RenderIndex](libTheme.symAddr("renderIndex"))
  let renderPostsProc = if renderPosts == nil: renderIndex else: renderPosts
  var tagCount: Table[string, int]

  for p in posts:
    for c in p.tags:
      if tagedPosts.hasKey(c):
        tagCount[c] = tagCount[c] + 1
        tagedPosts[c].add p
      else:
        tagCount[c] = 1
        tagedPosts[c] = @[p]
  # generate tag index
  let renderTag = cast[RenderTag](libTheme.symAddr("renderTag"))
  let prefix = rootUrl / conf.tag_dir
  let outDir = privDest / conf.tag_dir
  let indexNode = renderTag(conf, tagCount)
  if not dirExists(outDir):
    createDir(outDir)
  let outfile = outDir / "index.html"
  info "Generate tag index", to = outfile.relativePath(cwd)
  let description = xmltree.escape(conf.description)
  let content = renderHtml($indexNode, pageTitle = conf.title, title = conf.title, url = $prefix,
      siteName = conf.title, description = description, cssHtml = cssHtml)
  writeFile(outfile, content)
  block generateTagedPosts:
    var
      name: string
      postNode: VNode
      textContent: string
      description: string
      content: string
      outfile: string
      pagePosts: seq[PostMeta]
      pagination: Pagination
      postNodes: seq[VNode]
      indexNode: VNode
      postPartialNode: VNode
      privOutDir: string
    for tag, posts in tagedPosts:
      let prefix = rootUrl / conf.tag_dir / tag / index_generator.pagination_dir
      let outDir = privDest / conf.tag_dir / tag / index_generator.pagination_dir
      let perPage = index_generator.per_page
      let postsLen = posts.len
      var m = postsLen mod perPage
      let pages = if m != 0: postsLen div perPage + 1 else: postsLen div perPage
      var i = 0

      while i < pages:
        pagePosts = posts[i * perPage ..< min(postsLen, (i + 1) * perPage)]
        name = if i == 0: "" else: $(i + 1)
        pagination = Pagination(pageSize: perPage, totalPages: pages, currentPage: i+1)
        privOutDir = if i == 0: privDest / conf.category_dir / tag else: outDir

        postNodes.setLen(0)
        for data in pagePosts:
          textContent = innerText(data.getContentNode(), MaxDescriptionLen, @["pre", "code"])
          postPartialNode = renderPostPartial(conf, data, verbatim(textContent))
          postNodes.add(postPartialNode)

        indexNode = renderPostsProc(conf, postNodes, pagination)
        if not dirExists(privOutDir / name):
          createDir(privOutDir / name)
        outfile = privOutDir / name / "index.html"
        info "Generate tag", tage = tag, page = i + 1, to = outfile.relativePath(cwd)
        description = xmltree.escape(conf.description)
        content = renderHtml($indexNode, pageTitle = conf.title, title = conf.title, url = $(prefix / name),
            siteName = conf.title, description = description, cssHtml = cssHtml)
        writeFile(outfile, content)
        inc i

proc compileTheme(cwd, themeFile: string; themePath: string) =
  info "Theme", status = "Compiling", file = themeFile.relativePath(cwd)
  let cmd = "nim c -d:createNimRtl " & (when defined(release): "-d:release" else: "") &
      " --app:lib --verbosity:0 --hints:off -w:off " & themeFile
  let r = execCmdEx(cmd)
  if r.exitCode != 0:
    info "Theme", status = "Compile Error", msg = r.output, file = themeFile.relativePath(cwd)
    removeFile(themePath)
    quit(1)
  info "Theme", status = "Compiled", file = themeFile.relativePath(cwd)

proc build*(cwd = getCurrentDir()): int =
  ## generate static site
  result = 1
  let conf = parseConfig(cwd / "config.yml")
  let metaPath = cwd / "crown_ui.json"
  let theme = if conf.theme.len > 0: conf.theme else: "default"
  # compile theme
  let themesDir = cwd / "themes"
  if not dirExists(themesDir):
    createDir(themesDir)
  let themeDir = themesDir / theme
  const builtinThemesDir = currentSourcePath.parentDir / "themes"
  if dirExists(builtinThemesDir / theme):
    copyDir(builtinThemesDir / theme, themesDir / theme)
  let themeFile = themeDir / "theme.nim"
  let themePath = themeDir / libThemeName
  var needCompileTheme = false
  var dirver: string
  if fileExists(metaPath):
    let meta = json.parseFile(metaPath).to(CrownMeta)
    if meta.theme.name != theme:
      needCompileTheme = true
    else:
      dirver = computeDirVersion(themeDir & "/*.nim")
      if dirver != meta.theme.hash:
        needCompileTheme = true
  else:
    needCompileTheme = true

  if not fileExists(themePath):
    needCompileTheme = true
  info "Theme", status = "version", need_compile = needCompileTheme, ver = dirver
  if needCompileTheme:
    if dirver.len == 0:
      dirver = computeDirVersion(themeDir & "/*.nim")
    writeFile(metaPath, $ %* CrownMeta(theme: ThemeMeta(name: theme, hash: dirver)))
    compileTheme(cwd, themeFile, themePath)
  let libTheme = loadLib(themePath)
  doAssert libTheme != nil
  var cssHtml = ""
  if fileExists(themeDir / "css.html"):
    cssHtml = readFile(themeDir / "css.html")
  let sourceDir = (if conf.source_dir.len > 0: conf.source_dir else: "source") / "posts"
  let sources = cwd / sourceDir / "*.md"
  var posts = newSeq[PostMeta]()
  for f in walkFiles(sources):
    posts.add getPostData(f, absolutePath cwd / sourceDir)
  echo posts.len
  proc cmpPostDate(x, y: PostMeta): int =
    cmp(x.datetime(conf).toTime.toUnix, y.datetime(conf).toTime.toUnix)
  sort(posts, cmpPostDate, SortOrder.Descending)
  # generatePosts(conf, libTheme, posts, cwd = cwd, cssHtml = cssHtml)
  generateIndex(conf, libTheme, posts, cwd = cwd, cssHtml = cssHtml)
  echo posts.len
  generateArchive(conf, libTheme, posts, cwd = cwd, cssHtml = cssHtml)
  generateCategory(conf, libTheme, posts, cwd = cwd, cssHtml = cssHtml)
  generateTag(conf, libTheme, posts, cwd = cwd, cssHtml = cssHtml)
  unloadLib(libTheme)
  result = 0

when isMainModule:
  # const exampleDir = currentSourcePath.parentDir.parentDir.parentDir / "example"
  # echo exampleDir
  let exampleDir = "/Users/bung/mine-blog"
  discard build(exampleDir)
