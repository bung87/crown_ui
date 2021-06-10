import karax / [karaxdsl, vdom]
import ./layout
import crown_ui/config

const places = @["boston", "cleveland", "los angeles", "new orleans"]
  # h4(id = "participating-as-an-audience"):
  #             text "Participating as an audience"
  #           p:
#             text "All talks will be streamed and recorded for later viewing. Watching the talks live will allow you to ask questions and participate in the discussions with other viewers and the speakers."
proc renderIndex*(config: Config; ): Vnode {.cdecl, exportc, dynlib.} =
  buildHtml(tdiv(class = "mt-3")):
    h1: text "My Web Page"
    p: text "Hello world"
    ul:
      for place in places:
        li: text place
    dl:
      dt: text "Can I use Karax for client side single page apps?"
      dd: text "Yes"

      dt: text "Can I use Karax for server side HTML rendering?"
      dd: text "Yes"

