HTLL
====

HTLL(How To Layout Language) is a domain-specific language(DSL)
designed to layout views for iOS apps and try to reduce complexity of
developing iOS apps without xcode. It bases on Scheme syntax and
borrows layouting idea from
http://www.ibm.com/developerworks/cn/java/j-lo-uidsl/ (in
Chinese). The core part of HTLL is a Scheme interpreter comes from
SICP which read the layout source code and produces the corresponding
code can be included in object-c code.

Build
-----

HTLL runs on [Guile](http://www.gnu.org/software/guile/) or [Petite
Chez Scheme](http://www.scheme.com/petitechezscheme.html). So before
building it, you need to install one of them first. After that, edit
`Makefile.local` file and write down the scheme implementation you
have chosen like this:

    SCHEME:=guile

or

    SCHEME:=petite

Now, it's ready to make it by running `make` command. `htllc`(htll
compiler) is the product of building. It's a single file program, no
home, can be deployed to /usr/local/bin/ easily.

Layout Primitives
-----------------

HTLL uses serval primitives to layout interface. Those primitives can
be grouped into 3 classes: top-level primitive, basic primitives and
advanced primitives. The top-level primitive is entrance of layouting,
just like the main function in C programs. Primitives belong to basic
class are atomic, they can combine to more complex layout
primitives. Advanced primitives are some common patterns of combining
basic primitives, they are made for convenience.

### Top-Level primitive

There are only one primitive, `in`, in the top-level class.

    (in child parent)

`child` presents what and how we want to layout interface. Usually,
`child` is a advanced primitive, but it can be any primitives(except
the top-level primitive) or any views.

`parent` presents where we want to layout interface. General, we take
“self.view” as our canvas, it's the root view of a view controller. If
you want to layout in a subview of "self.view", you can replace it as
you wish.

A hello world style HTLL source code looks like this:

    (in (label '((text . "Hello World"))) 'self.view)

Attention, HTLL is a scheme-like language, so we need add "'" in front
of "self.view" to make sure it's a symbol.

Views
-----

Sample
------

Further Work
------------
