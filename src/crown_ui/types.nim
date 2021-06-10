import karax / [vdom]
import ./config
import times

type PostData* = tuple
  title: string
  id: string
  date: string # eg. 2020-04-08 10:20:53
  cates: seq[string]
  tags: seq[string]
  child: VNode
  filepath: string
  relpath: string

proc datetime*(self:PostData;config:Config):DateTime = 
  result = parse(self.date, config.dateTimeFormat)

type ThemeMeta* = object
  name*: string
  hash*: string
type CrownMeta* = object
  theme*: ThemeMeta
