---
title: "Implementing typeclasses in Scala, Part II: Functors and monads"
date: 2020-01-19
tags: 
  - "functors"
  - "monads"
  - "polymorphism"
  - "typeclasses"
  - "types"
---

[Last time](/2020/01/implementing-type-classes-in-scala-i/) we saw how to implement a simple type class using Scala implicits. We also know how type classes as well generics allow us to harness the power and utility of abstraction.

Let's back up a bit. Suppose we're working in a statically typed language without generics. We might be able to implement a list of integers or a list of strings but for every new type contained by our list we would need a new implementation. Maybe we could get around this limitation (e.g. by using void pointers in C) but we would probably lose type safety. Generics provide the precise abstraction mechanism necessary to implement type safe lists.

Now let's move up one level of abstraction. Suppose we write a function that processes a list by returning its reversal. This would be a a generic function. However, we might also want to produce reversals of arrays. Arrays and lists are _different_ generic data types, but they share something in common: they can be _traversed_. It would be tedious to have to write different functions to process different kinds of traversable collections. Many languages get around this limitation by introducing _iterables_ via interfaces. But as we saw last time, interfaces can be somewhat rigid.

Functors provide a flexible way of unifying otherwise disparate "container-like" objects that can be transformed through operations on single elements. In fact, they are more general than iterables in that they don't require a notion of ordering on the elements (because of this, they are unsuitable replacements for iterables; however type classes such as [`Traversable`](https://wiki.haskell.org/Typeclassopedia#Traversable) exist for this purpose).

## Functors

A functor is a type whose values can be _mapped_ over by a function. In other words, any function `f: A => B` can be "lifted" to a function transforming a functor _of_ elements of type `A` to a functor of elements of type `B`. For instance, the `List` implementation of the `map` function would have the following signature.

```scala
def map[A, B](f: A => B)(list: List[A]): List[B]
```

As a convenience, we've _[curried](https://en.wikipedia.org/wiki/Currying)_ our definition: rather than taking two arguments, `map` takes a single argument `f` and produces a _function_ `List[A] => List[B]`. We can still apply `map` to two arguments at once, e.g. `map(f)(list)` but we've gained the option not to.

How do we generalize this to general functors? A first guess would be to introduce a new type parameter `F` and write `map` like this.

```scala
def map[F, A, B](f: A => B)(fa: F[A]): F[B]
```

But this won't work: for instance, we could set `F = Int` to get the nonsensical `Int[A]` in our type signature. We need to specify that `F` is a thing _like_ `List`.

### Type constructors and higher-kinded types

But what is `List`? Well, it's not really a type, at least not in the sense we usually understand. Rather, `List[A]` is a type for any `A`. Objects such as `List` are known as **type constructors**: they take a type or several types as input and produce a new type as output. This is sometimes expressed by saying that type constructors have **kind** `* -> *`. As you might have guessed, we could also define a more general type operator that has **kind** `(* -> *) -> *`. This isn't a type constructor as we've defined them because it's _input_ is a type constructor, not a type. Anything with a kind except for (proper) types (which have kind `*`) is known as a **higher-kinded type**.

In Scala, we can express the fact that `F` should be a type constructor by writing `F[_]`. We can now complete our definition of `map`; however, we'll make `F[_]` a parameter for the `Functor` trait since we're not just trying to define `map` but rather the `Functor` type class as a whole (aside: this means `Functor` has kind `(* -> *) -> *`).

```scala
// Functor.scala

trait Functor[F[_]] {
  def map[A, B](f: A => B)(fa: F[A]): F[B]
}
```

The next step in defining a type class is to provide a companion object for our trait with a definition of `map` that accepts a functor instance as an implicit parameter. While we're at it, let's throw in a `FunctorOps` class to make `Functor` members "inherit" the `map` method.

```scala
// Functor.scala

object Functor {
  def map[A, B, F[_]: Functor](f: A => B)(fa: F[A]): F[B] =
    implicitly[Functor[F]].map(f)(fa)

  implicit class FunctorOps[A, F[_]: Functor](fa: F[A]) {
    def map[B](f: A => B): F[B] = implicitly[Functor[F]].map(f)(fa)
  }
}
```

