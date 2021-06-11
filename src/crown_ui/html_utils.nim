
import strformat
import karax / [vdom]
import fusion / [htmlparser, htmlparser/xmltree]
import unicode

proc renderHtml*(body: string, pageTitle: string, title: string, url: string, siteName: string, description: string,
    image = "", pubTime = "", modTime = "", author = "", locale = "", cssHtml = ""): string =
  let general = fmt"""
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>{pageTitle}</title>
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
  <meta name="description" content="{description}">
  <meta property="og:type" content="article">
  <meta property="og:title" content="{title}">
  <meta property="og:url" content="">
  <meta property="og:site_name" content="{siteName}">
  <meta property="og:description" content="{description}">
  <meta property="og:locale" content="{locale}">
  {cssHtml}
  """
  let metaImage = (if image.len > 0: fmt"""<meta property="og:image" content="{image}">""" else: "")
  let pubTime = (if pubTime.len > 0: fmt"""<meta property="article:published_time" content="{pubTime}">""" else: "")
  let modTime = (if modTIme.len > 0: fmt"""<meta property="article:modified_time" content="{modTIme}">""" else: "")
  let restHead = fmt"""
  <meta property="article:author" content="{author}">
  <meta name="generator" content="crown_ui">
  <link rel="alternate" href="/atom.xml" title="{siteName}" type="application/atom+xml">
  <link rel="icon" href="/favicon.png">
</head>"""

  result = general & metaImage & pubTime & modTime & restHead & "<body>" & body & "</body></html>"

proc innerText*(n: XmlNode, skip: seq[string] = @[]): string =
  ## Gets the inner text of `n`:
  let skipLen = skip.len
  proc worker(res: var string; n: XmlNode) =
    case n.kind
    of xnText, xnEntity:
      res.add(n.text)
    of xnElement:
      if skipLen > 0:
        if n.tag notin skip:
          for sub in n:
            worker(res, sub)
      else:
        for sub in n:
          worker(res, sub)
    else:
      discard

  result = ""
  worker(result, n)

proc innerText*(n: Vnode; limit: int, skip: seq[string] = @[]): string =
  ## limit: limit runes length
  ## skip: skip html tags
  var textContent = innerText(parseHtml($n), skip)
  var runes = textContent.toRunes()
  let runeLen = runes.len
  let b = min(limit, runeLen)
  result = $runes[0 ..< b]

