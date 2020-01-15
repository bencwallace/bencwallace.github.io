---
layout: post
title:  "Implementing type classes in Scala I"
date:   2020-01-15 00:37:44 +0100
categories: scala type classes
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
for example, creating multiple coexisting type class instances and pass them around as objects.
Moreover, due to Scala's object-oriented nature, type classes can be made to
inherit from one another.

Note that there are already exist some Scala libraries, such as
[Scalaz](https://github.com/scalaz/scalaz) that develop many useful type classes,
but for the purpose of understanding how this is done, I think it's best to start from scratch.

**Prerequisites.** I will make use of some basic Scala features. Implicits are the only feature
I'll really explain. Most of the others are similar to ones found in Java (traits are like
interfaces, objects replace the `static` keyword). I do use options and some pattern matching,
which will be familiar if you've used a language in ML family (like Haskell) before. In the later
posts I'll implement functors and monads, but these won't be discussed in this post.

**Warning.** As I said above I'm still learning Scala and I may do things in slightly non-idiomatic
ways at times. I'm also not an expert on programming languages. If you find anything wrong or that
could be improved in this post, please let me know.

## Roadmap

In this post, I'll start by discussing type classes and implicits, then I'll show how to implement the
`Show` type class in Scala. Of course, I'll also show how to make instances of type classes, starting with
instantiation of ordinary types like `Int` and `String`. In later posts, I'll add type constraints
(`Option` as an instance of `Show`) and show how to implement type classes for type constructors (`Option`
as an instance of `Functor` and `Monad`). Along the way, we'll see how a number of interesting Scala features
and programming language concepts come together, including: parametric and ad hoc polymorphism, context bounds,
and Scala `for` comprehensions.


## Why type classes?

Rather than giving a general explanation of what type classes are, I'll try to explain some of the basic
ideas in the examples that follow. Much better introductions to type classes than I could write,
can easily be found online. All I'll say here is that type classes are "like (Java) interfaces"
but much more general and powerful. In particular, we'll see the following examples of what
type classes can do that interfaces can't:

1. Types can be made instances of type classes outside of their own definitions; this means, for
  example, that we can instantiate type class instances for built-in types.
2. Type class instantiation of parameterized types can be specialized depending on the type parameter.
3. So-called "higher-kinded" types can be made instances of type classes.

## Scala implicits