**Functor laws.** Functors are expected to obey the following laws. As with `Measurable`, these laws cannot be enforced by the type system. We're also using the `===` sign here to represent a mathematical notion of equality that can't be expressed in Scala.

```scala
map(identity) === identity
map(f compose g) === (map f) compose (map g)
```

## A tree datatype

Now we're going to want to instantiate some members of `Functor`. We already mentioned `List` and `Array` above but these are somewhat... underwhelming. After all, they already have a `map` method built in. I thought it would be more fun to make our own datatype to play with.

One potential example that comes to mind is the binary tree. These are certainly functors but we'd run into issues with them later because they have no canonical definition as monads. Instead, we'll use a variation of regular binary trees in which _only leaves carry values_. To be precise, these will consist of nodes, which may either _branch_ into two sub-trees _or_ have a value attached to them, but not both. To be even more precise, let's just write it up.

```scala
// Tree.scala

sealed trait Tree[A]
case class Leaf[A](x: A) extends Tree[A]
case class Branch[A](left: Tree[A], right: Tree[A]) extends Tree[A]
```

Our implementation of this [algebraic data type](https://en.wikipedia.org/wiki/Algebraic_data_type) using sealed traits and case classes is a [common pattern](https://docs.scala-lang.org/tour/pattern-matching.html) in Scala (this is also the way, for example, that `Option` and `List` is implemented).

It might be useful to print these trees in order to see what we're doing. We'll define a simple `toString` method (we could also use `Show`, but I'd rather get on with things) that prints trees out using a simple, [Lisp-like syntax](https://en.wikipedia.org/wiki/S-expression).

```scala
// Tree.scala

sealed trait Tree[A] {
  override def toString: String = this match {
    case Leaf(x) => x.toString
    case Branch(l, r) => s"(${l.toString} ${r.toString})"
  }
}
```

Let's also define a simple, concrete working example.

```scala
val tree: Tree[Int] =
  Branch(
    Branch(
      Leaf(1),
      Branch(Leaf(2), Leaf(3))),
    Branch(Leaf(4), Leaf(5)))
```

So `println(tree.toString)` will print `((1 (2 3)) (4 5))`.

## Trees as functors

Now that we have our datatype in place and that we know how to use implicits to create type class instances, most of the work is done. All we need is an implicit conversion to produce a `Functor[Tree]` instance. This instance will be defined by a `map` method that recursively applies its input method to the left and right subtrees until it hits a leaf. We don't even need context bounds here!

```scala
// FunctorClient.scala
import Functor._

object FunctorClient {
  implicit val tree2functor: Functor[Tree] = new Functor[Tree] {
    def map[A, B](f: A => B)(tree: Tree[A]): Tree[B] = tree match {
      case Leaf(x) => Leaf(f(x))
      case Branch(l, r) => Branch(map(f)(l), map(f)(r))
    }
  }
}
```

Let's take it for a spin. Run `println(tree.map(x => x * x))` to get `((1 (4 9)) (16 25))`.

## Monads

I'm not going to go into a lengthy explanation of monads here because this has been done in numerous other places. I quite like the explanation at [A Neighborhood of Infinity](http://blog.sigfpe.com/2006/08/you-could-have-invented-monads-and.html). Personally, I think that, rather than learning what monads are, one should learn monads "one at a time". By doing this, you discover that the notion of a monad is just like that of parameterized types or functors: it's an _abstraction_ that captures a common pattern in computational thinking. For explanations of some of the most common monads (ordered roughly by "difficulty"), see [A Catalog of Standard Monads](https://wiki.haskell.org/All_About_Monads#A_Catalog_of_Standard_Monads) at the Haskell Wiki.

I'll start with a first attempt at defining the `Monad` trait. I'll explain a bit of what it means later.

```scala
trait Monad[M[_]] {
  def ret[A](a: A): M[A]
  def bind[A, B](ma: M[A], f: A => M[B]): M[B]
}
```

The `Monad` type class has two abstract methods. The first of these, the "return method" `ret` usually has a simple or obvious implementation. The method that gives `Monad` its power is usually referred to as "bind" and provides a way of "chaining monadic computations". Essentially what this means is that `bind` knows how to "apply" a function `A => M[B]` to a monad `M[A]`. This might remind you of the `map` method from `Functor` and a good way to understand `bind` is to examine the relationship between `Monad` and `Functor`.

### Monads are functors

One of the first thing to know about monads is that they're functors. In Haskell, this is expressed using a class constraint `class Functor m => Monad (m :: * -> *)` (yes, I cheated a bit here: Haskell refines the type class hierarchy a bit more via `Applicative`). In Scala, such a constraint can be expressed with a context bound. Declaring `trait Monad[M[_]: Functor]` won't work because traits can't take parameters and context bounds are merely syntactic sugar for implicit parameters. We could work around this by replacing `trait` by `abstract class` but we can do even better.

By attempting to directly translate from Haskell to Scala, we've failed to take advantage of one of Scala's most central and useful features: object-oriented programming. `Monad` really should be a subtype of `Functor`; Haskell just doesn't have such a notion (note that there can be some [serious issues](https://typelevel.org/blog/2016/09/30/subtype-typeclasses.html) when subtyping typeclasses). In Scala, we can do this:

```scala
trait Monad[M[_]] extends Functor[M]
```

In particular, any member of `Monad` must not only implement `ret` and `bind` but also `map`. But there's a canonical way to define `map` in terms of `ret` and `bind`. Actually, if you stare at the type signatures of these three functions for a minute or two you'll probably see that there's pretty much just one way to do this. For this reason, I've taken the liberty of marking `map` as `final`.

```scala
// Monad.scala

trait Monad[M[_]] extends Functor[M] {
  def ret[A](a: A): M[A]
  def bind[A, B](ma: M[A], f: A => M[B]): M[B]

  final override def map[A, B](f: A => B)(ma: M[A]): M[B] =
    bind(ma, (a: A) => ret(f(a)))
}
```

### The monad typeclass

At this point, we know how to complete the implementation of `Monad`. As usual, we'll throw in an implicit `MonadOps` class. However, we'll rename this class's version of `bind` to `>>=` for consistency with Haskell syntax (and as a simple demonstration of how "operators" can be defined in Scala). We'll also let `MonadOps` inherit `map` from `FunctorOps`.

**Edit (27.01.2020).** We only include `bind` in `MonadOps` since `ret` doesn't act on (but rather returns) a monadic value.

```scala
// Monad.scala
import Functor._
// ...

object Monad {
  def ret[A, M[_]: Monad](a: A): M[A] =
    implicitly[Monad[M]].ret(a)

  def bind[A, B, M[_]: Monad](ma: M[A], f: A => M[B]): M[B] =
    implicitly[Monad[M]].bind(ma, f)

  implicit class MonadOps[A, M[_]: Monad](ma: M[A]) extends FunctorOps(ma) {
    def >>=[B](f: A => M[B]): M[B] = implicitly[Monad[M]].bind(ma, f)
  }
}
```

**Monad laws.** Monads are expected to obey the following laws. Note that w're using Scala's [infix notation](https://docs.scala-lang.org/style/method-invocation.html).

```scala
ret(x) >>= f === f(x)
m >>= ret === m
(m >>= f) >>= g === m >>= (x => f(x) >>= g)
```

You can verify that, with our definition of `map` in terms of `bind` and `ret`, the monad laws imply the functor laws.

## Trees as monads

Let's make trees into monads. We need some way to `bind` a tree `tree` to a function `f` that produces a new tree for every element of the old tree. The "obvious" way to do this is to "glue" the root of each new tree `f(x)` to the old tree _at the leaf_ `Leaf(x)` that produced this new tree.

```scala
// MonadClient.scala

object MonadClient {
  implicit val tree2monad: Monad[Tree] = new Monad[Tree] {
    override def ret[A](x: A): Tree[A] = Leaf(x)

    override def bind[A, B](tree: Tree[A], f: A => Tree[B]): Tree[B] =
      tree match {
        case Leaf(x) => f(x)
        case Branch(l, r) => Branch(bind(l, f), bind(r, f))
      }
  }
}
```

Try, for example, `println(tree >>= (x => Branch(Leaf(x), Leaf(x))))` to get `(((1 1) ((2 2) (3 3))) ((4 4) (5 5)))`.

## Another view of monads

We've seen how to provide a default `Functor` implementation for `Monad`, but if we're defining a `Monad` instance, we probably already had an implementation of `Functor` in mind. In other words, we already had an idea of how `map` should work and the default implementation above is more of a convenience. Now applying this implementation of `map` with `B` replaced by `M[B]` gives us a way of lifting a function `A => M[B]` to a function `M[A] => M[M[B]]`. This is _almost_ `bind`: all we need now is a way of "flattening" `M[M[B]]` to `M[B]`.

So given a definition for `map` and an appropriate `flatten` function, we could define `bind(ma, f) = flatten(map(f)(ma))`. This is why `bind` is sometimes (including in Scala) referred to as `flatMap`. On the other hand, given an implementation of `bind`, we could, in addition to defining `map`, also define `flatten`. The definition can be guessed from the type signature: `flatten(mmb) = bind(mmb, identity)`.

The precise way in which we define `Monad` is up to us. In fact, had we not marked `map` as `final`, you could actually provide a default implementation of `bind` in terms of `flatten` and `map` while giving the latter default implementations in terms of bind. This would be a **bad idea** though, because there would be no way to ensure that _either_ default had been overriden, which could lead to a stack overflow at runtime.

One last thing we'll do is add a `flatMap` method to `MonadOps`, which merely acts as a synonym for `bind`.

```scala
// Monad.scala
// ...

object Monad {
  // ...
  implicit class MonadOps[A, M[_]: Monad](ma: M[A]) extends FunctorOps(ma) {
    // ...
    def flatMap[B](f: A => M[B]): M[B] =
      implicitly[Monad[M]].bind[A, B](ma, f)
  }
}
```

The reason we've done this is it allows us to take advantage of Scala's [`for` comprehensions](https://docs.scala-lang.org/tour/for-comprehensions.html), which are just syntactic sugar for `flatMap` (they are Scala's analogue of Haskell's `do` notation). This is also a good reason to implement `MonadOps` at all.

Let's see how `for` comprehensions work by example. The leaves of the `results` tree constructed in the following example contain all possible results of subtracting or dividing 12 or 18 by 3 or 4. The first level of branching corresponds to a choice of left-hand side (12 or 18), the second level to a choice of right-hand side, and the third level to a choice of binary operation. We've used Scala's wildcard notation to pass the subtraction and division functions as arguments to `Leaf`.

```scala
// MonadClient.scala

object MonadClient {
  // ...
  val lhs: Tree[Double] = Branch(Leaf(12), Leaf(18))
  val rhs: Tree[Double] = Branch(Leaf(3), Leaf(4))
  val ops: Tree[(Double, Double) => Double] =
    Branch(Leaf(_ - _), Leaf(_ / _))
  val results: Tree[Double] = for {
    x <- lhs
    y <- rhs
    f <- ops
  } yield f(x, y)
}
```

Try `println(results)` to get `(((9.0 4.0) (8.0 3.0)) ((15.0 6.0) (14.0 4.5)))` in other words `(((12-3 12/3) (12-4 12/4)) ((18-3 18/3) (18-4 18/4)))`.

### Desugaring

To explain the last example some more, the `for` comprehension [desugars](https://en.wiktionary.org/wiki/desugar#Verb_2) to a sequence of flat maps (binds) followed by calling `map`.

```scala
val results = lhs >>= (x => rhs >>= (y => ops.map(f => f(x, y))))
```

This justifies the name `bind`: for instance, each value "contained" in the monad `rhs` is _bound_ to the variable `y`.

If you're familiar with Haskell, you probably know that `do` notation desugars to a sequence of binds followed by `return`. But since we defined `map` in terms of `ret`, we can simplify the above further to see that Scala's `for` is doing the same thing as Haskell's `do`.

```scala
val results = lhs >>= (x => rhs >>= (y => ops >>= (f => ret(f(x, y)))))
```

## What's next?

That's all for now. It could be fun to talk about [monad transformers](https://en.wikibooks.org/wiki/Haskell/Monad_transformers) next time. I'd also like to talk about monads in probability and statistics at some point. Let me know if you have any suggestions!
