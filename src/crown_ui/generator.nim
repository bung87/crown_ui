
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
  RenderPost = proc(config: Config; data: PostData; child: VNode = nil): VNode {.gcsafe, stdcall.}
  RenderPostPartial = proc(config: Config; data: PostData; child: VNode = nil): VNode {.gcsafe, stdcall.}
  RenderIndex = proc(config: Config; posts: seq[VNode]; pagination: Pagination): VNode {.gcsafe, stdcall.}
  RenderPosts = proc(config: Config; posts: seq[VNode]; pagination: Pagination): VNode {.gcsafe, stdcall.}
  RenderArchive = proc(config: Config; archives: Table[int, seq[VNode]]): VNode{.gcsafe, stdcall.}
  RenderCategories = proc(config: Config; posts: seq[VNode]): VNode{.gcsafe, stdcall.}
  RenderTag = proc(config: Config; tagCount: Table[string, int]): VNode {.gcsafe, stdcall.}
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

proc getPostData*(filepath: string; sourceDir: string): PostData =
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
  let child = verbatim(markdown2html(splited.content))
  result = (title: title, id: id, date: date, cates: cates, tags: tags, child: child, filepath: filepath,
      relpath: filepath.relativePath(sourceDir))

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
    let date = now().format(config.getDateTimeFormat())
    let postPath = scaffoldsDir / tpl & ".md"
    let data = TplData(title: title, date: date)
    result = scaffold2source(postPath, data)

proc generatePriv(tpl: string; title: string; cwd: string = getCurrentDir()): string =
  let config = parseYamlConfig(cwd / "config.yml")
  result = generatePriv(config, tpl, title, cwd)

proc generate*(cwd = getCurrentDir(); dest = getCurrentDir() / "source" / "drafts"; tpl: seq[string]): int =
  ## generate new post or page
  let config = parseConfig(cwd / "config.yml")
  doAssert tpl.len > 0
  doAssert tpl[0] in ["post", "page"]
  let theTpl = tpl[0]
  let title = tpl[1]
  var privDest = dest
  if not dest.isRelativeTo(cwd):
    privDest = cwd / (if config.source_dir.len > 0: config.source_dir else: "source") / "drafts"
  let content = generatePriv(theTpl, title, cwd = expandTilde(cwd))
  writeFile(privDest / title & ".md", content)


proc generatePosts(config: Config; libTheme: LibHandle; posts: seq[PostData]; cwd = getCurrentDir();
    dest = getCurrentDir() / "build"; cssHtml = "") =
  ## generate all posts
  var privDest = dest
  if not dest.isRelativeTo(cwd):
    privDest = cwd / "build"

  let renderPost = cast[RenderPost](libTheme.symAddr("renderPost"))
  doAssert renderPost != nil
  for data in posts:
    # let data = getPostData(f, cwd / sourceDir)
    let name = getPermalinkOf(data, config)
    let post = renderPost(config, data, data.child)
    if not dirExists(privDest / name):
      createDir(privDest / name)
    let outfile = privDest / name / "index.html"
    info "Generate post", file = data.relpath, to = outfile.relativePath(cwd)
    let textContent = innerText(data.child, MaxDescriptionLen, @["pre", "code"]).replace('\n', ' ').strip()
    let description = if textContent.len > 0: xmltree.escape(textContent) else: xmltree.escape(data.title)
    let content = renderHtml($post, pageTitle = data.title & " | " & config.title, title = data.title, url = "",
        siteName = config.title, description = description, cssHtml = cssHtml)
    writeFile(outfile, content)

