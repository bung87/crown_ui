import karax / [karaxdsl, vdom]
# import json
import crown_uipkg / [config]

proc PureHeader*(conf: Config): VNode =
  result = buildHtml(header(class = "site-header")):
    nav(class = "pure-menu pure-menu-horizontal pure-menu-scrollable"):
      tdiv(class = "nav-content"):
        a(href = "/", class = "pure-menu-heading pure-menu-link site-logo-container"):
          img(class = "site-logo", src = "/images/logo.svg", height = "28", alt = "Nim")
        # ul(class = "pure-menu-list fr"):
        #   li(class = "pure-menu-item"):
        #     a(href = "/blog.html", class = "pure-menu-link"):
        #       text conf.title
        ul(class = "pure-menu-list fl"):
          for m in conf.menuLinks:
            li(class = "pure-menu-item"):
              a(href = m.href, class = "pure-menu-link"):
                text m.title
      tdiv(class = "menu-fade")

