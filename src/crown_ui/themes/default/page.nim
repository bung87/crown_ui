
import karax / [karaxdsl, vdom]
import ./layout
import crown_ui/config
import crown_ui/types

proc renderPagePartial*(conf: Config; data: PostMeta;
    child: VNode = nil): VNode =
  doAssert conf != nil
  result = buildHtml(tdiv(data-theme = "dark")):
    h4:
      a(href = data.permalink):
        text data.title
    tdiv(class = "post-meta"):
      span:
        span(class = "far fa-calendar-alt", aria-hidden = "true")
        text data.date
    child

proc renderPage*(conf: Config; data: PostMeta;
    child: VNode = nil): VNode  =
  let post = renderPagePartial(conf, data, child)
  result = renderLayout(conf, post)