proc generateIndex(config: Config; libTheme: LibHandle; posts: seq[PostData]; cwd = getCurrentDir();
    dest = getCurrentDir() / "build"; cssHtml = "") =
  ## generate posts index page
  var privDest = dest
  if not dest.isRelativeTo(cwd):
    privDest = cwd / "build"
  let homePageDir = privDest
  let index_generator = config.index_generator
  if index_generator.path.len > 0:
    privDest = privDest / index_generator.path
  let renderPosts = cast[RenderPosts](libTheme.symAddr("renderPosts"))
  let renderIndex = cast[RenderIndex](libTheme.symAddr("renderIndex"))
  let renderPostsProc = if renderPosts == nil: renderIndex else: renderPosts
  doAssert renderIndex != nil
  let renderPostPartial = cast[RenderPostPartial](libTheme.symAddr("renderPostPartial"))
  doAssert renderPostPartial != nil

  let rootUrl = parseUri(config.url)
  let prefix = rootUrl / index_generator.path / index_generator.pagination_dir
  let outDir = privDest / index_generator.pagination_dir

  let perPage = index_generator.per_page
  let postsLen = posts.len
  var m = postsLen mod perPage
  let pages = if m != 0: postsLen div perPage + 1 else: postsLen div perPage
  var i = 0
  while i < pages:
    let pagePosts = posts[i * perPage ..< min(postsLen, (i + 1) * perPage)]
    # let postLink = getPermalinkOf(data, config)
    let name = if i == 0: "" else: $(i + 1)
    let pagination = Pagination(pageSize: perPage, totalPages: pages, currentPage: i+1)
    let privOutDir = if i == 0: privDest else: outDir
    var posts = newSeq[VNode]()
    for data in pagePosts:
      let textContent = innerText(data.child, MaxDescriptionLen, @["pre", "code"])
      posts.add renderPostPartial(config, data, verbatim(textContent))
    if renderPosts != nil and i == 0:
      # render homepage
      let homePageNode = renderIndex(config, posts, pagination)
      let outfile = homePageDir / "index.html"
      info "Generate homepage", to = outfile.relativePath(cwd)
      let description = xmltree.escape(config.description)
      let content = renderHtml($homePageNode, pageTitle = config.title, title = config.title, url = config.url,
          siteName = config.title, description = description, cssHtml = cssHtml)
      writeFile(outfile, content)

    let indexNode = renderPostsProc(config, posts, pagination)
    if not dirExists(privOutDir / name):
      createDir(privOutDir / name)
    let outfile = privOutDir / name / "index.html"
    info "Generate posts page", page = i + 1, to = outfile.relativePath(cwd)
    let description = xmltree.escape(config.description)
    let content = renderHtml($indexNode, pageTitle = config.title, title = config.title, url = $(prefix / name),
        siteName = config.title, description = description, cssHtml = cssHtml)
    writeFile(outfile, content)
    inc i

proc generateArchive(config: Config; libTheme: LibHandle; posts: seq[PostData]; cwd = getCurrentDir();
    dest = getCurrentDir() / "build"; cssHtml = "") =
  var privDest = dest
  if not dest.isRelativeTo(cwd):
    privDest = cwd / "build"

  let renderArchive = cast[RenderArchive](libTheme.symAddr("renderArchive"))
  doAssert renderArchive != nil
  let renderPostPartial = cast[RenderPostPartial](libTheme.symAddr("renderPostPartial"))
  doAssert renderPostPartial != nil
  let index_generator = config.index_generator
  let rootUrl = parseUri(config.url)
  let prefix = rootUrl / index_generator.path / index_generator.pagination_dir
  let outDir = privDest / config.archive_dir / index_generator.pagination_dir

  let perPage = index_generator.per_page
  let postsLen = posts.len
  var m = postsLen mod perPage
  let pages = if m != 0: postsLen div perPage + 1 else: postsLen div perPage
  var i = 0
  var archives: Table[int, seq[VNode]]
  while i < pages:
    let pagePosts = posts[i * perPage ..< min(postsLen, (i + 1) * perPage)]
    let name = if i == 0: "" else: $(i + 1)
    let privOutDir = if i == 0: privDest / config.archive_dir else: outDir
    # var posts = newSeq[VNode]()
    for data in pagePosts:
      let textContent = innerText(data.child, MaxDescriptionLen, @["pre", "code"])
      let year = data.datetime(config).year
      let node = renderPostPartial(config, data, verbatim(textContent))
      if archives.hasKey(year):
        archives[year].add node
      else:
        archives[year] = @[node]

    let index = renderArchive(config, archives)
    archives.clear
    if not dirExists(privOutDir / name):
      createDir(privOutDir / name)
    let outfile = privOutDir / name / "index.html"
    info "Generate archive", page = i + 1, to = outfile.relativePath(cwd)
    let description = xmltree.escape(config.description)
    let content = renderHtml($index, pageTitle = config.title, title = config.title, url = $(prefix / name),
        siteName = config.title, description = description, cssHtml = cssHtml)
    writeFile(outfile, content)
    inc i

