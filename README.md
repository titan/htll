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
just like the main function in C language. Primitives belong to basic
class are atomic, they can combine to more complex layout
primitives. Advanced primitives are some common patterns of combining
basic primitives, they are made for convenience.

### Top-Level Primitive

There are only one primitive, `in`, in the top-level class.

    (in child parent)

`child` represents what and how we want to layout interface. Usually,
`child` is a advanced primitive, but it can be any primitives(except
the top-level primitive) or any views.

`parent` represents where we want to layout interface. General, we take
“self.view” as our canvas, it's the root view of a view controller. If
you want to layout in a subview of "self.view", you can replace it as
you wish.

A hello world style HTLL source code looks like this:

    (in (label '((text . "Hello World"))) 'self.view)

Attention, HTLL is a scheme-like language, so we need add `'` in front
of "self.view" to make sure it's a symbol.

### Basic Primitives

#### above

    (above top bottom ratio)

`above` will place `top` on the `bottom`, and occupy `ratio` percent
of area inherited from parent. `bottom` gets the rest area. Here,
`top` and `bottom` can be a basic primitive, a advanced primitive, or
a view. `ratio` is a float between 0.0 to 1.0.

Here is an example about `above`:

    (in (above (label '((text . "Hello")))
               (label '((text . "World"))) 0.5) 'self.view)

"Hello" will be placed on top of "World".

#### beside

    (beside left right ratio)

`beside` will place `left` on the left of `right`. Like `top` in
`above`, `left` occupies `ratio` percenter of area inherited from
parent, and `right` gets the rest. `ratio` has the same meaning as in
`above`.

### Advanced Primitives

For complex interfaces, a single `above` or `beside` primitive is not
enough, but you can combine them together to match the
requirement. Consider a simple name input form in there are a name
label, a text field and a confirm button. You can layout them like
this:

    (in (beside (label '((text . "Name")))
                (beside (text-field '())
                        (button '(())) 0.8) 0.3) 'self.view)

See, it's easy. But you should pay attention to those two
`ratio`s. The `ratio` in the first `beside` means that label gets 30%
width of `self.view`, and the `ratio` in the second one means the text
field gets 56% width of `self.view`. The second `beside` is `0.7 *
self.view`, so the text field is `0.8 * 0.7 * self.view`.

There are many ways to combine basic primitives, I just refined some
common patterns as advanced primitives.

#### center

    (center child h-ratio v-ratio)

`center` is the first advanced primitive I want to introduce. It
places the child, a view or a primitive, in the center of area
inherited from parent. h-ratio is ratio of horizental padding,
correspondingly, v-ratio is ratio of vertical padding.

#### hseq

    (hseq children)

`hseq` layout children sequentially in horizental direction. Here is
an example:

    (in (hseq (label '((text . "Hello")))
              (label '((text . "World")))
              (label '((text . "!")))) 'self.view)

Each label gets 33% width of `self.view`.

#### vseq

    (vseq children)

`vseq` is just like `hseq` but in vertical direction.

Views
-----

Resources
---------

Resources are special data types in HTLL, they cannot be layouted but
can be referenced by any view. The reason they occurs in HTTL is that
we need decorate views with them like what we do in object-c.

### Color

Predefined colors include:

- black-color
- darkGray-color
- lightGray-color
- white-color
- gray-color
- red-color
- green-color
- blue-color
- cyan-color
- yellow-color
- magenta-color
- orange-color
- purple-color
- brown-color
- clear-color
- light-text-color
- dark-text-color
- group-table-view-background-color
- view-flipside-background-color
- scroll-view-textured-background-color
- under-page-background-color

The following code is to layout a red label in `self.view`:

    (in (label '((text . "Hello World")
                 (text-color . red-color))) 'self.view)

There are two customize color definition functions if above predefined
colors don't satisfy your requirement.

    (hsba-color hue saturation brightness alpha)
    (rgba-color red green blue alpha)

- The hue component of the color object in the HSB color space,
  specified as a value from 0.0 to 1.0.
- The saturation component of the color object in the HSB color space,
  specified as a value from 0.0 to 1.0.
- The brightness (or value) component of the color object in the HSB
  color space, specified as a value from 0.0 to 1.0.
- The alpha(opacity) value of the color object, specified as a value
  from 0.0 to 1.0.
- The red component of the color object, specified as a value from 0.0
  to 1.0.
- The green component of the color object, specified as a value from
  0.0 to 1.0.
- The blue component of the color object, specified as a value from
  0.0 to 1.0.

Rewrite above example with `rgba-color` like this:

    (in (label `((text . "Hello World")
                 (text-color . ,(rgba-color 1 0 0 1)))) 'self.view)

### Font

You can use 4 functions to create font for text views:

- `(font name size)`

    This function creates and returns a font object for the specified
    font name and size.

- `(system-font-with-size size)`

    This function returns the font object used for standard interface
    items in the specified size.

- `(bold-system-font-of-size size)`

    This function returns the font object used for standard interface
    items that are rendered in boldface type in the specified size.

- `(italic-system-font-of-size size)`

    This function returns the font object used for standard interface
    items that are rendered in italic type in the specified size.

There are 4 auxiliary functions to help you get the suitable font size
of view:

- `(label-font-size)`

    This function returns the standard font size used for labels.

- `(button-font-size)`

    This function returns the standard font size used for buttons.

- `(small-system-font-size)`

    This function returns the size of standard small system font.

- `(system-font-size)`

    This function return the size of standard system font.

All above 4 function have no argument.

A simple example show you how to use font resource:

    (in (label `((text . "font")
                 (font . ,(system-font-of-size (system-font-size)))))
        'self.view)

Sample
------

Further Work
------------

1. Support iOS5, iOS6 and iOS7
