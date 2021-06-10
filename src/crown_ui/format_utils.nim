import strutils
import ./types
import times

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

proc parseColonLeadFormat*(format: string): seq[PermalinkComp] =
  let perm = ":year/:month/:day/:title/"
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

proc getPermalinkOf*(post: PostData; format: string): string =
  let comps = parseColonLeadFormat(format)
  var candi = newSeq[string]()
  let localNow = now().local()
  for c in comps:
    case c.kind
    of PermalinkCompKind.raw:
      candi.add c.value
    of PermalinkCompKind.year:
      candi.add $(localNow.year)
    of PermalinkCompKind.month:
      candi.add align($(localNow.month.int), 2, '0')
    of PermalinkCompKind.i_month:
      candi.add $(localNow.month.int)
    of PermalinkCompKind.day:
      candi.add align($(localNow.monthday), 2, '0')
    of PermalinkCompKind.i_day:
      candi.add $(localNow.monthday)
    of PermalinkCompKind.hour:
      candi.add align($(localNow.hour), 2, '0')
    of PermalinkCompKind.minute:
      candi.add align($(localNow.minute), 2, '0')
    of PermalinkCompKind.second:
      candi.add align($(localNow.second), 2, '0')
    of PermalinkCompKind.title:
      # Filename (relative to “source/_posts/“ folder)
      discard
    of PermalinkCompKind.name:
      # filename
      discard
    of PermalinkCompKind.post_title:
      candi.add post.title
    of PermalinkCompKind.category:
      candi.add $post.cates
    of PermalinkCompKind.hash:
      discard
    of PermalinkCompKind.id:
      discard

  candi.join("")