proc generateCategory(config: Config; libTheme: LibHandle; posts: seq[PostData]; cwd = getCurrentDir();
    dest = getCurrentDir() / "build"; cssHtml = "") =
  ## generate categories
  var privDest = dest
  if not dest.isRelativeTo(cwd):
    privDest = cwd / "build"

  let renderCategories = cast[RenderCategories](libTheme.symAddr("renderCategories"))
  doAssert renderCategories != nil
  let renderPostPartial = cast[RenderPostPartial](libTheme.symAddr("renderPostPartial"))
  doAssert renderPostPartial != nil
  let index_generator = config.index_generator
  let rootUrl = parseUri(config.url)

  var catedPosts: Table[string, seq[PostData]]
  let defaultCate = config.default_category
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
  for cate, posts in catedPosts:
    let prefix = rootUrl / config.category_dir / cate / index_generator.pagination_dir
    let outDir = privDest / config.category_dir / cate / index_generator.pagination_dir
    let perPage = index_generator.per_page
    let postsLen = posts.len
    var m = postsLen mod perPage
    let pages = if m != 0: postsLen div perPage + 1 else: postsLen div perPage
    var i = 0

    while i < pages:
      let pagePosts = posts[i * perPage ..< min(postsLen, (i + 1) * perPage)]
      let name = if i == 0: "" else: $(i + 1)
      let privOutDir = if i == 0: privDest / config.category_dir / cate else: outDir
      var postNodes = newSeq[VNode]()
      for data in pagePosts:
        let textContent = innerText(data.child, MaxDescriptionLen, @["pre", "code"])
        let node = renderPostPartial(config, data, verbatim(textContent))
        postNodes.add(node)

      let indexNode = renderCategories(config, postNodes)
      if not dirExists(privOutDir / name):
        createDir(privOutDir / name)
      let outfile = privOutDir / name / "index.html"
      info "Generate category", page = i + 1, to = outfile.relativePath(cwd)
      let description = xmltree.escape(config.description)
      let content = renderHtml($indexNode, pageTitle = config.title, title = config.title, url = $(prefix / name),
          siteName = config.title, description = description, cssHtml = cssHtml)
      writeFile(outfile, content)
      inc i

