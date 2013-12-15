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

- enabled

    A Boolean value that determines whether the receiver is enabled.

- selected

    A Boolean value that determines whether the receiver is
    highlighted.

- highlighted

    A Boolean value that determines whether the receiver is highlighted.

- content-vertical-alignment

    The vertical alignment of content (text or image) within the
    receiver. Available values include:

    1. center
    2. top
    3. bottom
    4. fill

- content-horizontal-alignment

    The horizontal alignment of content (text or image) within the
    receiver. Available values include:

    1. center
    2. left
    3. right
    4. fill

### view

`view` corresponds to UIView in iOS, and all views inherit from it.

- background-color

    The receiver’s background color.

- hidden

    A Boolean value that determines whether the receiver is hidden.

- alpha

    The receiver’s alpha value. A float value.

- opaque

    A Boolean value that determines whether the receiver is opaque.

- clips-to-bounds

    A Boolean value that determines whether subviews are confined to
    the bounds of the receiver.

- clears-context-before-drawing

    A Boolean value that determines whether the receiver’s bounds
    should be automatically cleared before drawing.

- user-interaction-enabled

    A Boolean value that determines whether user events are ignored
    and removed from the event queue.

- multiple-touch-enabled

    A Boolean value that indicates whether the receiver handles
    multi-touch events.

- exclusive-touch

    A Boolean value that indicates whether the receiver handles touch
    events exclusively.

- autoresizing-mask

    An integer bit mask that determines how the receiver resizes
    itself when its superview’s bounds change. Available values
    include:

    1. none
    2. flexible-left-margin
    3. flexible-width
    4. flexible-right-margin
    5. flexible-top-margin
    6. flexible-height
    7. flexible-bottom-margin

- autoresizes-subviews

    A Boolean value that determines whether the receiver automatically
    resizes its subviews when its bounds change.

- content-mode

    A flag used to determine how a view lays out its content when its
    bounds change.

- content-stretch

    The rectangle that defines the stretchable and nonstretchable
    regions of a view. A rect value.

- content-scale-factor

    The scale factor applied to the view. This value is typically
    either 1.0 or 2.0.

### scroll

`scroll` corresponds to UIScrollView in iOS.

- content-offset

    The point at which the origin of the content view is offset from
    the origin of the scroll view. A point value.

- content-size

    The size of the content view. A size value.

- content-inset

    The distance that the content view is inset from the enclosing
    scroll view. An edge-insets value.

- scroll-enabled

    A Boolean value that determines whether scrolling is enabled.

- direction-lock-enabled

    A Boolean value that determines whether scrolling is disabled in a
    particular direction.

- scroll-to-top

    A Boolean value that controls whether the scroll-to-top gesture is
    effective.

- paging-enabled

    A Boolean value that determines whether paging is enabled for the
    scroll view.

- bounces

    A Boolean value that controls whether the scroll view bounces past
    the edge of content and back again.

- always-bounces-vertical

    A Boolean value that determines whether bouncing always occurs
    when vertical scrolling reaches the end of the content.

- always-bounces-horizontal

    A Boolean value that determines whether whether bouncing always
    occurs when horizontal scrolling reaches the end of the content
    view.

- can-cancel-content-touches

    A Boolean value that controls whether touches in the content view
    always lead to tracking.

- delays-content-touches

    A Boolean value that determines whether the scroll view delays the
    handling of touch-down gestures.

- deceleration-rate

    A floating-point value that determines the rate of deceleration
    after the user lifts their finger.

- indicator-style

    The style of the scroll indicators. Available styles include:

    1. default
    2. black
    3. white

- scroll-indicator-insets

    The distance the scroll indicators are inset from the edge of the
    scroll view. A edge-insets value.

- shows-horizontal-scroll-indicator

    A Boolean value that controls whether the horizontal scroll
    indicator is visible.

- shows-vertical-scroll-indicator

    A Boolean value that controls whether the vertical scroll
    indicator is visible.

- zoom-scale

    A floating-point value that specifies the current scale factor
    applied to the scroll view's content.

- maximum-zoom-scale

    A floating-point value that specifies the maximum scale factor
    that can be applied to the scroll view's content.

- minimum-zoom-scale

    A floating-point value that specifies the minimum scale factor
    that can be applied to the scroll view's content.

- bounces-zoom

    A Boolean value that determines whether the scroll view animates
    the content scaling when the scaling exceeds the maximum or
    minimum limits.

