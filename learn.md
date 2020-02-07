---
layout: default
title: learn
permalink: /learn/
---

I'm a fan of self-education and in particular of [MOOCs](https://en.wikipedia.org/wiki/Massive_open_online_course). I think that, especially when it comes to computer science and related topics, where it's possible to develop rather detailed and informative automated assessments, MOOCs have a huge potential as introductory resources. Here are some examples that I've thoroughly enjoyed.

## From Nand to Tetris

A 2-part "learn by doing" course that guides you through the construction of a computing platform from the ground up.

### [Part I](https://www.coursera.org/learn/build-a-computer)

This course begins with a discussion of elementary logic gates and guides you through the process of building an ALU, CPU, and RAM and the von Neumann architecture that connects these components together. Before taking this course, electronics may as well have been magic for me (and to [some extent](https://en.wikipedia.org/wiki/Semiconductor), it still is). If you feel the same way, this course will be incredibly eye-opening.

### [Part II](https://www.coursera.org/learn/nand2tetris2)

Develops the software hierarchy, from the simple construction
of an assembler, to the development of a virtual machine and a compiler, and finally the implementation of a basic
operating system. Due to the breadth of this course, only the bare essentials of each are covered, leading to more of a big-picture understanding of how computers work. If you've ever wondered "where" the stack and heap are located, you'll especially enjoy the section on [virtualization](https://en.wikipedia.org/wiki/Virtualization).

The course ends with an open-ended project: write a program or library that can be compiled with your compiler and
run on the architecture you've built. I wrote an [implementation](https://github.com/bencwallace/toh) of the [Tower
of Hanoi](https://en.wikipedia.org/wiki/Tower_of_Hanoi) puzzle. Below is a screenshot of the game in action, running
on the Hack platform simulator.

[![](https://raw.githubusercontent.com/bencwallace/toh/master/images/toh2.png){:class="img-responsive"}](https://raw.githubusercontent.com/bencwallace/toh/master/images/toh2.png)

## Algorithms

An excellent introduction to algorithms and data structures. This course has one of the best automated graders I've had to fight with. It checks not only correctness, but also style and time and space complexity.

[Part I](https://www.coursera.org/learn/algorithms-part1) 

Discusses the fundamentals, such as stacks and queues, merge sort and quick sort, search trees, and hash tables.

[Part II](https://www.coursera.org/learn/algorithms-part2)

Deals with graph algorithms, such as breadth- and depth-first search and Dijkstra's algorithm, as well as
string processing algorithms, such as the famous grep algorithm.

One of my [favourite assignments](https://coursera.cs.princeton.edu/algs4/assignments/seam/specification.php) involved the implementation of a [seam carving](https://en.wikipedia.org/wiki/Seam_carving) algorithm for smart image resizing. The video
below is an excellent explanation of this algorithm.

<iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/6NcIJXTlugc" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Programming Languages

A 3-part introduction to the theory of programming languages. I find this course not only made me a better programmer, but also allowed me to better compare programming languages and understand programming language concepts, including (but not limited to): referential transparency, syntax and semantics, compile time vs. runtime, macros, and dynamic dispatch.

### [Part A](https://www.coursera.org/learn/programming-languages)

Introduces functional programming with static types through Standard ML.

### [Part B](https://www.coursera.org/learn/programming-languages-part-b)

Introduces dynamic typing through Racket.

### [Part C](https://www.coursera.org/learn/programming-languages-part-c)

Introduces object-oriented programming with Ruby.

## Machine Learning

A great overview of the field: from linear and logistic regression to neural networks, support vector machines, PCA, and clustering.

[Machine Learning](https://www.coursera.org/learn/machine-learning)

## Deep Learning

A 5-course sequence on deep neural networks. The 5 courses discuss, respectively: feedforward neural networks, training techniques, structuring deep learning projects, convolutional neural networks, and recurrent neural networks.

[Deep Learning](https://www.coursera.org/specializations/deep-learning)

The final assignment involved an implementation of [neural style transfer](https://en.wikipedia.org/wiki/Neural_Style_Transfer) using a convolution neural network. The image below, of the Louvre in style of Monet, was generated using this network.

![](/assets/nst.jpg){:class="img-responsive"}

## Functional Programming in Scala

The first part of a [5-course sequence](https://www.coursera.org/specializations/scala); an introduction to functional programming through Scala.

I hope to take the other parts sometime. These begin with an introduction to more advanced functional concepts (monads, lazy evaluation) and continue on to parallel programming and big data analysis and conclude with a capstone project.

[Functional Programming in Scala](https://www.coursera.org/learn/progfun1)
