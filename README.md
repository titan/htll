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

Sample
------

There is an iOS5 [project]("https://github.com/titan/GearCalc") which
demonstrates how to write an iOS App with HTLL.

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
of area inherited from parent and `bottom` gets the rest area. `ratio`
is a float between 0.0 to 1.0 (excluding 0.0 and 1.0).

Here is an example about `above`:

    (in (above (label '((text . "Hello")))
               (label '((text . "World"))) 0.5) 'self.view)

"Hello" will be placed on top of "World".

#### beside

    (beside left right ratio)

`beside` will place `left` on the left of `right`. `left` occupies
`ratio` percenter of area inherited from parent and `right` gets the
rest. `ratio` is a float between 0.0 and 1.0(excluding 0.0 and 1.0).

### ^^

    (^^ top bottom [margin])

`^^` will place `top` on the `bottom` and wrap it's real height and
`bottom` gets the rest area. There may be a gap (`margin`) between
`top` and `bottom`. `margin` is a integer greater than 1.

### vv

    (vv top bottom [margin])

`vv` acts as same as `^^` except that `top` gets the rest area
inherited from parent.

### <<

    (<< left right [margin])

`<<` will place `left` on the left of `right` and wrap it's real width
and `right` gets the rest area inherited from parent. There may be a
`margin` long gap between `left` and `right` if `margin` appears.

### >>

    (>> left right [margin])

`>>` acts as same as `<<` except that `left` gets the rest area
inherited from parent.

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

#### h...

    (h... children)

`h...` works like `hseq` except that it bases on `^^`. That means
children are layouted sequentially and each of them occupy their own
size of area, not share the area inherited from parent averagely.

#### v...

    (v... children)

`v...` works link `h...` but in vertical direction.

Views
-----

Views is what you want to layout in HTLL. Most of views have many
attributes, they are structured as an association list, you should
select and set them as your need.

### blank

`blank` is a fake view, it doesn't show any on the screen, just
occupies area inherited from parent. But it's useful when
layouting. For example, if you don't want to layout two visible view
so closed, you can insert a `blank` between them. e.g.

    (in (beside (label '((text . "Hello")))
                (beside blank
                        (label '((text . "World"))) 0.5) 0.3) 'self.view)

### control

`control` is an abstract view which means you cannot instance it in
HTLL. There are serveral views inherit `control`, they also get it's
attributes.

Attribute|Type
:-------|:------
enabled|boolean
selected|boolean
highlighted|boolean
content-vertical-alignment|center/top/bottom/fill
content-horizontal-alignment|center/left/right/fill

### view

`view` corresponds to UIView in iOS, and all views inherit from it.

Attribute|Type
:-------|:------
background-color|color
hidden|boolean
alpha|float
opaque|boolean
clips-to-bounds|boolean
clears-context-before-drawing|boolean
user-interaction-enabled|boolean
multiple-touch-enabled|boolean
exclusive-touch|boolean
autoresizing-mask|none/flexible-left-margin/flexible-width/flexible-right-margin/flexible-top-margin/flexible-height/flexible-bottom-margin
autoresizes-subviews|boolean
content-mode|see below
content-stretch|rect
content-scale-factor|float. This value is typically either 1.0 or 2.0.

Available content modes include:

- scale-to-fill
- scale-aspect-fit
- scale-aspect-fill
- redraw
- center
- top
- bottom
- left
- right
- top-left
- top-right
- bottom-left
- bottom-right

### scroll

`scroll` corresponds to UIScrollView in iOS.

Attribute|Type
:-------|:------
content-offset|point
content-size|size
content-inset|edge-insets
scroll-enabled|boolean
direction-lock-enabled|boolean
scroll-to-top|boolean
paging-enabled|boolean
bounces|boolean
always-bounces-vertical|boolean
always-bounces-horizontal|boolean
can-cancel-content-touches|boolean
delays-content-touches|boolean
deceleration-rate|float
indicator-style|default/black/white
scroll-indicator-insets|edge-insets
shows-horizontal-scroll-indicator|boolean
shows-vertical-scroll-indicator|boolean
zoom-scale|float
maximum-zoom-scale|float
minimum-zoom-scale|float
bounces-zoom|boolean

### label

`label` corresponds to UILabel in iOS.

Attribute|Type
:-------|:------
text|string
font|font
text-color|color
text-alignment|left/center/right
line-break-mode|word-wrap/character-wrap/clip/head-truncation/tail-truncation/middle-truncation
enabled|boolean
adjusts-font-size-to-fit-width|boolean
baseline-adjustment|align-baselines/align-centers/none
minimum-font-size|int
number-of-lines|int
highlighted-text-color|color
highlighted|boolean
shadow-color|color
shadow-offset|size

### button

`button` corresponds to UIButton in iOS. It inherits from `control`
and `view`.

Attribute|Type
:-------|:------
reverses-title-shadow-when-highlighted|boolean
title-for-state|(cons string control-state)
title-color-for-state|(cons color control-state)
title-shadow-color-for-state|(cons color control-state)
adjusts-image-when-highlighted|boolean
adjusts-image-when-disabled|boolean
shows-touch-when-highlighted|boolan
background-image-for-state|(cons image-named control-state)
image-for-state|(cons image-named control-state)
content-edge-insets|edge-insets
title-edge-insets|edge-insets
image-edge-insets|edge-insets

Available control states include:

1. normal
2. highlighted
3. disabled
4. selected
5. application
6. reserved

### image

`image` corresponds to UIImageView in iOS.

Attribute|Type
:-------|:------
image|image-named
highlighted-image|image-named
animation-images|(list image-named)
highlighted-animation-images|(list image-named)
animation-duration|float
animation-repeat-count|int
user-interaction-enabled|boolean
highlighted|boolean

### slider

`slider` corresponds to UISlider in iOS and inherits from `control`.

Attribute|Type
:-------|:------
value|float
minimum-value|float
maximum-value|float
continuous|boolean
minimum-value-image|image-named
maximum-value-image|image-named
minimum-track-tint-color|color
minimum-track-image-for-state|(cons image-named control-state)
maximum-track-tint-color|color
maximum-track-image-for-state|(cons image-named control-state)
thumb-tint-color|color
thumb-image-for-state|(cons image-named control-state)

### segmented-control

`segmented-control` correspends to UISegmentedControl in iOS and
inherits from `control`.

Attribute|Type
:-------|:------
items|(list string/image-named)
selected-segment-index|int
momentary|boolean
segmented-control-style|plain/bordered/bar/bezeled
apportions-segment-widths-by-content|boolean
tint-color|color
enabled-for-segment-at-index|(cons boolean int)
content-offset-for-segment-at-index|(cons size int)
width-for-segment-at-index|(cons float int)
background-image-for-state-bar-metrics|(list image-named control-state default/landscape-phone)
content-position-adjustment-for-segment-type-bar-metrics|(list offset any/left/center/right/alone default/landscape-phone)
divider-image-for-left-segment-state-right-segment-state-bar-metrics|(list image-named control-state control-state default/landscape-phone)
title-text-attributes-for-state|(cons (assoication list) control-state)

### text-field

`text-field` corresponds to UITextField in iOS and inherits from
`control`.

Attribute|Type
:-------|:------
text|string
placeholder|string
font|font
text-color|color
text-alignment|left/center/right
adjusts-font-size-to-fit-width|boolean
minimum-font-size|float
clears-on-begin-editing|boolean
border-style|none/line/bezel/rounded-rect
background|image-named
disabled-background|image-named
clear-button-mode|never/while-editing/unless-editing/always
left-view|view
left-view-mode|never/while-editing/unless-editing/always
right-view|view
right-view-mode|never/while-editing/unless-editing/always
input-view|view
input-accessory-view|view

### text-view

`text-view` corresponds to UITextView in iOS and inherits from
`scroll`.

Attribute|Type
:-------|:------
text|string
font|font
text-color|color
editable|boolean
data-detector-types|none/phone-number/link/address/calendar-event/all
text-alignment|left/center/right
selected-range|range
input-view|view
input-accessory-view|view

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

### Image

The only way to reference a image in HTLL is `(image-named name)`, it
returns the image object associated with the specified filename. This
method looks in the system caches for an image object with the
specified name and returns that object if it exists. If a matching
image object is not already in the cache, this method loads the image
data from the specified file, caches it, and then returns the
resulting object.

Further Work
------------

1. Support iOS5, iOS6 and iOS7
2. Research more effective layout method
3. Support more view type
