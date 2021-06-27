import strutils
import ./types
import times
import ./datetime_utils
import ./config
import os

# https://hexo.io/docs/permalinks
type PermalinkCompKind* {.pure.} = enum
  raw = "raw"
  year = ":year"
  month = ":month"
  i_month = ":i_month"
  day = ":day"
  i_day = ":i_day"
  hour = ":hour"
  minute = ":minute"
  second = ":second"
  title = ":title" # Filename (relative to “source/_posts/“ folder)
  name = ":name"   # filename
  post_title = ":post_title"
  id = ":id"
  category = ":category"
  hash = ":hash"   # hash of filename (same as :title) and date (12-hexadecimal)

type PermalinkComp = object
  case kind*: PermalinkCompKind
  of raw:
    value*: string
  else:
    discard

proc parseColonLeadFormat*(perm: string): seq[PermalinkComp] =
  let permLen = perm.len
  var i = 0
  var candi = newSeq[string]()
  var cur: string
  var m = false
  while i < permLen:
    if perm[i] == ':':
      m = true
      cur.add perm[i]
    elif perm[i] in {'a' .. 'z', '_'}:
      cur.add perm[i]
    else:
      if m == true:
        candi.add cur
      m = false
      cur.setLen 0
      candi.add $perm[i]
    inc i
  for c in candi:
    try:
      let x = parseEnum[PermalinkCompKind](c)
      result.add PermalinkComp(kind: x)
    except:
      result.add PermalinkComp(kind: raw, value: c)

proc getPermalinkOf*(post: PostData; conf: Config): string =
  let format = conf.permalink
  let comps = parseColonLeadFormat(format)
  var candi = newSeq[string]()
  let localNow = now().local()
  let dtf = conf.dateTimeFormat
  let date = if post.date.len > 0: parse(post.date, dtf) else: localNow
  for c in comps:
    case c.kind
    of PermalinkCompKind.raw:
      candi.add c.value
    of PermalinkCompKind.year:
      candi.add $(date.year)
    of PermalinkCompKind.month:
      candi.add align($(date.month.int), 2, '0')
    of PermalinkCompKind.i_month:
      candi.add $(date.month.int)
    of PermalinkCompKind.day:
      candi.add align($(date.monthday), 2, '0')
    of PermalinkCompKind.i_day:
      candi.add $(date.monthday)
    of PermalinkCompKind.hour:
      candi.add align($(date.hour), 2, '0')
    of PermalinkCompKind.minute:
      candi.add align($(date.minute), 2, '0')
    of PermalinkCompKind.second:
      candi.add align($(date.second), 2, '0')
    of PermalinkCompKind.title:
      # Filename (relative to “source/_posts/“ folder)
      candi.add post.relpath.changeFileExt("")
    of PermalinkCompKind.name:
      # filename
      var (_, name, _) = splitFile(post.relpath)
      candi.add name
    of PermalinkCompKind.post_title:
      candi.add post.title
    of PermalinkCompKind.category:
      candi.add $post.cates
    of PermalinkCompKind.hash:
      discard
    of PermalinkCompKind.id:
      discard

  candi.join("")

when isMainModule:
  echo parse("2021-06-11 15:04:29", "YYYY-MM-dd' 'HH:mm:ss")
  let d = "2021-06-11 15:04:29"
  let f = "YYYY-MM-dd' 'HH:mm:ss"
  echo parse(d, f)