proc generateTag(config: Config; libTheme: LibHandle; posts: seq[PostData]; cwd = getCurrentDir();
    dest = getCurrentDir() / "build"; cssHtml = "") =
  ## generate tag page
  var privDest = dest
  if not dest.isRelativeTo(cwd):
    privDest = cwd / "build"

  let renderPostPartial = cast[RenderPostPartial](libTheme.symAddr("renderPostPartial"))
  doAssert renderPostPartial != nil
  let index_generator = config.index_generator
  let rootUrl = parseUri(config.url)

  var tagedPosts: Table[string, seq[PostData]]
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
  let prefix = rootUrl / config.tag_dir
  let outDir = privDest / config.tag_dir
  let indexNode = renderTag(config, tagCount)
  if not dirExists(outDir):
    createDir(outDir)
  let outfile = outDir / "index.html"
  info "Generate tag index", to = outfile.relativePath(cwd)
  let description = xmltree.escape(config.description)
  let content = renderHtml($indexNode, pageTitle = config.title, title = config.title, url = $prefix,
      siteName = config.title, description = description, cssHtml = cssHtml)
  writeFile(outfile, content)
  for tag, posts in tagedPosts:
    let prefix = rootUrl / config.tag_dir / tag / index_generator.pagination_dir
    let outDir = privDest / config.tag_dir / tag / index_generator.pagination_dir
    let perPage = index_generator.per_page
    let postsLen = posts.len
    var m = postsLen mod perPage
    let pages = if m != 0: postsLen div perPage + 1 else: postsLen div perPage
    var i = 0

    while i < pages:
      let pagePosts = posts[i * perPage ..< min(postsLen, (i + 1) * perPage)]
      let name = if i == 0: "" else: $(i + 1)
      let pagination = Pagination(pageSize: perPage, totalPages: pages, currentPage: i+1)
      let privOutDir = if i == 0: privDest / config.category_dir / tag else: outDir

      var postNodes = newSeq[VNode]()
      for data in pagePosts:
        let textContent = innerText(data.child, MaxDescriptionLen, @["pre", "code"])
        let node = renderPostPartial(config, data, verbatim(textContent))
        postNodes.add(node)

      let indexNode = renderPostsProc(config, postNodes, pagination)
      if not dirExists(privOutDir / name):
        createDir(privOutDir / name)
      let outfile = privOutDir / name / "index.html"
      info "Generate tag", tage = tag, page = i + 1, to = outfile.relativePath(cwd)
      let description = xmltree.escape(config.description)
      let content = renderHtml($indexNode, pageTitle = config.title, title = config.title, url = $(prefix / name),
          siteName = config.title, description = description, cssHtml = cssHtml)
      writeFile(outfile, content)
      inc i

proc compileTheme(cwd, themeFile: string; themePath: string) =
  info "Theme", status = "Compiling", file = themeFile.relativePath(cwd)
  let cmd = "nim c " & (when defined(release): "-d:release" else: "") & " --app:lib --verbosity:0 --hints:off -w:off " & themeFile
  let r = execCmdEx(cmd)
  if r.exitCode != 0:
    info "Theme", status = "Compile Error", msg = r.output, file = themeFile.relativePath(cwd)
    removeFile(themePath)
    quit(1)
  info "Theme", status = "Compiled", file = themeFile.relativePath(cwd)

proc build*(cwd = getCurrentDir()): int =
  ## generate static site
  result = 1
  let config = parseConfig(cwd / "config.yml")
  let metaPath = cwd / "crown_ui.json"
  let theme = if config.theme.len > 0: config.theme else: "default"
  # compile theme
  let themeDir = cwd / "themes" / theme
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
  let sourceDir = (if config.source_dir.len > 0: config.source_dir else: "source") / "posts"
  let sources = cwd / sourceDir / "*.md"
  var posts = newSeq[PostData]()
  for f in walkFiles(sources):
    posts.add getPostData(f, absolutePath cwd / sourceDir)

  proc cmpPostDate(x, y: PostData): int =
    cmp(x.datetime(config).toTime.toUnix, y.datetime(config).toTime.toUnix)
  sort(posts, cmpPostDate, SortOrder.Descending)
  generatePosts(config, libTheme, posts, cwd = cwd, cssHtml = cssHtml)
  generateIndex(config, libTheme, posts, cwd = cwd, cssHtml = cssHtml)
  generateArchive(config, libTheme, posts, cwd = cwd, cssHtml = cssHtml)
  generateCategory(config, libTheme, posts, cwd = cwd, cssHtml = cssHtml)
  generateTag(config, libTheme, posts, cwd = cwd, cssHtml = cssHtml)
  unloadLib(libTheme)
  result = 0

when isMainModule:
  const exampleDir = currentSourcePath.parentDir.parentDir.parentDir / "example"
  echo exampleDir
  discard build(exampleDir)
