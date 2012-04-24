---
layout: default
title: Butterfly SQLite Framework
subtitle: The easy way to handle SQLite databases
---


### Welcome to Butterfly SQLite Framework
Databases are one of the few things in software development, which I really don't like. 
They are dry and boring, but still extremely useful and indispensable. 
So I decided, for an incoming AIR project to develop a framework that facilitates the handling of databases. 
My goal was to reduce SQL programming to the lowest. I wrote the framework in few days, because 
I didn't have too much time and it has not been tested for all possible cases, 
but it works very fine for small projects and not overly complex table structures.

The framework is designed to run asynchronously, as in most cases synchronous calls results to freeze the graphical user interface. 
Especially, when you handle huge amount of data.

### Table of Content

* [Basics](basics.html)