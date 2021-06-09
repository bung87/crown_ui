import karax / [karaxdsl, vdom]
import json
import crown_ui / [utils]

proc PureHeader*(title: string = ""; menu: seq[Link] = @[]; n: VNode = nil): VNode =
  buildHtml(header(class = "site-header")):
    nav(class = "pure-menu pure-menu-horizontal pure-menu-scrollable"):
      tdiv(class = "nav-content"):
        a(href = "/", class = "pure-menu-heading pure-menu-link site-logo-container"):
          img(class = "site-logo", src = "/images/logo.svg", height = "28", alt = "Nim")
        if n != nil: n else: discard
        ul(class = "pure-menu-list fr"):
          li(class = "pure-menu-item"):
            a(href = "/blog.html", class = "pure-menu-link"):
              text title
        ul(class = "pure-menu-list fl"):
          for item in menu:
            li(class = "pure-menu-item"):
              a(href = item.href, class = "pure-menu-link"):
                text item.title
      tdiv(class = "menu-fade")

