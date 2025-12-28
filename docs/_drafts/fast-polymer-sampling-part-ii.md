---
title: "Fast polymer sampling, Part II: Intersection testing with balanced trees"
# date: 2025-11-08
categories: 
  - "math"
  - "programming"
tags: 
  - "probability"
---

This is the second post in a series discussing the problem of sampling the self-avoiding walk. In the [first post]({% post_url 2025-11-08-fast-polymer-sampling-part-i-markov-chains-and-hash-maps %}) I introduced and motivated this problem,
described and implemented a "naive" solution (the pivot algorithm), and discussed its performance characteristics. In particular,
I identified the main bottleneck as the self-intersection test. In this post, I'll describe a far more efficient way to check
for intersections introduced by [Nathan Clisby](https://clisby.net/). In the next post, I'll discuss my own implementation of Clisby's
algorithm that uses SIMD to obtain an additional performance boost.

My full implementation of the work described in this series can be found at
- [https://github.com/bencwallace/pivot](https://github.com/bencwallace/pivot)

## Tree representation

In this section, I'll go over the ideas from the following paper:

- [Clisby. _Efficient implementation of the pivot algorithm for self-avoiding walks_.](https://arxiv.org/abs/1005.1444)

Central to Clisby's method is a representation of walks as trees, with bounding box information attached to nodes. This data structure, which replaces the hash map (and array) from the naive implementation, improves the worst-case performance of the self-intersection test from linear to logarithmic.

**TODO: relation to R-Trees and methods in collision detection**

Previously, we took all our walks to start at the origin. For the tree-walk representation that follows, however, it's more convenient to let our walks start at the first unit vector
$$e_1 = (1, 0, 0, \ldots, 0)$$. The origin instead plays the role of a pivot point about which the walk can be transformed (rotated/reflected). Given two such walks (both starting at $$e_1$$),
a "left" walk and a "right" walk, a larger walk can be formed as follows. Start by taking the right walk, transform it, and translate its origin to the endpoint of the left walk.
The resulting right walk's start point will be one unit vector away from the left walk's endpoint, so they can now form a single walk (not necessarily self-avoiding).

This is illustrated in the diagram below, which is taken from Clisby's paper. In both diagrams, the origin is an unfilled (white) circle,
the walks' lattice sites are filled circles, and the steps (consecutive sites) are represented as lines connecting the sites.
There is also a dashed lined for each walk connecting the origin to the first site (which can otherwise be ambiguous).
Both diagrams illustrate the operation described above, the first using the identity transformation (denoted by the letter $$I$$),
the second using a rotation by $$\pi/2$$ ($$90^\circ$$ counter-clockwise, denoted by $$\curvearrowleft$$).
The upper diagram shows two 2-site (1-step) walks joined to form a 4-site (3-step) walk.
The lower diagram shows two 3-site walks joined to form a 6-step walk. 

![](/assets/posts/fast-polymer-sampling-part-ii/tree-construction.svg)

<!-- Any given walk can be represented as a tree by recursively dividing it in two: Given any point along the walk, there is a sub-tree "to the left" of that point and a sub-tree to the right.
The notions of left and right come from an ordering of points from start to end and we'll always take our walks to start at the first unit vector $$e_1 = (1, 0, 0, \ldots, 0)$$ (this choice turns out to be the most suitable for Clisby's method). In particular, we need to "forget" where the right sub-tree actually starts, i.e. we translate it back to $$e_1$$. In doing so, we also forget its position relative to the endpoint of the left sub-tree. In order to reconstruct the full walk then it's enough to remember two pieces of information corresponding to each node and its corresponding sub-tree (i.e. the sub-tree for which it is the root node):

- Each node carries its tree's endpoint.
- Each node carries the orientation of its right sub-tree relative to its left sub-tree. -->

Conversely, any walk can be represented as a tree by recursively dividing it in two and keeping track of the left sub-walk's endpoint
and the right sub-walk's "relative orientation", i.e. the transform needed to join it to the left sub-walk. The endpoint information can be attached to
the parent nodes of the left and right sub-trees (corresponding to the sub-walks) and the transform can be attached to the mutual parent node
connecting these two sub-trees.

<!-- The tree's steps can then be recursively reproduced as follows: Given left and right sub-trees, translate the right sub-tree to the left sub-tree's endpoint and re-orient it according to the information in the root node. This is best illustrated with a diagram from Clisby's paper. -->

Given the representations of points and transforms from the previous post

```cpp
template <int Dim> class point {
  std::array<int, Dim> coords_{};
};

template <int Dim> class transform {
  std::array<int, Dim> perm_;
  std::array<int, Dim> signs_;
};
```

the nodes making up this tree can be defined as the following data structure ([walk_node.h](https://github.com/bencwallace/pivot/blob/v1.0.2/src/include/walk_node.h)):

```cpp
template <int Dim> class walk_node {
  walk_node *left_;
  walk_node *right_;
  transform<Dim> symm_;
  point<Dim> end_;
};
```

The upshot of this representation is that it makes the pivot transformation especially simple, a fact that can most easily be seen when the pivot point happens to be the lattice site corresponding to the root of the tree. In this case, a pivot transformation merely changes the relative orientations of left and right sub-trees. This means the only thing that changes is the transform `symm_` at the root node, which gets right-multiplied by the lattice transform coming from the pivot transformation itself.

In other words, **under this representation, a pivot about the root node is a constant time operation**. Of course, we haven't discussed the real bottleneck yet (the intersection test). But this is still a major improvement over the naive walk representation, for which a pivot transformation
(without checking for intersections) requires a linear number of operations (each point "to the right" must be modified).

### Non-uniqueness, tree rotations, and pivot transform

The obvious problem now is how to perform a pivot transformation at a non-root node. To answer this, it's important to understand the non-uniqueness of the tree representation. This stems from the arbitrary way in which we recursively split the walk to begin with: We never said the walk needed to be split exactly at the center. In fact, the split can be performed anywhere. Splitting at or near the center is only necessary if we want to end up with a balanced tree. What this means is that **any point on the walk can serve as the root of the tree**.

Rather than rebuilding the tree from scratch every time we want to perform a pivot move, it would be better to find a minimal sequence of local tree transformations such that the desired node becomes the root. To devise such a mechanism, it's best to start with a very simple tree, consisting of 3 points: $$(1, 0), (2, 0), (3, 0)$$. There are two possible ways to split this walk in two.

If we "split" the walk between $$(2, 0)$$ and $$(3, 0)$$, the right sub-tree consists of a single leaf node (corresponding to the point $$(3, 0)$$) while the left sub-tree captures the 2-point sub-walk $$(1, 0), (2, 0)$$. This is shown in the diagram on the left below. The leaf nodes have been labeled with the points along the walk that they correspond to. The non-leaf nodes have been labeled with the angle by which the right sub-walk should be rotated before connecting it to the left sub-walk.

Alternatively, if we split the walk between $$(1, 0)$$ and $$(2, 0)$$, we end up with the tree shown in the diagram on the right below.

|**TODO: fix endpoints** | |
|-|-|
|![](/assets/posts/fast-polymer-sampling-part-ii/left.svg)|![](/assets/posts/fast-polymer-sampling-part-ii/right.svg)|

The operation that transforms trees resembling the one on the left to those resembling ones on the right is known as a left-rotation.
In the example above, we started with a tree that allowed us to easily perform a pivot move about $$(2, 0)$$ and ended up with one that allowed us to pivot about $$(1, 0)$$.

**TODO: non-uniqueness of representation, left/right rotations**

**TODO: pivot at non-root via shuffle up (repeated rotations)**

## Bounding boxes for intersection testing

**TODO: bounding boxes and intersection testing**

## Extras/optimizations

### Staying balanced

**TODO: maintaining balance via shuffle down**

### Quitting early

**TODO: mention shuffle-intersect & problems encountered**

## Performance and applications

**TODO: mention Clisby's performance analysis**
**TODO: determining critical exponents**
