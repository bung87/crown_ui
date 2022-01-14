import karax / [karaxdsl, vdom]
import crown_ui/config
import crown_ui/types
import crown_ui/format_utils

proc renderPagination*(conf: Config; pagination: Pagination): VNode =
  doAssert conf != nil

  result = buildHtml(tdiv(data-theme = "dark")):
    tdiv(class = "pagination"):
      ul(class = "pure-menu-list"):
        li(class = "pagination-previous disabled"):
          a:
            text "← Newer"
        for p in max(pagination.currentPage - 3, 1) .. min(pagination.currentPage + 3, pagination.totalPages):
          let isCurrent = pagination.currentPage == p
          li(class = if isCurrent: "pagination-item pagination-current" else: "pagination-item "):
            a:
              text $p
        li(class = "pagination-next"):
          a:
            text "Older →"