### label

`label` corresponds to UILabel in iOS.

- text

    The text displayed by the label. A string value.

- font

    The font of the text.

- text-color

    The color of the text.

- text-alignment

    The technique to use for aligning the text. Availabel values are:

    1. left
    2. center
    3. right

- line-break-mode

    The technique to use for wrapping and truncating the label’s
    text. Available modes are:

    1. word-wrap
    2. character-wrap
    3. clip
    4. head-truncation
    5. tail-truncation
    6. middle-truncation

- enabled

    The enabled state to use when drawing the label’s text.

- adjusts-font-size-to-fit-width

    A Boolean value indicating whether the font size should be reduced
    in order to fit the title string into the label’s bounding
    rectangle.

- baseline-adjustment

    Controls how text baselines are adjusted when text needs to shrink
    to fit in the label. Available adjustments are:

    1. align-baselines
    2. align-centers
    3. none

- minimum-font-size

    The size of the smallest permissible font with which to draw the
    label’s text.

- number-of-lines

    The maximum number of lines to use for rendering text. A integer
    value.

- highlighted-text-color

    The highlight color applied to the label’s text.

- highlighted

    A Boolean value indicating whether the receiver should be drawn
    with a highlight.

- shadow-color

    The shadow color of the text.

- shadow-offset

    The shadow offset (measured in points) for the text. A size value.

### button

`button` corresponds to UIButton in iOS. It inherits from `control`
and `view`.

- reverses-title-shadow-when-highlighted

    A Boolean value that determines whether the title shadow changes
    when the button is highlighted.

- title-for-state

    Sets the title to use for the specified state. A pair of a string
    and a control state. Available control states include:

    1. normal
    2. highlighted
    3. disabled
    4. selected
    5. application
    6. reserved

- title-color-for-state

    Sets the color of the title to use for the specified state. A pair
    of a color and a control state. Available control states are same
    as what in title-for-state.

- title-shadow-color-for-state

    Sets the color of the title shadow to use for the specified
    state. The same type as in title-color-for-state.

- adjusts-image-when-highlighted

    A Boolean value that determines whether the image changes when the
    button is highlighted.

- adjusts-image-when-disabled

    A Boolean value that determines whether the image changes when the
    button is disabled.

- shows-touch-when-highlighted

    A Boolean value that determines whether tapping the button causes
    it to glow.

- background-image-for-state

    Sets the background image to use for the specified button state. A
    pair of a image and a control state. Available control states are
    the same as in title-for-state.

- image-for-state

    Sets the image to use for the specified state. The parameter is
    like what in background-image-for-state.

- content-edge-insets

    The inset or outset margins for the edges of the button content
    drawing rectangle. An edge-insets value.

- title-edge-insets

    The inset or outset margins for the edges of the button title
    drawing rectangle. An edge-insets value.

- image-edge-insets

    The inset or outset margins for the edges of the button image
    drawing rectangle. An edge-insets value.

### image
- image
- highlighted-image
- animation-images
- highlighted-animation-images
- animation-duration
- animation-repeat-count
- user-interaction-enabled
- highlighted
- tint-color
### slider
- value
- minimum-value
- maximum-value
- continuous
- minimum-value-image
- maximum-value-image
- minimum-track-tint-color
- minimum-track-image-for-state
- maximum-track-tint-color
- maximum-track-image-for-state
- thumb-tint-color
- thumb-image-for-state
### segmented-control
- items
- selected-segment-index
- momentary
- segmented-control-style
- apportions-segment-widths-by-content
- tint-color
- enabled-for-segment-at-index
- content-offset-for-segment-at-index
- width-for-segment-at-index
- background-image-for-state-bar-metrics
- content-position-adjustment-for-segment-type-bar-metrics
- divider-image-for-left-segment-state-right-segment-state-bar-metrics
- title-text-attributes-for-state
### text-field
- text
- placeholder
- font
- text-color
- text-alignment
- adjusts-font-size-to-fit-width
- minimum-font-size
- clears-on-begin-editing
- border-style
- background
- disabled-background
- clear-button-mode
- left-view
- left-view-mode
- right-view
- right-view-mode
- input-view
- input-accessory-view
### text-view
- text
- font
- text-color
- editable
- data-detector-types
- text-alignment
- selected-range
- input-view
- input-accessory-view
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

Sample
------

Further Work
------------

1. Support iOS5, iOS6 and iOS7
