---
layout: default
title: learn
permalink: /learn/
---

I'm a fan of self-education and in particular of [MOOCs](https://en.wikipedia.org/wiki/Massive_open_online_course), which I think have massive potential value, especially when it comes to topics like computer science, where it's possible to develop rather thorough and informative automated assessments. Here are some example of particularly well-designed MOOCs that I've enjoyed.

## From Nand to Tetris

A 2-part "learn by doing" course that guides you through the construction of a computing platform from the ground up.

### [Part I](https://www.coursera.org/learn/build-a-computer)

Part I begins with a discussion of elementary logic gates and guides you through the process of building an ALU, CPU, RAM, and the von Neumann architecture that connects these components together. Before taking this course, all of this may as well have been magic for me (and to [some extent](https://en.wikipedia.org/wiki/Semiconductor), it still is). If you feel the same way, this course will be incredibly eye-opening.

### [Part II](https://www.coursera.org/learn/nand2tetris2)

Part II develops the software hierarchy, from the relatively straightforward construction
of an assembler to the development of a virtual machine and a compiler and finally the implementation of a very basic
operating system. Due to the breadth of topics, only the bare essentials of each are covered. The advantage of this is that it allows you to develop a big-picture understanding of how computers work.

### Project

The course ends with an open-ended project: write a program or library that can be compiled with your compiler and
run on the architecture you've built. I wrote an [implementation](https://github.com/bencwallace/toh) of the [Tower
of Hanoi](https://en.wikipedia.org/wiki/Tower_of_Hanoi) puzzle. Below is a screenshot of the game in action, running
on the Hack platform simulator.

[![](https://raw.githubusercontent.com/bencwallace/toh/master/images/toh2.png){:class="img-responsive"}](https://github.com/bencwallace/toh)

## Algorithms

An excellent introduction to algorithms and data structures. This course has one of the best automated graders I've had to fight with. It checks not only correctness, but also style and time and space complexity. This course is more than just a survey of algorithms: lectures and assignments emphasize how to select and use these algorithms properly in practice.

[Part I](https://www.coursera.org/learn/algorithms-part1) 

Discusses the fundamentals, such as stacks and queues, merge sort and quick sort, search trees, and hash tables.

[Part II](https://www.coursera.org/learn/algorithms-part2)

Deals with graph algorithms, such as breadth- and depth-first search and Dijkstra's algorithm, as well as
string processing algorithms, such as the famous grep algorithm.

## Programming Languages

A 3-part introduction to the theory of programming languages. I find this course not only made me a better programmer, but also allowed me to better compare programming languages and understand programming language concepts, including (but not limited to): referential transparency, syntax and semantics, polymorphism, macros, and dynamic dispatch.

### [Part A](https://www.coursera.org/learn/programming-languages)

Introduces functional programming with static types through Standard ML.

### [Part B](https://www.coursera.org/learn/programming-languages-part-b)

Introduces dynamic typing and macros through Racket.

### [Part C](https://www.coursera.org/learn/programming-languages-part-c)

Introduces object-oriented programming and duck typing with Ruby.

## Machine Learning

A great overview of the field: from linear and logistic regression to neural networks, support vector machines, PCA, and clustering.

[Machine Learning](https://www.coursera.org/learn/machine-learning)

## Deep Learning

A 5-course sequence on deep neural networks. The 5 courses discuss, respectively: feedforward neural networks, training techniques, structuring deep learning projects, convolutional neural networks, and recurrent neural networks.

The final assignment involved an implementation of [neural style transfer](https://en.wikipedia.org/wiki/Neural_Style_Transfer) using a convolution neural network. The image below, of the Louvre in style of Monet, was generated using this network.

![](/assets/nst.jpg){:class="img-responsive"}

[Deep Learning](https://www.coursera.org/specializations/deep-learning)

## Functional Programming in Scala

The first part of a [5-course sequence](https://www.coursera.org/specializations/scala); an introduction to functional programming through Scala.

I hope to take the other parts sometime. These begin with an introduction to more advanced functional concepts (monads, lazy evaluation) and continue on to parallel programming and big data analysis and conclude with a capstone project.

[Functional Programming in Scala](https://www.coursera.org/learn/progfun1)
