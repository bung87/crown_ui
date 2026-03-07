
import karax / [karaxdsl, vdom, vstyles]
import ./layout
import crown_uipkg/config
import crown_uipkg/types

proc renderPagePartial*(conf: Config; data: PostMeta;
    child: VNode = nil): VNode =
  doAssert conf != nil
  result = buildHtml(main(class = "main", style = "marginTop:40px;".toCss)):
    tdiv(class = "content", style = "paddingTop:20px;paddingBottom:20px;border-radius:4px;".toCss):
      section(class = "post-page"):
        h4:
          a(href = data.permalink):
            text data.title
        tdiv(class = "post-meta"):
          span:
            span(class = "far fa-calendar-alt", aria-hidden = "true")
            text data.date
        child

proc renderPage*(conf: Config; data: PostMeta;
    child: VNode = nil): VNode =
  let post = renderPagePartial(conf, data, child)
  result = renderLayout(conf, post)
