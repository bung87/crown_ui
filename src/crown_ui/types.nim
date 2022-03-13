import ./config
from times import DateTime, parse

type PostMeta* = tuple
  title: string
  id: string
  date: string # eg. 2020-04-08 10:20:53
  cates: seq[string]
  tags: seq[string]
  # child: VNode
  filepath: string
  relpath: string
  permalink: string

proc datetime*(self: PostMeta; config: Config): DateTime =
  result = parse(self.date, config.dateTimeFormat)

type ThemeMeta* = object
  name*: string
  hash*: string
type CrownMeta* = object
  theme*: ThemeMeta

type Pagination* = object
  pageSize*: int
  totalPages*: int
  currentPage*: int
