---
title: test post one title
id: 463
categories:
  - post_cat1
date: 2017-11-05 17:59:58
tags:
---

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