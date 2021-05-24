import yaml, streams
import json

proc parseYaml*(s: Stream): seq[JsonNode] =
  var parser = initYamlParser(true)
  var ys = parser.parse(s)
  result = constructJson(ys)

proc parseYaml*(s: string): seq[JsonNode] =
  var parser = initYamlParser(true)
  var ys = parser.parse(s)
  result = constructJson(ys)

proc parseConfig*(path: static[string]): JsonNode =
  const s = staticRead path
  let res = parseYaml(s)
  result = if res.len > 0: res[0] else: newJObject()
