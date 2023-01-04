---
title: Under development
id: 1
date: "2021-06-11 15:04:29"
---
`crown_ui` is under development.  

code highligh test below  

``` nim

import strformat
type
  Person = object
    name*: string # Field is exported using `*`.
    age: Natural  # Natural type ensures the age is positive.

var people = [
  Person(name: "John", age: 45),
  Person(name: "Kate", age: 30)
]

for person in people:
  # Type-safe string interpolation.
  echo(fmt"{person.name} is {person.age} years old")

```