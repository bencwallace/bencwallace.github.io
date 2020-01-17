---
layout: post
title:  "Implementing type classes in Scala I"
date:   2020-01-15 00:37:44 +0100
categories: scala implicits typeclasses polymorphism
---

I've been learning Scala recently and have been very impressed with the power of some of
its features as well as the way in which it seamlessly combines object-oriented
and functional programming. Nevertheless, some of these features can seem a bit
tricky and learning resources can be relatively hard to find. In particular, I had some
difficulty wrapping my head around [*implicits*](https://docs.scala-lang.org/tour/implicit-parameters.html).
Things came together when I began to
ask myself: what are the analogs of [Haskell's type classes](https://en.wikibooks.org/wiki/Haskell/Classes_and_types)
in Scala?

It turns out that, unlike
in Haskell, type classes are not built-in to the language; rather, they can be *implemented*
using implicits. Because of this, they're actually more powerful than in Haskell: you can,
for example, create multiple coexisting type class instances and pass them around as objects.
Moreover, due to Scala's object-oriented nature, type classes can
inherit from one another.

Note that there already exist some Scala libraries, such as
[Scalaz](https://github.com/scalaz/scalaz) and [Cats](https://github.com/typelevel/cats),
that develop many useful type classes,
but for the purpose of understanding how this is done I think it's best to start from scratch.

**Prerequisites.** I will make use of some basic Scala features. Implicits are the only feature
I'll really explain (I also briefly explain "options"). Most of the others are similar to ones found
in Java (traits are like interfaces, objects replace the `static` keyword, pattern matching is somewhat
like the `switch` statement). In the later posts I'll implement functors and monads, but these won't be
discussed here.

**Warning.** As I said above I'm still learning Scala and I may do things in slightly non-idiomatic
ways at times. I'm also not an expert on programming languages. If you find anything wrong or that
could be improved in this post, please let me know.

## Roadmap

In this post, I'll start by discussing type classes, options, and implicits. Then I'll introdue
`Measurable`, a made-up type class that we'll work with, and show how to make ordinary types like
`Int` and `String` members of it.
This will lead to a discussion of context bounds, which will allow us to add type constraints and implement
an instance of `Option` for `Measurable`. I'll wrap up with a brief discussion of implicit classes.


## Why type classes?

Rather than giving a general explanation of what type classes are, I'll try to explain some of the basic
ideas in the examples that follow. Much better introductions to type classes than I could write
can easily be found online. All I'll say here is that type classes are "like (Java) interfaces"
but much more general and powerful. In particular, we'll see the following examples of what
type classes can do that interfaces can't:

1. Types can be made members of type classes outside of their own definitions; this means, for
  example, that we can make built-in types members of type classes.
2. Type class instantiation of parameterized types can be specialized depending on the type parameter
  ("ad hoc polymorphism").
3. So-called "higher-kinded" types can be made members of type classes.

## Options

I'll be using options extensively as examples, so I'll briefly explain what they are: Options are basically
a type-safe replacement for `null`. For any type `A`, the parameterized type `Option[A]` can take on either
the value `None` or the value `Some(x)` for any value `a` of type `A`. For example, you could use options
to write a function
that reads user input and expects an integer like this.

{% highlight scala %}
def getInteger(): Option[Int] = {
  val s = StdIn.readLine()
  try {
    Some(s.toInt)
  } catch {
    case _: NumberFormatException => None
  }
}
{% endhighlight %}

Here `None` is used as a type-safe way of signalling that the user did not input a number. This is different
from returning `null` because we're actually returning an object and avoiding the possibility of a
`NullPointerException`.

## Scala implicits

Implicits obviate the need to (explicitly) cast or convert objects from one type to another. In fact,
this is how Scala deals with different numerical types: when you pass, say, an `Int` to a function of a
`Double`, [Scala](https://github.com/scala/scala/blob/v2.11.8/src/library/scala/Int.scala#L474) performs
an implicit conversion (this is necessary because `Int` is not a subtype of `Double`).

There are several ways to define implicit conversions. Rather than provide an exhaustive explanation,
I'll sprinkle these throughout the post. Here's one way to do it.

**Implicit conversion I.** Define an `implicit` function or method that performs the implicit conversion

Suppose we wanted to pass an ordinary (non-option) value `a` to a function of an option and have it automatically
understood as `Some(x)`. Here's what we'd do.

{% highlight scala %}
implicit def any2option[A](x: A): Option[A] = Some(x)

def f[A](option: Option[A]): Unit = option match {
  case None => println("None")
  case Some(x) => println(x)
}
{% endhighlight %}

Now (as long as `any2option` is in scope) we can call, for example `f(10)`, which will print "10" to the screen.
When the compiler encounters our function call, it notices that `10` is not of the right type to be passed to
`f`. In most statically-typed languages, this would immediately lead to a compilation error. The Scala compiler,
however, searches within the "implicit scope" for an implicit conversion; in this case, it finds `any2option`,
which can convert an `Int` to an `Option[Int]`, which *is* of the right type to be passed to `f`.
The compiler then replaces our ordinary function call `f(10)` by `f(any2option(10))`.

Note that if we called `f(Some(10))`, the compiler would *still* print "10" to the screen (rather than "Some(10)")
because an implicit conversion is not necessary (hence not used) in this case.

**Terminology.** The fact that `any2option` works with parameters of any type is referred to as
[**parametric polymorphism**](https://en.wikipedia.org/wiki/Parametric_polymorphism).
This isn't especially relevant right now, but will be good to know later.

## Beginning to define a type class

I decided to start with a very simple, made-up type class `Measurable`. Members of member have values that can be
"measured" in some way. It doesn't really matter how but some ideas that come to mind are: the measure of a
numeric value could be its absolute value; the measure of a string could be its length; the measure of a list of measurable
values could be the sum of their measures; and so on.

{% highlight scala %}
// Measurable.scala

trait Measurable[A] {
  def measure(x: A): Double
}
{% endhighlight %}

In addition to this, we'll also define a "law" for `Measurable`. This is a contract that clients of measurable are expected
to obey but that cannot be enforced by the type system. Numerous common type classes derived from mathematics, such as
functors and monads, have laws of this kind. Our `Measurable` law will be the following.

**Measurable law.** The `measure` function must produce non-negative values.

This requirement cannot be expressed, at least in plain Scala, because it requires [refinement types](https://en.wikipedia.org/wiki/Refinement_type)
(however, there does appear to be a [library](https://github.com/fthomas/refined) for refinement types in Scala).

## Instantiating type class members

So far that was pretty simply. All we did was define a trait with a single method.
Now you might complain: *Traits are just Scala's versions of interfaces[^1]. So how is a type class
different from an interface?* Well, for starters, we're actually not done with the type class definition.
But more importantly, type classes are different in how we use them. Rather than extending them,
we'll implement them *implicitly*.

Suppose we wanted to make `Int` a member of `Measurable`. Since `Int` is *already defined* elsewhere, we can't change it.
However, we can define a *separate* object that realizes the instance of `Measurable` we would like.

{% highlight scala %}
val int2measure: Measurable[Int] = x => x
{% endhighlight %}

Here we've used a bit of syntactic sugar. Since `Measurable` contains only one abstract method, we can define an anonymous
class implementing it just by specifying how that method is implemented. Moreover, this method can be given as an
anonymous function (because it's name, `measure`, is already determined). That's why the right-hand side looks like an
anonymous function (with the same signature as `measure` when `A = Int`). We've also used Scala's
[string interpolation](https://docs.scala-lang.org/overviews/core/string-interpolation.html).

This is all well and good, but how does it help us?
Let's remind ourselves of what we're trying to accomplish. We'd like to be able to pass an `Int` to `Measurable.measure`.
The latter is abstract, but we'd like it to be *implicitly defined* by `int2measure.measure`. We could call the latter
directly, but this isn't really satisfactory. For example, suppose we implemented another implicit conversion
`string2measure: Measurable[String]`. Now we'd have to call `string2measure.measure("hello")`. We'd like to be able to unify
the `measure` methods of `int2measure`, `string2measure`, and so on into *a single function*.

### Ad hoc polymorphism

What we want is a *polymorphic*
function `measure[A]` that works for any `A` *for which an instance of `Measurable[A]` exists*. This is *not* parametric
polymorphism, because the type `A` is constrained. We need some way to express this constraint.
This is where the notion of an implicit parameter comes in.

**Implicit conversion II.** Add an `implicit` parameter to the type signature of a function that may require
an implicit conversion.

Let's define our `measure` function and then explain how it works.

{% highlight scala %}
// Measurable.scala
// ...

object Measurable {
  def measure[A](x: A)(implicit measureInstance: Measurable[A]): Double =
    measureInstance.measure(x)
}
{% endhighlight %}

Even though `measure` is generic, it takes an implicit parameter of type `Measurable[A]`. Because the parameter is implicit,
we don't have to explicitly pass in a value for it. Rather, the compiler will look for an implicit object in the
current scope that it can use, depending on the type parameter `A`. For instance, we would like it to be able to
find `int2measure`, so we make that value implicit.

{% highlight scala %}
// MeasurableClient.scala

import Measurable._

object MeasurableInt {
  implicit val int2measure: Measurable[Int] = x => x
}
{% endhighlight %}

Now if we call `measure(10)` (with `int2measure` in scope), the compiler will
automatically find `int2measure` and pass it in as the value of `measureInstance`; thus, `measure(10)` will call
`int2measure.measure(10)`. Similarly, `measure("hello")` would call `string2measure.measure("hello")`.

In a way, `measure` is not fully generic even though it appears to be declared generically. Rather, `measure[A](x)`
will only work for types `A` for which an instance `Measurable[A]` exists. This is the basic idea of
[**ad hoc polymorphism**](https://en.wikipedia.org/wiki/Ad_hoc_polymorphism).

## Defining a type class

Putting together what we saw above, here's how we define the `Measurable` typeclass.

{% highlight scala %}
// Measurable.scala

trait Measurable[A] {
  def measure(x: A): Double
}

object Measurable {
  def measure[A](x: A)(implicit measureInstance: Measurable[A]): Double =
    measureInstance.measure(x)
}
{% endhighlight %}

Essentially, a type class consists of a trait together with a companion object whose methods implicitly
implement the trait's methods via ad hoc polymorphism.

A member of a type class is an implicit instantiation of that trait.

## Context bounds

At this point we're basically done. We've implemented the `Measurable` type class and demonstrated how to make other
types members of it. However, there's a few things we get "for free" at this point that are worth discussing.

The type signature of `measure` says that "`A` must have a type that implements the `Measurable`
type class". This precise idea can be expressed using the following syntactic sugar supported by Scala: instead of
declaring `measure` as above, we write `def measure[A: Measurable](x: A)`. The constraint `A: Measurable` is called a
[**context bound**](https://docs.scala-lang.org/tutorials/FAQ/context-bounds.html).

Now if you try making that replacement, you'll encounter an issue on the right-hand side: `measureInstance` is no
longer bound to anything. However, if `A` does have a `Measurable` instance (represented by an implementation of `Measurable[A]`),
an implicit parameter *will* be passed to `measure` and can be retrieved within its scope by referring to
`implicitly[Measurable[A]]`. Thus, the definition of `measure` becomes the following.

{% highlight scala %}
// Measurable.scala
// ...

object Measurable {
  def measure[A: Measurable](x: A): Double =
    implicitly[Measurable[A]].measure(x)
}
{% endhighlight %}

This is not only cleaner, but better captures the fact that `measure` uses ad hoc rather than parametric polymorphism.

## Type class membership with constraints

Equipped with our knowledge of context bounds, we can now also make `Option[A]` a member of `Measurable`... that is,
*so long as `A` itself is a member of `Measurable`*. With context bounds, this constraint
is incredibly easy to express! We just need something like
`int2measure`, but polymorphic. Since `val` declarations can't be parameterized, we use a `def` instead.

**Implicit conversion III.** Define a an `implicit` function that converts values of one type to values of
another.

{% highlight scala %}
def option2measure[A: Measurable](x: A): Measurable[Option[A]] = {
  case None => 0
  case Some(x) => measure(x)
}
{% endhighlight %}

We're using quite a bit of syntactic sugar here. In addition to specifying an anonymous instance of a single-method
trait by an anonymous method (as we did with `int2measure`), we're also specifying this anonymous method by an anonymous
pattern match.

There's a problem with this. If we set `val x = Some(10)` and call `measure(x)`, then everything works fine.
But `measure(Some(10))` doesn't compile. That's because `Some(10)` has type `Some[Int]`, which isn't the
same as `Option[Int]` (although it is a subtype).

Instead of having `option2measure` produce a `Measurable[Option[A]]`,
we want it to produce an instance of `Measurable` for all subtypes of `Option[A]`.
In Scala, a constraint of this kind can be expressed by an *upper bound* using `<:`. We'll have to
introduce another type parameter `B` for this.

{% highlight scala %}
// MeasurableClient.scala

object MeasurableClient {
  // ...
  implicit def measureOption[A: Measurable, B <: Option[A]]: Measurable[B] =
    (x: B) => if (b.get == None) "None" else b.get.measure
}
{% endhighlight %}

Function signatures like this one can be somewhat daunting at first but are incredibly informative.
All we're saying is that, given any `A` that is a member of `Measurable`, we can implicitly define
an instance of `Measurable[B]` for any subtype `B` of `Option[A]`.

## Implicit classes

One more thing we can do is use implicit *classes*
to automatically convert objects that are members of `Measurable` to objects with a `measure` *method*.

**Implicit conversion IV.** Define an `implicit` class. Such a class can implicitly convert from
the type of its constructor parameter to the class that it itself defines.

{% highlight scala %}
// Measurable.scala
// ...

object Measurable {
  implicit class MeasurableOps[A: Measurable](x: A) {
    def measure: Double = Measurable.measure(x)
  }
}
{% endhighlight %}

Now we can call `10.measure` or `Some(10).measure` and it will behave as expected! In a way, we've "implicitly" extended
the `Int` class and `Some[A]` (for `A: Measurable`) classes.

Let's think about how this works. When `10.measure` is called, the compiler looks for a `measure` method in the `Int`
class. It doesn't find one, so it looks in the implicit scope for *an implicitly defined type that has a `measure`
method and to which `Int` can be converted*. It finds the implicit class `MeasurableOps` and sees that `MeasurableOps`
requires a parameter of a type `A` that is a member of `Measurable`. Since `A = Int`, the compiler looks for
an implicit conversion of `Int` to `Measurable` and finds[^2] `int2measure`. It passes `10` explicitly and `int2measure` implicitly
to the constructor of `MeasurableOps`, which returns a new `MeasurableOps` object equipped with a method `measure`. Since
`implicitly[Measurable[A]]` is bound to the implicit constructor parameter `int2measure`, the `measure` method of this new
object calls `int2measure.measure(10)`.

## What's next?

Next time, I'll discuss higher-kinded types and the `Functor` and `Monad` type classes.


[^1]: Indeed, [traits compile to interfaces](https://www.scala-lang.org/news/2.12.0-RC1/).

[^2]: One sometimes says that the type checker has *proved* that `Int` is a member of `Measurable`, i.e. that the requirement `Int: Measurable` can be satisfied.