import yaml, streams
import json

proc parseYaml*(s: Stream): seq[JsonNode] =
  var parser = initYamlParser(true)
  var ys = parser.parse(s)
  result = constructJson(ys)
