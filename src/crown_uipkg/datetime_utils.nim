##
## output format compatible with momentjs format
## see https://momentjs.com/docs/#/displaying/
## see https://nim-lang.org/docs/times.html#parsing-and-formatting-dates
##
import npeg, strutils
import npeg/lib/utf8
import json 

type Data = seq[string]

const parser = peg("line", d: Data):
  line <- *(ident | noQuote | char)
  ident <- (YYYY | M | D | h | m | s | w | W | YY | MM | DD | HH|hh | mm | ss | MMM)
  YYYY <- "YYYY": # Y 代表年(完整显示)
    d.add "YYYY"
  M <- 'M':       # M 代表月(1-12)
    d.add "M"
  D <- 'D':       # D 代表日(1-31)
    d.add "d"
  h <- 'h':       # h 代表时(0-23)
    d.add "H"
  m <- 'm':       # m 代表分(0-59)
    d.add "m"
  s <- 's':       # s 代表秒(0-59)
    d.add "s"
  w <- 'w':       # w 代表星期(0-6)
    d.add "e"
  W <- 'W':       # W 代表星期的英文缩写(支持翻译)
    d.add "ddd"
  YY <- "YY":     # YY 代表年(只显示末两位)
    d.add "YY"
  MM <- "MM":     # MM 代表月(01-12)
    d.add "MM"
  DD <- "DD":     # DD 代表日(01-31)
    d.add "dd"
  hh <- "hh":     # hh 代表时(00-23)
    d.add "HH"
  HH <- "HH":
    d.add "HH"
  mm <- "mm":     # mm 代表分(00-59)
    d.add "mm"
  ss <- "ss":     # ss 代表秒(00-59)
    d.add "ss"
  MMM <- "MMM":   # MMM 代表月的英文缩写(支持翻译)
    d.add "MMM"
  noQuote <- {':', '-', '(', ')', '/', '[', ']', ',', ' '}:
    d.add $0
  char <- > utf8.any:
    d.add "'" & $1 & "'"

proc isMomentFormat*(format: string): bool =
  var words: seq[string]
  let r = parser.match(format, words)
  result = r.ok

proc toNimFormat*(format: string): string =
  var words: seq[string]
  let r = parser.match(format, words)
  if not r.ok:
    raise newException(ValueError, "can't parse input format: " & format)
  result = words.join("")

