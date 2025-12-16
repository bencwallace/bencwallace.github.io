---
title: "Implementing typeclasses in Scala I"
date: 2020-01-19
categories: 
  - "programming"
  - "scala"
tags: 
  - "polymorphism"
  - "typeclasses"
  - "types"
---

I've been learning Scala recently and have been very impressed with the power of some of its features as well as the way in which it seamlessly combines object-oriented and functional programming. Nevertheless, some of these features can seem a bit tricky and learning resources can be relatively hard to find. In particular, I had some difficulty wrapping my head around [_implicits_](https://docs.scala-lang.org/tour/implicit-parameters.html). Things came together when I began to ask myself: what are the analogs of [Haskell's typeclasses](https://en.wikibooks.org/wiki/Haskell/Classes_and_types) in Scala?

It turns out that, unlike in Haskell, typeclasses are not built-in to the language; rather, they can be _implemented_ using implicits. Because of this, they're actually more powerful than in Haskell: you can, for example, create multiple coexisting typeclass instances and pass them around as objects. Moreover, due to Scala's object-oriented nature, typeclasses can inherit from one another.

Note that there already exist some Scala libraries, such as [Scalaz](https://github.com/scalaz/scalaz) and [Cats](https://github.com/typelevel/cats), that develop many useful typeclasses, but for the purpose of understanding how this is done I think it's best to start from scratch.

**Note**. I'll make use of some basic Scala features. Implicits are the only feature I'll really explain (I also briefly explain "options"). Most of the others are similar to ones found in Java (traits are like interfaces, objects replace the `static` keyword, pattern matching is somewhat like the `switch` statement). In the later posts I'll implement functors and monads, but these won't be discussed here.

I may also do things in slightly non-idiomatic ways at times. I'm also not an expert on programming languages. If you find anything wrong or that could be improved in this post, please let me know.

## Roadmap

In this post, I'll start by discussing typeclasses, options, and implicits. Then I'll introduce `Measurable`, a made-up typeclass that we'll work with, and show how to make ordinary types like `Int` and `String` members of it. This will lead to a discussion of context bounds, which will allow us to add type constraints and implement an instance of `Option` for `Measurable`. I'll wrap up with a brief discussion of implicit classes.

## Why typeclasses?

Rather than giving a general explanation of what typeclasses are, I'll try to explain some of the basic ideas in the examples that follow. Much better introductions to typeclasses than I could write can easily be found online. All I'll say here is that typeclasses are "like (Java) interfaces" but much more general and powerful. In particular, we'll see the following examples of what typeclasses can do that interfaces can't:

1. Types can be made members of typeclasses outside of their own definitions; this means, for example, that we can make built-in types members of typeclasses.
2. Typeclass instantiation of parameterized types can be specialized depending on the type parameter ("ad hoc polymorphism").
3. So-called "higher-kinded" types can be made members of typeclasses.

## Options

I'll be using options extensively as examples, so I'll briefly explain what they are: Options are basically a type-safe replacement for `null`. For any type `A`, the parameterized type `Option[A]` can take on either the value `None` or the value `Some(x)` for any value `x` of type `A`. For example, you could use options to write a function that reads user input and expects an integer like this.

```scala
def getInteger(): Option[Int] = {
  val s = StdIn.readLine()
  try {
    Some(s.toInt)
  } catch {
    case _: NumberFormatException => None
  }
}

```

Here `None` is used as a type-safe way of signalling that the user did not input a number. This is different from returning `null` because we're actually returning an object and avoiding the possibility of a `NullPointerException`.

## Scala implicits

Implicits obviate the need to (explicitly) cast or convert objects from one type to another. In fact, this is how Scala deals with different numerical types: when you pass, say, an `Int` to a function of a `Double`, [Scala](https://github.com/scala/scala/blob/v2.11.8/src/library/scala/Int.scala#L474) performs an implicit conversion (note that `Int` is _not_ a subtype of `Double`).

There are several ways to define implicit conversions. Rather than provide an exhaustive list, I'll sprinkle these throughout the post. Here's one way to do it.

**Implicit conversion I.** Define an `implicit` function or method that performs the implicit conversion

Suppose we wanted to pass an ordinary (non-option) value `a` to a function `f` of an option and have it automatically understood as `Some(x)`. Here's what we'd do.

```scala
implicit def any2option[A](x: A): Option[A] = Some(x)

def f[A](option: Option[A]): Unit = option match {
  case None => println("None")
  case Some(x) => println(x)
}

```

Now (as long as `any2option` is in scope) we can call, for example, `f(10)`, which will print "10" to the screen. When the compiler encounters our function call, it notices that `10` is not of the right type to be passed to `f`. In most statically-typed languages, this would immediately lead to a compilation error. The Scala compiler, however, searches within the "implicit scope" for an implicit conversion; in this case, it finds `any2option`, which can convert an `Int` to an `Option[Int]`, which _is_ of the right type to be passed to `f`. The compiler then replaces our ordinary function call `f(10)` by `f(any2option(10))`.

Note that if we called `f(Some(10))`, the compiler would _still_ print "10" to the screen (rather than "Some(10)") because an implicit conversion is not necessary (hence not used) in this case.

The fact that `any2option` works with parameters of any type is referred to as [**parametric polymorphism**](https://en.wikipedia.org/wiki/Parametric_polymorphism). This isn't especially relevant right now, but will be good to know later. This is a great term if you want to sound smart, because it's made up of two words of Greek origin.

## Beginning to define a typeclass

I decided to start with a very simple, made-up typeclass `Measurable`. Members of `Measurable` have values that can be "measured" in some way. It doesn't really matter how but some ideas that come to mind are: the measure of a numeric value could be its absolute value; the measure of a string could be its length; the measure of a list of measurable values could be the sum of their measures; and so on. We begin our definition with a trait declaration.

```scala
// Measurable.scala

trait Measurable[A] {
  def measure(x: A): Double
}

```

In addition to this, we'll also define a "law" for `Measurable`. This is a contract that clients of measurable are _expected_ to obey but that cannot be enforced by the type system. Numerous common typeclasses derived from mathematics, such as functors and monads, have laws of this kind. Our `Measurable` law will be the following.

**Measurable law.** The `measure` function must produce non-negative values.

This requirement cannot be expressed, at least in plain Scala, because it requires [refinement types](https://en.wikipedia.org/wiki/Refinement_type) (however, there does appear to be a [library](https://github.com/fthomas/refined) for refinement types in Scala).

## Instantiating typeclass members

So far that was pretty simply. All we did was define a trait with a single method. Now you might complain: _[Traits are just Scala's versions of interfaces](https://www.scala-lang.org/news/2.12.0-RC1/). So how is a typeclass different from an interface?_ Well, for starters, we're actually not done with the typeclass definition. But more importantly, typeclasses are different in how we use them. Rather than extending them, we'll implement them _implicitly_.

Suppose we wanted to make `Int` a member of `Measurable`. Since `Int` is _already defined_ elsewhere, we can't change it. However, we can define a _separate_ object that realizes the instance of `Measurable` we would like.

```scala
val int2measure: Measurable[Int] = x => Math.abs(x)
```

**Syntactic sugar.** Here we've used a bit of [syntactic sugar.](https://en.wikipedia.org/wiki/Syntactic_sugar) Since `Measurable` contains only one abstract method, we can define an anonymous class implementing it just by specifying how that method is implemented. Moreover, this method can be given as an anonymous function (because its name, `measure`, is already determined). That's why the right-hand side looks like an anonymous function (with the same signature as `measure` when `A = Int`). We've also used Scala's [string interpolation](https://docs.scala-lang.org/overviews/core/string-interpolation.html).

This is all well and good, but how does it help us? Let's remind ourselves of what we're trying to accomplish. We'd like to be able to pass an `Int` to `Measurable.measure`. The latter is abstract, but we'd like it to be _implicitly defined_ by `int2measure.measure`. We could call the latter directly, but this isn't really satisfactory. For example, suppose we implemented another implicit conversion `string2measure: Measurable[String]`. Now we'd have to call `string2measure.measure("hello")`. We'd like to be able to unify the `measure` methods of `int2measure`, `string2measure`, and so on into _a single function_.

### Ad hoc polymorphism

What we want is a _polymorphic_ function `measure[A]` that works for any `A` _for which an instance of `Measurable[A]` exists_. This is _not_ parametric polymorphism, because the type `A` is constrained. We need some way to express this constraint. This is where the notion of an implicit parameter comes in.

**Implicit conversion II.** Add an `implicit` parameter to the type signature of a function that may require an implicit conversion.

Let's define our `measure` function and then explain how it works. Note that we've placed this function in the [companion object](https://docs.scala-lang.org/overviews/scala-book/companion-objects.html) for `Measurable`.

```scala
// Measurable.scala // ...

object Measurable {
  def measure[A](x: A)(implicit measureInstance: Measurable[A]): Double =
    measureInstance.measure(x)
}

```

Even though `measure` is generic, it takes an implicit parameter of type `Measurable[A]`. Because the parameter is implicit, we don't have to explicitly pass in a value for it. Rather, the compiler will look for an implicit object in the current scope that it can use, depending on the type parameter `A`. For instance, we would like it to be able to find `int2measure`, so we make that value implicit.

```scala
// MeasurableClient.scala

import Measurable._

object MeasurableInt {
  implicit val int2measure: Measurable[Int] = x => Math.abs(x)
}

```

Now if we call `measure(10)` (with `int2measure` in scope), the compiler will automatically find `int2measure` and pass it in as the value of `measureInstance`; thus, `measure(10)` will become `measure(10)(int2measure)`, which evaluates to `int2measure.measure(10)`. Similarly, `measure("hello")` would become `string2measure.measure("hello")`.

In a way, `measure` is not fully generic even though it appears to be declared generically. Rather, `measure[A](x)` will only work for types `A` for which an instance `Measurable[A]` exists. This is the basic idea of [**ad hoc polymorphism**](https://en.wikipedia.org/wiki/Ad_hoc_polymorphism). This is an even better term than parametric polymorphism for sounding smart, because it's made up of of a Latin phrase together with a word of Greek origin.

**Enforcing laws.** At this point, we could implement the `Measurable` law using an `assert` statement as follows.

```scala
object Measurable {
  def measure[A: Measurable](x: A): Double = {
    val result = implicitly[Measurable[A]].measure(a)
    assert(result >= 0)
    result
  }
}
```

However, this won't work for other typeclasses.

## Defining a typeclass

Putting together what we saw above, here's how we define the `Measurable` typeclass.

```scala
// Measurable.scala

trait Measurable[A] {
  def measure(x: A): Double
}

object Measurable {
  def measure[A](x: A)(implicit measureInstance: Measurable[A]): Double =
    measureInstance.measure(x)
}

```

To summarize:

- A _typeclass_ is implemented using a trait together with a companion object whose methods implicitly implement the trait's methods via ad hoc polymorphism.
- An _instance_ of a typeclass is an implicit instantiation of the trait in the typeclass's implementation.
- A _member_ of a typeclass is any type with an instance of the typeclass.

## Context bounds

At this point we're pretty much done. We've implemented the `Measurable` typeclass and demonstrated how to make other types members of it. However, there's a few things we get "for free" at this point that are worth adding.

The type signature of `measure` says that "`A` must have a type that implements the `Measurable` typeclass". This precise idea can be expressed using the following syntactic sugar supported by Scala: instead of declaring `measure` as above, we write `def measure[A: Measurable](x: A)`. The constraint `A: Measurable` is called a [**context bound**](https://docs.scala-lang.org/tutorials/FAQ/context-bounds.html).

Now if you try making that replacement, you'll encounter an issue on the right-hand side: `measureInstance` is no longer bound to anything. However, if `A` does have a `Measurable` instance (represented by an implementation of `Measurable[A]`), an implicit parameter _will_ be passed to `measure` and can be retrieved within its scope by referring to `implicitly[Measurable[A]]`. Thus, the definition of `measure` becomes the following.

```scala
// Measurable.scala
// ...

object Measurable {
  def measure[A: Measurable](x: A): Double =
    implicitly[Measurable[A]].measure(x)
}

```

This is not only cleaner, but better captures the fact that `measure` uses ad hoc rather than parametric polymorphism.

### Class constraints

Equipped with our knowledge of context bounds, we can now also make `Option[A]` a member of `Measurable`… that is, _so long as `A` itself is a member of `Measurable`_. With context bounds, this constraint is incredibly easy to express! We just need something like `int2measure`, but polymorphic.

```scala
def option2measure[A: Measurable](x: A): Measurable[Option[A]] = {
  case None => 0
  case Some(x) => measure(x)
}
```

**Syntactic sugar.** In addition to specifying an anonymous instance of a single-method trait by an anonymous method (as we did with `int2measure`), we're also specifying this anonymous method by an anonymous pattern match.

## Type variance

There's still an issue we should address. If we set `val x: Option[Int] = Some(10)` and call `measure(x)`, then everything works fine. But `measure(Some(10))` doesn't compile. That's because `Some(10)` has type `Some[Int]`, which isn't the same as `Option[Int]` (although it is a subtype).

We need `measure[Some[Int]]` to accept an implicit parameter of type `Measurable[Option[Int]]`. More generally, we need `measure[A]` to accept an implicit parameter whose type is `Measurable[B]` where `B` is any _supertype_ of `A`. This can be accomplished if `Measurable[B] <: Measurable[A]` whenever `A <: B`. This is known as **contravariance** of the type parameter to `Measurable`.

In general in Scala, a relationship between `A` and `B` doesn't imply _any_ relationship between corresponding parameterized types (there are [good reasons](https://en.wikipedia.org/wiki/Covariance_and_contravariance_(computer_science)#Covariant_arrays_in_Java_and_C#) for this). However, a contravariance relation can be imposed by prefixing a type parameter with `-` and, similarly, a **covariance** relationship by prefixing with a `+`. In this case, we'll change our `Measurable` trait as follows.

```scala
// Measurable.scala

trait Measurable[-A]
```

## Implicit classes

One more thing we can do is use implicit _classes_ to automatically convert objects that are members of `Measurable` to objects with a `measure` _method_.

**Implicit conversion III.** Define an `implicit` class. Such a class can implicitly convert from the type of its constructor parameter to the class that it itself defines.

```scala
// Measurable.scala

object Measurable {
  implicit class MeasurableOps[A: Measurable](x: A) {
    def measure: Double = Measurable.measure(x)
  }
}
```

Now we can call `10.measure` or `Some(10).measure` and it will behave as expected! In a way, we've "implicitly" extended the `Int` class and `Some[A]` (for `A: Measurable`) classes.

Let's think about how this works. When `10.measure` is called, the compiler looks for a `measure` method in the `Int` class. It doesn't find one, so it looks in the for _an implicitly defined type that has a `measure` method and to which `Int` can be converted_. It finds the implicit class `MeasurableOps` and sees that `MeasurableOps` requires a parameter of a type `A` that is a member of `Measurable`. Since `A = Int`, the compiler looks for an implicit conversion of `Int` to `Measurable` and finds `int2measure` (One sometimes says that the type checker has _proved_ that `Int` is a member of `Measurable`, i.e. that the requirement `Int: Measurable` can be satisfied). It passes `10` explicitly and `int2measure` implicitly to the constructor of `MeasurableOps`, which returns a new `MeasurableOps` object equipped with a method `measure`. Since `implicitly[Measurable[A]]` is bound to the implicit constructor parameter `int2measure`, the `measure` method of this new object calls `int2measure.measure(10)`.

## What's next?

In the [next post](/2020/01/implementing-type-classes-in-scala-ii/) I'll discuss higher-kinded types and the `Functor` and `Monad` typeclasses. I'll also introduce a tree-like data structure to test these ideas on.
