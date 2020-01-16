---
layout: post
title:  "Implementing type classes in Scala I"
date:   2020-01-15 00:37:44 +0100
categories: scala typeclasses polymorphism
---

I've been learning Scala recently and have been very impressed with the power of some of
its features as well as the way in which it seamlessly combines object-oriented
and functional programming. Nevertheless, some of these features can seem a bit
tricky and learning resources can be relatively hard to find. In particular, I had some
difficulty wrapping my head around *implicits*. Things came together when I began to
ask myself: what are the analogs of Haskell's type classes in Scala?

It turns out that, unlike
in Haskell, type classes are not built-in to the language; rather, they can be *implemented*
using implicits. Because of this, they're actually more powerful than in Haskell: you can,
for example, create multiple coexisting type class instances and pass them around as objects.
Moreover, due to Scala's object-oriented nature, type classes can
inherit from one another.

Note that there already exist some Scala libraries, such as
[Scalaz](https://github.com/scalaz/scalaz), that develop many useful type classes,
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

In this post, I'll start by discussing type classes and implicits, then I'll explain how to implement
the `Show` type class in Scala and how to make ordinary types like `Int` and `String` members of it.
This will lead to a discussion of context bounds, which will allows us to add type constraints
(`Option` as a member of `Show`). In the following post, I'll introduce higher-kinded types and
show how to implement functors and monads.


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
the value `None` or the value `Some(a)` for any value `a` of type `A`. For example, you could write a function
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

## Scala implicits

Implicits obviate the need to (explicitly) cast or convert objects from one type to another. In fact,
this is how Scala deals with different numerical types: when you pass, say, an `Int` to a function of a
`Double`, [Scala](https://github.com/scala/scala/blob/v2.11.8/src/library/scala/Int.scala#L474) performs
an implicit conversion (this is necessary because `Int` is not a subtype of `Double`).

There are several ways to define implicit conversions. Rather than provide an exhaustive explanation,
I'll sprinkle these throughout the post. Here's one way to do it.

**Implicit conversion I.** Define an `implicit` function or method that performs the implicit conversion

Suppose we wanted to pass an ordinary (non-option) value `a` to a function of an option and have it automatically
understood as `Some(a)`. Here's what we'd do.

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
**parametric polymorphism**. This isn't especially relevant right now, but will be good to know later.

## Beginning to define a type class

**Note.** Much of the following is based on [Type classes in Scala](https://scalac.io/type-classes-in-scala/).
Rather than just linking to that article, I thought it would be best to write up many of the ideas there using my own notation,
terminology, and project structure in order to better motivate and prepare you for the following posts.

If you've used Haskell before, you're probably familiar with the `Show` type class. Any type `T` that is a member
of `Show` can be passed to the `show` function, which returns a string. In other words, `show` determines how members
of a type should be displayed on the screen. In order to make a new class a member of `Show`, we need to define `show`
for that type. Let's implement `Show` in Scala.

{% highlight scala %}
// Show.scala

trait Show[A] {
  def show(a: A): String
}
{% endhighlight %}

That's pretty simple. The `Show` type class is just a trait with a single method. In fact, all the typeclases we define
will simply be traits. Now you might complain: *Traits are just Scala's versions of interfaces[^1]. So how is a type class
different from an interface?* As you'll see, type classes are different in how we use them. Rather than extending them,
we'll implement them *implicitly*.

## Instantiating type class members

Suppose we wanted to make `Int` a member of `Show`. Since `Int` is *already defined* elsewhere, we can't change it.
However, we can define a *separate* object that realizes the instance of `Show` we would like.

{% highlight scala %}
val int2show: Show[Int] = x => s"$x"
{% endhighlight %}

Here we've used a bit of syntactic sugar. Since `Show` contains only one abstract method, we can define an anonymous
class implementing it just by specifying how that method is implemented. Moreover, this method can be given as an
anonymous function (because it's name, `show`, is already determined). That's why the right-hand side looks like an
anonymous function (with the same signature as `show` when `A = Int`). We've also used Scala's
[string interpolation](https://docs.scala-lang.org/overviews/core/string-interpolation.html).

This is all well and good, but how does it help us?
Let's remind ourselves of what we're trying to accomplish. We'd like to be able to pass an `Int` to `Show.show`.
The latter is abstract, but we'd like it to be *implicitly defined* by `int2show.show`. We could call the latter
directly, but this isn't really satisfactory. For example, suppose `Show` implemented an implicit conversion
`string2show: Show[String]`. Now we'd have to call `string2show.show("hello")`. We'd like to be able to unify
the `show` methods of `int2show`, `string2show`, and so on into *a single function*.

### Ad hoc polymorphism

What we want is a *polymorphic*
function `show[A]` that works for any `A` *for which an instance of `Show[A]` exists*. This is *not* parametric
polymorphism, because the type `A` is constrained. We need some way to express this constraint.
This is where the notion of an implicit parameter comes in.

**Implicit conversion II.** Add an `implicit` parameter to the type signature of a function that may require
an implicit conversion.

Let's define our `show` function and then explain how it works.

{% highlight scala %}
// Show.scala
// ...

object Show {
  def show[A](a: A)(implicit showInstance: Show[A]): String =
    showInstance.show(a)
}
{% endhighlight %}

Even though `show` is generic, it takes an implicit parameter of type `Show[A]`. Because the parameter is implicit,
we don't have to explicitly pass in a value for it. Rather, the compiler will look for an implicit object in the
current scope that it can use, depending on the type parameter `A`. For instance, we would like it to be able to
find `int2show`, so we make that value implicit.

{% highlight scala %}
// ShowClient.scala

import Show._

object ShowInt {
  implicit val int2show: Show[Int] = x => s"$x"
}
{% endhighlight %}

Now if we call `show(10)` (with `int2show` in scope), the compiler will
automatically find `int2show` and pass it in as the value of `showInstance`; thus, `show(10)` will call
`int2show.show(10)`. Similarly, `show("hello")` would call `string2show.show("hello")`.

In a way, `show` is not fully generic even though it appears to be declared generically. Rather, `show[A](x)`
will only work for types `A` for which an instance `Show[A]` exists. This is the basic idea of
**ad hoc polymorphism**.

## Defining a type class

Putting together what we saw above, here's how we define the `Show` typeclass.

{% highlight scala %}
// Show.scala

trait Show[A] {
  def show(a: A): String
}

object Show {
  def show[A](a: A)(implicit showInstance: Show[A]): String =
    showInstance.show(a)
}
{% endhighlight %}

Essentially, a type class consists of a trait together with a companion object whose methods implicitly
implement the trait's methods via ad hoc polymorphism.

A member of a type class is an implicit instantiation of the trait.

## Context bounds

At this point we're basically done. We've implemented the `Show` type class and demonstrated how to make other
types members of it. However, there's a few things we get "for free" at this point that are worth discussing.

The type signature of `show` says that "`A` must have a type that implements the `Show`
type class". This precise idea can be expressed using the following syntactic sugar supported by Scala: instead of
declaring `show` as above, we write `def show[A: Show](a: A)`. The constraint `A: Show` is called a **context bound**.

Now if you try making that replacement, you'll encounter an issue on the right-hand side: `showInstance` is no
longer bound to anything. However, if `A` does have a `Show` instance (represented by an implementation of `Show[A]`),
an implicit parameter *will* be passed to `show` and can be retrieved within its scope by referring to
`implicitly[Show[A]]`. Thus, the definition of `show` becomes the following.

{% highlight scala %}
// Show.scala
// ...

object Show {
  def show[A: Show](a: A): String = implicitly[Show[A]].show(a)
}
{% endhighlight %}

This is not only cleaner, but better captures the fact that `show` does not use parametric polymorphism, but
rather ad hoc polymorphism.

## Type class membership with constraints

Equipped with our knowledge of context bounds, we can now also make `Option[A]` a member of `Show`... that is,
*so long as `A` itself is a member of `Show`*. With context bounds, this constraint
is incredibly easy to express! We just need something like
`int2show`, but polymorphic. Since `val` declarations can't be parameterized by types, we use a `def` instead.

**Implicit conversion III.** Define a an `implicit` function that converts values of one type to values of
another.

{% highlight scala %}
def option2show[A: Show](a: A): Show[Option[A]] = {
  case None => "None"
  case Some(a) => s"Some(${show(a)})"
}
{% endhighlight %}

We're using quite a bit of syntactic sugar here. In addition to specifying an anonymous instance of a single-method
trait by an anonymous method (as we did with `int2show`), we're also specifying this anonymous method by an anonymous
pattern match.

There's a problem with this. If we set `val x = Some(10)` and call `show(x)`, then everything works fine.
But `show(Some(10))` doesn't compile. That's because `Some(10)` has type `Some[Int]`, which isn't the
same as `Option[Int]` (although it is a subtype).

Instead of having `option2show` produce a `Show[Option[A]]`,
we want it to produce an instance of `Show` for all subtypes of `Option[A]`.
In Scala, a constraint of this kind can be expressed by an *upper bound* using `<:`. We'll have to
introduce another type parameter `B` for this.

{% highlight scala %}
// ShowClient.scala

object ShowClient {
  // ...
  implicit def showOption[A: Show, B <: Option[A]]: Show[B] =
    (b: B) => if (b.get == None) "None" else b.get.show
}
{% endhighlight %}

## Implicit classes

One more thing we can do is use implicit *classes*
to automatically convert objects that are members of `Show` to objects with a `show` *method*.

**Implicit conversion IV.** Define an `implicit` class. Such a class can implicitly convert from
the type of its constructor parameter to the class that it itself defines.

{% highlight scala %}
// Show.scala
// ...

object Show {
  implicit class ShowOps[A: Show](a: A) {
    def show: String = Show.show(a)
  }
}
{% endhighlight %}

Now we can call `10.show` or `Some(10).show` and it will behave as expected! In a way, we've "implicitly" extended
the `Int` class and `Some[A]` (for `A: Show`) classes.

Let's think about how this works. When `10.show` is called, the compiler looks for a `show` method in the `Int`
class. It doesn't find one, so it looks in the implicit scope for *an implicitly defined type that has a `show`
method and to which `Int` can be converted*. It finds the implicit class `ShowOps` and sees that `ShowOps`
requires a parameter of a type `A` that is a member of `Show`. Since `A = Int`, the compiler looks for
an implicit conversion of `Int` to `Show` and finds[^2] `int2show`. It passes `10` explicitly and `int2show` implicitly
to the constructor of `ShowOps`, which returns a new `ShowOps` object equipped with a method `show`. Since
`implicitly[Show[A]]` is bound to the implicit constructor parameter `int2show`, the `show` method of this new
object calls `int2show.show(10)`.

## What's next?

Next time, I'll discuss higher-kinded types and the `Functor` and `Monad` type classes.


[^1]: Indeed, [traits compile to interfaces](https://www.scala-lang.org/news/2.12.0-RC1/).

[^2]: One sometimes says that the type checker has *proved* that `Int` is a member of `Show`, i.e. that the requirement `Int: Show` can be satisfied.