Implicits obviate the need to (explicitly) cast or convert objects from one type to another. In fact,
this is how Scala deals with different numerical types: when you pass, say, an `Int` to a function of a
`Double`, [Scala](https://github.com/scala/scala/blob/v2.11.8/src/library/scala/Int.scala#L474) performs
an implicit conversion (this is necessary because `Int` is not a subtype of `Double`).

There are several ways to define implicit conversions. Rather than provide an exhaustive explanation,
I'll sprinkle these throughout the post. Here's one way to do it.

***Implicit conversion I.*** Define an `implicit` function or method that performs the implicit conversion

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
The compiler then replaces our ordinary function call `f(10)` by `f(any2option(x))`.

Note that if we called `f(Some(10))`, the compiler would *still* print "10" to the screen (rather than "Some(10)")
because an implicit conversion is not necessary (hence not used) in this case.

**Terminology.** The fact that `any2option` works with parameters of any type is referred to as
**parametric polymorphism**. This isn't especially relevant right now, but will be good to know later.

## The `Show` type class

**Note.** The rest of this post closely follows [Type classes in Scala](https://scalac.io/type classes-in-scala/).
Rather than just linking to that article, I thought it would be best to write up many of the ideas there using my own notation,
terminology, and project structure in order to better motivate and prepare you for the following posts.

If you've used Haskell before, you're probably familiar with the `Show` type class. Any type `T` that is an instance
of `Show` can be passed to the `show` function, which returns a string. In other words, `show` determines how members
of a type should be displayed on the screen. In order to make a new class a member of `Show`, we need to define `show`
for that type. Let's implement `Show` in Scala.

{% highlight scala %}
// we'll start our code snippets with a comment indicating the file name

// Show.scala

trait Show[A] {
  def show(a: A): String
}
{% endhighlight %}

That's pretty simple. The `Show` type class is just a trait with a single method. In fact, all the typeclases we define
will simply be traits. Now you might complain: *Traits are just Scala's versions of interfaces[^1]. So how is a type class
different from an interface?* As you'll see, type classes are different in how we use them. Rather than extending them,
we'll implement them *implicitly*.

## Instantiating typeclass members

Suppose we wanted to make `Int` a member of `Show`. Since `Int` is *already defined*, we can't simply throw
in `extends Show` or `with Show` to the declaration of `Int`. Part of the power of of implicits and typeclasses is that
we can nevertheless make `Int` an instance of `Show`. All we need is an implicit conversion from `Int` to `Show[Int]`.
We start with the following.

{% highlight scala %}
// Show.scala

object Show {
  implicit val int2show: Show[Int] = x => s"$x"
}
{% endhighlight %}

Here we've used a bit of syntactic sugar. Since `Show` contains only one abstract method, we can define an anonymous
class implementing just by specifying how that method is implemented. Moreover, this method can be specified as an
anonymous function (because it's name, `show`, is already specified). That's why the right-hand side looks like an
anonymous function (with the same signature as `show` when `A = Int`). We've also used Scala's
[string interpolation](https://docs.scala-lang.org/overviews/core/string-interpolation.html).

Note that we've placed our implicit conversion inside the `Show` trait's companion object. Think of it this way:
we, the implementers of the `Show` typeclass, are specifying a "default" instance for a common type. A client would
still have to import this implementation in order to use. The necessity of such an import might seem like extra
boilerplate, but in fact it allows a client to choose *not* to import our instance and instead define their own.
This is an example of how, unlike in Haskell, a typeclass can have multiple instances that coexist.

**Ad hoc polymorphism**

Our definition isn't complete yet. Right now, in order to show an integer, we have to do the following. Let's take
the perspective of a client of `Show` and make a new file.

{% highlight scala %}
import Show._

object Main {
  def main(args: Array[String]): Unit = {
  println(showInt.show(10))
}
{% endhighlight %}

Now suppose we wanted to show some other type, like a string. Suppose `Show` implemented an implicit conversion
`showString: Show[String]`. Now we'd have to call `showString.show("hello")`. This is unfortunate because we
have to call a different function for each type we want to show. We can't necessarily make a generic `showAny`
method because not all types are necessarily showable (e.g. function types). This is where the notion of an
implicit parameter comes in.

***Implicit conversion III.*** Add an `implicit` parameter to the type signature of a function that may require
an implicit conversion.

{% highlight scala %}
// Show.scala

object Show {
  // ...

  def show[A](a: A)(implicit showInstance: Show[A]): String =
    showInstance.show(a)
}
{% endhighlight %}

Even though `show` is generic, it takes an implicit parameter of type `Show[A]`. Because the parameter is implicit,
we don't have to explicitly pass in a value for it. Rather, the compiler will look for an implicit object in the
implicit scope that it can use, depending on the type parameter `A`. If we call `show(10)`, the compiler will
automatically find `showInt` and pass it in as the value of `showInstance`; thus, `show(10)` will call
`showInt.show(10)`. Similarly, `show("hello")` would call `showString.show("hello")`.

In a way, `show` is not fully generic even though it appears to be declared generically. Rather, `show[A](x)`
will only work for values of `x` for which an instance of `Show[Int]` can be found. This is the basic idea of
**ad hoc polymorphism**. The type signature of `show` says that "`a` must have a type that implements the `Show`
typeclass". This precise idea can be expressed using the following syntactic sugar supported by Scala: instead of
declaring `show` as above, we write `def show[A: Show](a: A)` (this is called a **context bound**).

Now if you try making that replacement, you'll encounter an issue on the right-hand side; `showInstance` is no
longer bound to anything. However, if `A` does have a `Show` instance (represented by an instance of `Show[A]`),
an implicit parameter *will* be passed to `show` and can be retrieved within its scope by referring to
`implicitly[Show[A]]`. Thus, the definition of show becomes the following.

{% highlight scala %}
// Show.scala

object Show {
  // ...
  // replace the previous definition of `show` by the following
  def show[A: Show](a: A): String = implicitly[Show[A]].show(a)
}
{% endhighlight %}

This is not only cleaner, but better captures the fact that `show` does not use parametric polymorphism, but
rather ad hoc polymorphism.

**Making things object-oriented**

There's still something a bit unsatisfying about this. Initially, we declared `show` as an abstract `method`
of `Show`. But now we're using it as a function. If we declared a new type, we might be tempted to simply
let it extend the `Show` trait and override the `show` *method*. It turns out we can use implicit *classes*
to automatically convert objects with an instance of `Show` to objects with a `show` method.

***Implicit conversion IV.*** Define an `implicit` class. Such a class behaves as a type conversion from
the type of the object passed to its constructor to its own type.

{% highlight scala %}
// Show.scala

object Show {
  // ...
  // dispense with the `show` method define above entirely
  // do the following instead
  implicit class ShowOps[A: Show](a: A) {
    def show: String = implicitly[Show[A]].show(a)
  }
}
{% endhighlight %}

Now we can call `10.show` and it will behave as expected! In a way, we've "implicitly" extended the `Int` class.

Let's think about how this works. When `10.show` is called, the compiler looks for a `show` method in the `Int`
class. It doesn't find one, so it looks in the implicit scope for *an implicitly defined type that has a `show`
method and to which `Int` can be converted*. It finds the implicit class `ShowOps` and sees that `ShowOps`
requires an a parameter of a type `A` that has an instance of `Show`. Since `A = Int`, the compiler looks for
an implicit conversion of `Int` to `Show` and finds[^2] `showInt`. It passes `10` explicitly and `showInt` implicitly
to the constructor of `ShowOps`, which returns a new `ShowOps` object equipped with a method `show`. Since
`implicitly[Show[A]]` is bound to the implicit constructor parameter `showInt`, the `show` method of this new
object calls `showInt.show(10)`.

# What's next?

Next time, I'll discuss how to make `Option` an instance of `Show`, higher-kinded types, and how to define a
`Functor` typeclass.


[^1]: Indeed, [traits compile to interfaces](https://www.scala-lang.org/news/2.12.0-RC1/).

[^2]: One sometimes says that the type checker has *proved* that `Int` is an instance of `Show`,
i.e. that the requirement `Int: Show` can be satisfied.