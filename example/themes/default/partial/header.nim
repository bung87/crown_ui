import karax / [karaxdsl, vdom]
import json
import crown_ui / [utils, config]

proc PureHeader*(config: Config; ): VNode =
  buildHtml(header(class = "site-header")):
    nav(class = "pure-menu pure-menu-horizontal pure-menu-scrollable"):
      tdiv(class = "nav-content"):
        a(href = "/", class = "pure-menu-heading pure-menu-link site-logo-container"):
          img(class = "site-logo", src = "/images/logo.svg", height = "28", alt = "Nim")
        ul(class = "pure-menu-list fr"):
          li(class = "pure-menu-item"):
            a(href = "/blog.html", class = "pure-menu-link"):
              text config.title
        ul(class = "pure-menu-list fl"):
          for item in config.menuLinks:
            li(class = "pure-menu-item"):
              a(href = item.href, class = "pure-menu-link"):
                text item.title
      tdiv(class = "menu-fade")

