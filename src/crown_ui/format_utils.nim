import strutils

type PermalinkCompKind = enum
  raw = "raw"
  year = ":year"
  month = ":month"
  i_month = ":i_month"
  day = ":day"
  i_day = ":i_day"
  hour = ":hour"
  minute = ":minute"
  second = ":second"
  title = ":title"
  name = ":name"
  post_title = ":post_title"
  id = ":id"
  category = ":category"
  hash = ":hash"

type PermalinkComp = object
  case kind: PermalinkCompKind
  of raw:
    value: string
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
