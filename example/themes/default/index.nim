import karax / [karaxdsl, vdom]
import ./layout
import crown_uipkg/config
import crown_uipkg/types

proc renderIndex*(conf: Config; posts: seq[VNode]; pagination = default(Pagination)): Vnode =
  doAssert conf != nil
  let c = buildHtml(tdiv(class = "main")):
    section(class = "jumbotron"):
      h2(id = "banner-title"):
        text "A fast, simple & powerful static site generator"
      tdiv(id = "banner-start"):
        span(id = "banner-start-command"):
          text "nimble install crown_ui"
        a(id = "banner-start-link", class = "pure-button pure-button-primary", href = "docs/"):
          span(class = "fa fa-arrow-right")
    section(class = "content"):
      tdiv(class = "pure-g"):
        for p in posts[0 ..< min(2, posts.len)]:
          tdiv(class = "pure-u-1 pure-u-md-1-2"):
            p
      tdiv(class = "text-centered"):
        a(class = "pure-button", href = "/blog.html"):
          text "All articles"
    section(class = "jumbotron"):
      ul(id = "intro-feature-list", class = "pure-g"):
        li(class = "intro-feature-wrap pure-u-1-2"):
          tdiv(class = "intro-feature"):
            tdiv(class = "intro-feature-icon"):
              span(class = "fa fa-bolt")
            h3(class = "intro-feature-title"):
              text "Blazing Fast"
            p(class = "intro-feature-desc"):
              text "Incredible generating speed powered by Nim. Hundreds of files take only seconds to build."
        li(class = "intro-feature-wrap pure-u-1-2"):
          tdiv(class = "intro-feature"):
            tdiv(class = "intro-feature-icon"):
              span(class = "fa fa-bolt")
            h3(class = "intro-feature-title"):
              text "Markdown Support"
            p(class = "intro-feature-desc"):
              text "All features of GitHub Flavored Markdown are supported, including most Octopress plugins."
        li(class = "intro-feature-wrap pure-u-1-2"):
          tdiv(class = "intro-feature"):
            tdiv(class = "intro-feature-icon"):
              span(class = "fa fa-bolt")
            h3(class = "intro-feature-title"):
              text "One-Command Deployment"
            p(class = "intro-feature-desc"):
              text "You only need one command to deploy your site to GitHub Pages, Heroku or other platforms."
        li(class = "intro-feature-wrap pure-u-1-2"):
          tdiv(class = "intro-feature"):
            tdiv(class = "intro-feature-icon"):
              span(class = "fa fa-bolt")
            h3(class = "intro-feature-title"):
              text "Plugins"
            p(class = "intro-feature-desc"):
              text "Features powerful APIs for limitless extensibility. Various plugins are available to support most template engines (EJS, Pug, Nunjucks, and many others). Easily integrate with existing NPM packages (Babel, PostCSS, Less/Sass, etc)."
  result = renderLayout(conf, c)
