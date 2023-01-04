
import karax / [karaxdsl, vdom]
import ./layout
import crown_uipkg/config
import tables

proc renderArchive*(conf: Config; archives: Table[string, seq[VNode]]): Vnode =
  let c = buildHtml(tdiv(class = "mt-3")):
    for year, posts in archives:
      tdiv:
        tdiv(class = "pure-u-1"):
          h2:
            text $year
        for thePost in posts:
          tdiv(class = "pure-u pure-u-md-1-3"):
            thePost
  result = renderLayout(conf, c)
