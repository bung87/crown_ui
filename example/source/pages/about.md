---
title: about
date: "2022-03-13 16:52:52"
---

`crown_ui` is a static site generator written in [Nim](https://nim-lang.org) language. 

Nim is a statically typed compiled systems programming language. It combines successful concepts from mature languages like Python, Ada and Modula.  

`crown_ui` use [karax](https://github.com/karaxnim/karax) as template engine.

Karax is a framework for developing single page applications in Nim. karax comes with its own `buildHtml` DSL for convenient construction of (virtual) DOM trees (of type `VNode`)  

`crown_ui` use [nimscripter](https://github.com/beef331/nimscripter) for calling nimscript to build dynamic theme. 

`crown_ui` use [scorper](https://github.com/bung87/scorper) as development server  

scorper is a micro and elegant web framework written in Nim