import karax / [vdom]
type PostData* = tuple
  title: string
  id: string
  date: string # eg. 2020-04-08 10:20:53
  cates: seq[string]
  tags: seq[string]
  child: VNode
  filepath: string
  relpath: string
