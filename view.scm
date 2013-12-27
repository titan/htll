(define (custom-value? value)
  (and (list? value)
       (> (length value) 0)
       (symbol? (car value))))

(define (fake-generate var value) "")

(define (generate-bool value)
  (if (boolean? value)
      (if value "YES" "NO")
      (error "Invalid boolean type" value)))

(define (generate-assign-bool var attr value)
  (string-append var "." attr " = " (generate-bool value) ";"))

(define (generate-float value)
  (if (real? value)
      (number->string value)
      (error "Invalid float type" value)))

(define (generate-assign-float var attr value)
  (string-append var "." attr " = " (generate-float value) ";"))

(define (generate-integer value)
  (if (integer? value)
      (number->string value)
      (error "Invalid integer type" value)))

(define (generate-assign-integer var attr value)
  (string-append var "." attr " = " (generate-integer value) ";"))

(define (generate-number value)
  (if (number? value)
      (number->string value)
      (error "Invalid number type" value)))

(define (generate-assign-number var attr value)
  (string-append var "." attr " = " (generate-number value) ";"))

(define (generate-size value)
  (if (and (custom-value? value) (= (length value) 3) (eq? 'size (car value)) (number? (cadr value)) (number? (caddr value)))
      (string-append "(CGSize) {" (cadr value) ", " (caddr value) "}")
      (error "Invalid size type" value)))

(define (generate-assign-size var attr value)
  (string-append var "." attr " = " (generate-size value)))

(define (generate-rect value)
  (if (and (custom-value? value) (= (length value) 5) (eq? 'rect (car value)) (number? (cadr value)) (number? (caddr value)) (number? (cadddr value)) (number? (car (cddddr value))))
      (string-append "(CGRect) {" (cadr value) ", " (caddr value) ", " (cadddr value) ", " (car (cddddr value)) "}")
      (error "Invalid rect type" value)))

(define (generate-assign-rect var attr value)
  (string-append var "." attr " = " (generate-rect value) ";"))

(define (generate-offset value)
  (if (and (custom-value? value) (= (length value) 3) (eq? 'offset (car value)) (number? (cadr value)) (number? (caddr value)))
      (let ((h (number->string (cadr value)))
            (v (number->string (caddr value))))
        (string-append "UIOffsetMake(" h ", " v ")"))
      (error "Invalid offset type" value)))

(define (generate-assign-offset var attr value)
  (string-append var "." attr " = " (generate-offset value) ";"))

(define (generate-range value)
  (if (and (custom-value? value) (= (length value) 3) (eq? 'range (car value)) (number? (cadr value)) (number? (caddr value)))
      (let ((loc (number->string (cadr value)))
            (len (number->string (caddr value))))
        (string-append "NSRangeMake(" loc ", " len ")"))
      (error "Invalid range type" value)))

(define (generate-assign-range var attr value)
  (string-append var "." attr " = " (generate-range value)))

(define (generate-edge-insets value)
  (if (and (custom-value? value) (= (length value) 5) (eq? 'edge-insets (car value)) (number? (cadr value)) (number? (caddr value)) (number? (cadddr value)) (number? (car (cddddr value))))
      (string-append "UIEdgeInsetsMake(" (cadr value) ", " (caddr value) ", " (cadddr value) ", " (car (cddddr value)) ")")
      (error "Invalid edge-insets type" value)))

(define (generate-assign-edge-insets var attr value)
  (string-append var "." attr " = " (generate-edge-insets value) ";"))

(define (generate-image-named value)
  (if (and (custom-value? value) (eq? 'image-named (car value)))
      (string-append "[UIImage imageNamed:" (generate-string (cadr value)) "]")
      (error "Invalid image type" value)))

(define (generate-image-or-ref value)
  (if (and (custom-value? value) (eq? 'image-named (car value)))
      (let ((ref (lookup-variable-by-value-ignoring-root value)))
        (if ref
            (symbol->string ref)
            (generate-image-named value)))
      (error "Invalid image type" value)))

(define (generate-assign-image var attr value)
  (string-append var "." attr " = " (generate-image-named value) ";"))

(define (generate-set-image-for-state var fun value)
  (if (and (pair? value) (list? (car value)) (symbol? (cdr value)))
      (let ((image (car value))
            (state (cdr value)))
        (string-append "[" var " " fun ":" (generate-image-or-ref image) " forState:" (generate-control-state state) "];"))
      (error (string-append "Invalid data type for [" var " " fun ":forState:]") value)))

(define (generate-localized value)
  (string-append "NSLocalizedString(@\"" (localized-key value) "\", @\"" (localized-default value) "\")"))

(define (generate-string value)
  (cond
   ((tagged-list? value 'localized)
    (generate-localized value))
   ((string? value)
    (string-append "@\"" value "\""))
   (else
    (error "Invalid string type" value))))

(define (generate-assign-string var attr value)
  (string-append var "." attr " = " (generate-string value) ";"))

(define (generate-font value)
  (cond
   ((and (tagged-list? value 'font) (string? (cadr value)) (number? (caddr value)))
    (let ((ref (lookup-variable-by-value-ignoring-root value)))
      (if ref
          (symbol->string ref)
          (string-append "[UIFont fontWithName:@\"" (cadr value) "\" size:" (number->string (caddr value)) "]"))))
   ((and (tagged-list? value 'system-font-of-size) (number? (cadr value)))
    (string-append "[UIFont systemFontOfSize:" (cadr value) "]"))
   ((and (tagged-list? value 'bold-system-font-of-size) (number? (cadr value)))
    (string-append "[UIFont boldSystemFontOfSize:" (cadr value) "]"))
   ((and (tagged-list? value 'italic-system-font-of-size) (number? (cadr value)))
    (string-append "[UIFont italicSystemFontOfSize:" (cadr value) "]"))
   (else (error "Invalid font " value))))

(define (generate-assign-font var attr value)
  (string-append var "." attr " = " (generate-font value) ";"))

(define (generate-font-size value)
  (cond
   ((number? value) (number->string value))
   ((custom-value? value)
    (case (car value)
      ((label-font-size) "[UIFont labelFontSize]")
      ((button-font-size) "[UIFont buttonFontSize]")
      ((small-system-font-size) "[UIFont smallSystemFontSize]")
      (else "[UIFont systemFontSize]")))
   (else (error "Invalid font size" value))))

(define (generate-assign-font-size var attr value)
  (string-append var "." attr " = " (generate-font-size value) ";"))

(define (generate-array value)
  (let loop ((array value)
             (result "[NSArray arrayWithObjects:"))
    (if (null? array)
        (string-append result "nil]")
        (loop (cdr array) (string-append result (car array) ", ")))))

(define (generate-dictionary value)
  (let loop ((array value)
             (result "[NSDictionary dictionaryWithObjectsAndKeys:"))
    (if (null? array)
        (string-append result "nil]")
        (loop (cdr array) (string-append result (cdar array) ", " (caar array) ", ")))))

(define (generate-control-state state)
  (case state
    ((normal) "UIControlStateNormal")
    ((highlighted) "UIControlStateHighlighted")
    ((disabled) "UIControlStateDisabled")
    ((selected) "UIControlStateSelected")
    ((application) "UIControlStateApplication")
    (else "UIControlStateReserved")))

(define (generate-bar-metrics metrics)
  (case metrics
    ((landscape-phone) "UIBarMetricsLandscapePhone")
    (else "UIBarMetricsDefault")))

(define (generate-segment-type segment)
  (case segment
    ((left) "UISegmentedControlSegmentLeft")
    ((center) "UISegmentedControlSegmentCenter")
    ((right) "UISegmentedControlSegmentRight")
    ((alone) "UISegmentedControlSegmentAlone")
    (else "UISegmentedControlSegmentAny")))

(define (generate-text-field-border-style value)
  (case value
    ((line) "UITextBorderStyleLine")
    ((bezel) "UITextBorderStyleBezel")
    ((rounded-rect) "UITextBorderStyleRoundedRect")
    (else "UITextBorderStyleNone")))

(define (generate-text-field-view-mode value)
  (case value
    ((while-editing) "UITextViewModeWhileEditing")
    ((unless-editing) "UITextViewModeUnlessEditing")
    ((always) "UITextViewModeAlways")
    (else "UITextViewModeNever")))

(define (generate-data-detector-type value)
  (case value
    ((phone-number) "UIDataDetectorTypePhoneNumber")
    ((link) "UIDataDetectorTypeLink")
    ((address) "UIDataDetectorTypeAddress")
    ((calendar-event) "UIDataDetectorTypeCalendarEvent")
    ((all) "UIDataDetectorTypeAll")
    (else "UIDataDetectorTypeNone")))

(define (generate-scroll-indicator-style value)
  (case value
    ((black) "UIScrollViewIndicatorStyleBlack")
    ((white) "UIScrollViewIndicatorStyleWhite")
    (else "UIScrollViewIndicatorStyleDefault")))

(define (generate-view-ref value)
  (if (and (custom-value? value) ((memq (car value) '(view label image custom-button rounded-rect-button detail-disclousre-button info-light-button info-dark-button contact-add-button slider segmented-control text-field))))
      (let ((ref (lookup-variable-by-value-ignoring-root value)))
        (if ref
            (symbol->string ref)
            (error "Cannot find view refered to " ref)))
      (error "Invalid view type" value)))

(define (generate-assign-view-ref var attr value)
  (string-append var "." attr " = " (generate-view-ref value) ";"))

(define the-predefined-colors
  (list (cons 'black-color "blackColor")
        (cons 'darkGray-color "darkGrayColor")
        (cons 'lightGray-color "lightGrayColor")
        (cons 'white-color "whiteColor")
        (cons 'gray-color "grayColor")
        (cons 'red-color "redColor")
        (cons 'green-color "greenColor")
        (cons 'blue-color "blueColor")
        (cons 'cyan-color "cyanColor")
        (cons 'yellow-color "yellowColor")
        (cons 'magenta-color "magentaColor")
        (cons 'orange-color "orangeColor")
        (cons 'purple-color "purpleColor")
        (cons 'brown-color "brownColor")
        (cons 'clear-color "clearColor")
        (cons 'light-text-color "lightTextColor")
        (cons 'dark-text-color "darkTextColor")
        (cons 'group-table-view-background-color "groupTableViewBackgroundColor")
        (cons 'view-flipside-background-color "viewFlipsideBackgroundColor")
        (cons 'scroll-view-textured-background-color "scrollViewTexturedBackgroundColor")
        (cons 'under-page-background-color "underPageBackgroundColor")))

(define (generate-color color)
  (cond
   ((symbol? color)
    (let ((color-definition (assq color the-predefined-colors)))
      (if color-definition
          (string-append "[UIColor " (cdr color-definition) "]")
          (error "Invalid color type " color))))
   ((list? color)
    (let ((tag (car color)))
      (cond
       ((eq? tag 'hsba-color)
        (string-append "[UIColor colorWithHue:" (cadr color) " saturation:" (caddr color) " brightness:" (cadddr color) " alpha:" (car (cddddr color)) "]"))
       ((eq? tag 'rgba-color)
        (string-append "[UIColor colorWithRed:" (cadr color) " green:" (caddr color) " blue:" (cadddr color) " alpha:" (car (cddddr color)) "]"))
       (else (error "Unknown color " (tag))))))
   (else (error "Invalid color type" color))))

(define (generate-assign-color var attr color)
  (string-append var "." attr " = " (generate-color color) ";"))

(define (generate-set-color-for-state var fun value)
  (if (and (pair? value) (symbol? (car value)) (symbol? (cdr value)))
      (let ((color (car value))
            (state (cdr value))
            (ref (lookup-variable-by-value-ignoring-root value)))
        (if ref
            (string-append "[" var " " fun ":" ref " forState:" (generate-control-state state) "];")
            (string-append "[" var " " fun ":" (generate-color color) " forState:" (generate-control-state state) "];")))
      (error (string-append "Invalid data type for [" var " " fun ":forState:]") value)))

(define (generate-autoresizing-mask value)
  (if (symbol? value)
      (case value
        ((flexible-left-margin) "UIViewAutoresizingFlexibleLeftMargin")
        ((flexible-width) "UIViewAutoresizingFlexibleWidth")
        ((flexible-right-margin) "UIViewAutoresizingFlexibleRightMargin")
        ((flexible-top-margin) "UIViewAutoresizingFlexibleTopMargin")
        ((flexible-height) "UIViewAutoresizingFlexibleHeight")
        ((flexible-bottom-margin) "UIViewAutoresizingFlexibleBottomMargin")
        (else "UIViewAutoresizingNone"))
      (error "Unknown autoresizing mask" value)))

(define (generate-assign-autoresizing-mask var attr value)
  (string-append var "." attr " = " (generate-autoresizing-mask value) ";"))

(define (generate-content-mode value)
  (if (symbol? value)
      (case value
        ((scale-to-fill) "UIViewContentModeScaleToFill")
        ((scale-aspect-fit) "UIViewContentModeScaleAspectFit")
        ((scale-aspect-fill) "UIViewContentModeScaleAspectFill")
        ((redraw) "UIViewContentModeRedraw")
        ((center) "UIViewContentModeCenter")
        ((top) "UIViewContentModeTop")
        ((bottom) "UIViewContentModeBottom")
        ((left) "UIViewContentModeLeft")
        ((right) "UIViewContentModeRight")
        ((top-left) "UIViewContentModeTopLeft")
        ((top-right) "UIViewContentModeTopRight")
        ((bottom-left) "UIViewContentModeBottomLeft")
        ((bottom-right) "UIViewContentModeBottomRight"))
      (error "Unknown content mode" value)))

(define (generate-assign-content-mode var attr value)
  (string-append var "." attr " = " (generate-content-mode value)))

(define (generate-content-vertical-alignment value)
  (if (symbol? value)
      (case value
        ((center) "UIControlContentVerticalAlignmentCenter")
        ((top) "UIControlContentVerticalAlignmentTop")
        ((bottom) "UIControlContentVerticalAlignmentBottom")
        ((fill) "UIControlContentVerticalAlignmentFill")
        (else (error "Unknown content vertical alignment" value)))
      (error "Unknown content vertical alignment" value)))

(define (generate-assign-content-vertical-alignment var attr value)
  (string-append var "." attr " = " (generate-content-vertical-alignment value) ";"))

(define (generate-content-horizontal-alignment value)
  (if (symbol? value)
      (case value
        ((center) "UIControlContentHorizontalAlignmentCenter")
        ((left) "UIControlContentHorizontalAlignmentLeft")
        ((right) "UIControlContentHorizontalAlignmentRight")
        ((fill) "UIControlContentHorizontalAlignmentFill")
        (else (error "Unknown content horizontal alignment" value)))
      (error "Unknown content horizontal alignment" value)))

(define (generate-assign-content-horizontal-alignment var attr value)
  (string-append var "." attr " = " (generate-content-horizontal-alignment value) ";"))

(define (generate-assign-indicator-style var attr value)
  (string-append var "." attr " = " (generate-scroll-indicator-style value) ";"))

(define (generate-text-alignment value)
  (if (symbol? value)
      (if (eq? ios-version 'ios5)
          (case value
            ((left) "UITextAlignmentLeft")
            ((center) "UITextAlignmentCenter")
            ((right) "UITextAlignmentRight")
            (else (error "Unknown text alignment" value)))
          (case value
            ((left) "NSTextAlignmentLeft")
            ((center) "NSTextAlignmentCenter")
            ((right) "NSTextAlignmentRight")
            (else (error "Unknown text alignment" value))))
      (error "Unknown text alignment" value)))

(define (generate-assign-text-alignment var attr value)
  (string-append var "." attr " = " (generate-text-alignment value) ";"))

(define (generate-link-break-mode value)
  (if (symbol? value)
      (if (eq? ios-version 'ios5)
          (case value
            ((word-wrap) "UILineBreakModeWordWrap")
            ((character-wrap) "UILineBreakModeCharacterWrap")
            ((clip) "UILineBreakModeClip")
            ((head-truncation) "UILineBreakModeHeadTruncation")
            ((tail-truncation) "UILineBreakModeTailTruncation")
            ((middle-truncation) "UILineBreakModeMiddleTruncation")
            (else (error "Invalid link break mode" value)))
          (case value
            ((word-wrap) "NSLineBreakModeWordWrap")
            ((character-wrap) "NSLineBreakModeCharacterWrap")
            ((clip) "NSLineBreakModeClip")
            ((head-truncation) "NSLineBreakModeHeadTruncation")
            ((tail-truncation) "NSLineBreakModeTailTruncation")
            ((middle-truncation) "NSLineBreakModeMiddleTruncation")
            (else (error "Invalid link break mode" value))))
      (error "Invalid link break mode" value)))

(define (generate-assign-line-break-mode var attr value)
  (string-append var "." attr " = " value ";"))

(define the-predefined-baseline-adjustments
  (list (cons 'align-baselines "UIBaselineAdjustmentAlignBaselines")
        (cons 'align-centers "UIBaselineAdjustmentAlignCenters")
        (cons 'none "UIBaselineAdjustmentNone")))

(define (generate-baseline-adjustment value)
  (if (symbol? value)
      (case value
        ((align-baselines) "UIBaselineAdjustmentAlignBaselines")
        ((align-centers) "UIBaselineAdjustmentAlignCenters")
        (else "UIBaselineAdjustmentNone"))
      (error "Invalid baseline adjustment" value)))

(define (generate-assign-baseline-adjustment var attr value)
  (string-append var "." attr " = " (generate-baseline-adjustment value) ";"))

(define (generate-title-for-state var value)
  (if (and (pair? value) (string? (car value)) (symbol? (cdr value)))
      (let ((title (car value))
            (state (cdr value)))
        (string-append "[" var " setTitle:" (generate-string title) " forState:" (generate-control-state state) "];"))
      (error (string-append "Invalid data type for [" var " setTitle:forState:]") value)))

(define (generate-assign-images var attr value)
  (let loop ((array value)
             (result '()))
    (if (null? array)
        (string-append var "." attr " = " (generate-array result) ";")
        (let ((ref (lookup-variable-by-value-ignoring-root (car array))))
          (if ref
              (loop (cdr array) (cons (symbol->string ref) result))
              (loop (cdr array) (cons (generate-image-named (car array)) result)))))))

(define (generate-minimum-track-image-for-state var value)
  (generate-set-image-for-state var "setMinimumTrackImage" value))

(define (generate-maximum-track-image-for-state var value)
  (generate-set-image-for-state var "setMaximumTrackImage" value))

(define (generate-thumb-image-for-state var value)
  (generate-set-image-for-state var "setThumbImage" value))

(define (generate-segmented-control-style value)
  (if (symbol? value)
      (case value
        ((bordered) "UISegmentedControlStyleBordered")
        ((bar) "UISegmentedControlStyleBar")
        ((bezeled) "UISegmentedControlStyleBezeled")
        (else "UISegmentedControlStylePlain"))
      (error "Invalid segmented control style" value)))

(define (generate-assign-segmented-control-style var attr value)
  (string-append var "." attr " = " (generate-segmented-control-style value) ";"))

(define (generate-enabled-for-segment-at-index var value)
  (if (and (pair? value) (boolean? (car value)) (number? (cdr value)))
      (let ((enabled (car value))
            (index (cdr value)))
        (string-append "[" var " setEnabled:" (generate-bool enabled) " forSegmentAtIndex:" (number->string index) "];"))
      (error (string-append "Invalid data type for [" var " setEnabled:forsegmentAtIndex:]") value)))

(define (generate-content-offset-for-segment-at-index var value)
  (if (and (pair? value) (list? (car value)) (number? (cdr value)))
      (let ((offset (car value))
            (index (cdr value)))
        (string-append "[" var " setContentOffset:" (generate-size offset) " forSegmentAtIndex:" (number->string index) "];"))
      (error (string-append "Invalid data type for [" var " setContentOffset:forSegmentAtIndex:];") value)))

(define (generate-width-for-segment-at-index var value)
  (if (and (pair? value) (number? (car value)) (number? (cdr value)))
      (let ((width (car value))
            (index (cdr value)))
        (string-append "[" var " setWidth:" (number->string width) " forSegmentAtIndex:" (number->string index) "];"))
      (error (string-append "Invalid data type for [" var " setWidth:forSegmentAtIndex:];") value)))

(define (generate-background-image-for-state-bar-metrics var value)
  (if (and (list? value) (= 3 (length value)) (list? (car value)) (symbol? (cadr value)) (symbol? (caddr value)))
      (let ((image (car value))
            (state (cadr value))
            (metrics (caddr value)))
        (string-append "[" var " setBackgroundImage:" (generate-image-or-ref image) " forState:" (generate-control-state state) " barMetrics:" (generate-bar-metrics metrics) "];"))
      (error (string-append "Invalid data type for [" var " setBackgroundImage:forState:barMetrics:];") value)))

(define (generate-content-position-adjustment-for-segment-type-bar-metrics var value)
  (if (and (list? value) (= 3 (length value)) (and (custom-value? (car value)) (eq? 'offset (caar value))) (symbol? (cadr value)) (symbol? (caddr value)))
      (let ((offset (car value))
            (segment-type (cadr value))
            (metrics (caddr value)))
        (string-append "[" var " setContentPositionAdjustment:" (generate-offset offset) " forSegmentType:" (generate-segment-type segment-type) " barMetrics:" (generate-bar-metrics metrics) "];"))
      (error (string-append "Invalid data type for [" var " setContentPositionAdjustment:forSegmentType:barMetrics:];") value)))

(define (generate-divider-image-for-left-segment-state-right-segment-state-bar-metrics var value)
  (if (and (list? value) (= 4 (length value)) (and (custom-value? (car value)) (eq? 'image-named (caar value))) (symbol? (cadr value)) (symbol? (caddr value)) (symbol? (cadddr value)))
      (let ((image (car value))
            (left (cadr value))
            (right (caddr value))
            (metrics (cadddr value)))
        (string-append "[" var " setDividerImage:" (generate-image-or-ref image) " forLeftSegmentState:" (generate-control-state left) " rightSegmentState:" (generate-control-state right) " barMetrics:" (generate-bar-metrics metrics) "];"))
      (error (string-append "Invalid data type for [" var " setDividerImage:forLeftSegmentState:rightSegmentState:barMetrics:];") value)))

(define (generate-title-text-attributes-for-state var value)
  (if (and (pair? value) (list? (car value)) (symbol? (cdr value)))
      (let ((attrs (car value))
            (state (cdr value)))
        (let loop ((as attrs)
                   (result '()))
          (if (null? as)
              (string-append "[" var " setTitleTextAttributes:" (generate-dictionary result) " forState:" (generate-control-state state) "];")
              (loop (cdr as)
                    (cons (cond
                           ((eq? 'font (caar as))
                            (cons "UITextAttributeFont" (generate-font (cdar as))))
                           ((eq? 'text-color (caar as))
                            (cons "UITextAttributeTextColor" (generate-color (cdar as))))
                           ((eq? 'text-shadow-color (caar as))
                            (cons "UITextAttributeTextShadowColor" (generate-color (cdar as))))
                           ((eq? 'text-shadow-offset (caar as))
                            (cons "UITextAttributeTextShadowOffset" (generate-offset (cdar as))))
                           (else (error "Unknown text attributes" (caar as))))
                          result)))))
      (error (string-append "Invalid data type for [" var " setTitleTextAttributes:forState:];") value)))

(define (generate-assign-border-style var attr value)
  (string-append var "." attr " = " (generate-text-field-border-style value) ";"))

(define (generate-assign-text-field-view-mode var attr value)
  (string-append var "." attr " = " (generate-text-field-view-mode value) ";"))

(define (generate-assign-data-detector-types var attr value)
  (string-append var "." attr " = " (generate-data-detector-type value) ";"))

(define (generate-separator-style value)
  (case value
    ((single-line) "UITableViewCellSeparatorStyleSingleLine")
    ((single-line-etched) "UITableViewCellSeparatorStyleSingleLineEtched")
    (else "UITableViewCellSeparatorStyleNone")))

(define (generate-assign-separator-style var attr value)
  (string-append var "." attr " = " (generate-separator-style value) ";"))

(define (generate-assign-data-source var attr value)
  (if (symbol? value)
      (string-append var "." attr " = " (symbol->string value) ";")
      (error "Invalid data source type" value)))

(define (generate-assign-delegate var attr value)
  (if (symbol? value)
      (string-append var "." attr " = " (symbol->string value) ";")
      (error "Invalid delegate type" value)))

(define the-view-attribute-generators
  (list (list 'background-color generate-assign-color "backgroundColor")
        (list 'hidden generate-assign-bool "hidden")
        (list 'alpha generate-assign-float "alpha")
        (list 'opaque generate-assign-bool "opaque")
        (list 'clips-to-bounds generate-assign-bool "clipsToBounds")
        (list 'clears-context-before-drawing generate-assign-bool "clearsContexBeforeDrawing")
        (list 'user-interaction-enabled generate-assign-bool "userInteractionEnabled")
        (list 'multiple-touch-enabled generate-assign-bool "multipleTouchEnabled")
        (list 'exclusive-touch generate-assign-bool "exclusiveTouch")
        (list 'autoresizing-mask generate-assign-autoresizing-mask "autoresizingMask")
        (list 'autoresizes-subviews generate-assign-bool "autoresizesSubviews")
        (list 'content-mode generate-assign-content-mode "contentMode")
        (list 'content-stretch generate-assign-rect "contentStretch")
        (list 'content-scale-factor generate-assign-float "contentScaleFactor")))

(define the-control-attribute-generators
  (list (list 'enabled generate-assign-bool "enabled")
        (list 'selected generate-assign-bool "selected")
        (list 'highlighted generate-assign-bool "highlighted")
        (list 'content-vertical-alignment generate-assign-content-vertical-alignment "contentVerticalAlignment")
        (list 'content-horizontal-alignment generate-assign-content-horizontal-alignment "contentHorizontalAlignment")))

(define the-scroll-attribute-generators
  (append the-view-attribute-generators
          (list (list 'content-offset generate-assign-offset "contentOffset")
                (list 'content-size generate-assign-size "contentSize")
                (list 'content-inset generate-assign-edge-insets "contentInset")
                (list 'scroll-enabled generate-assign-bool "scrollEnabled")
                (list 'direction-lock-enabled generate-assign-bool "directionLockEnabled")
                (list 'scroll-to-top generate-assign-bool "scrollToTop")
                (list 'paging-enabled generate-assign-bool "pagingEnabled")
                (list 'bounces generate-assign-bool "bounces")
                (list 'always-bounces-vertical generate-assign-bool "alwaysBouncesVertical")
                (list 'always-bounces-horizontal generate-assign-bool "alwaysBouncesHorizontal")
                (list 'can-cancel-content-touches generate-assign-bool "canCancelContentTouches")
                (list 'delays-content-touches generate-assign-bool "delaysContentTouches")
                (list 'deceleration-rate generate-assign-float "decelerationRate")
                (list 'indicator-style generate-assign-indicator-style "indicatorStyle")
                (list 'scroll-indicator-insets generate-assign-edge-insets "scrollIndicator")
                (list 'shows-horizontal-scroll-indicator generate-assign-bool "showsHorizontalScrollIndicator")
                (list 'shows-vertical-scroll-indicator generate-assign-bool "showsVerticalScrollIndicator")
                (list 'zoom-scale generate-assign-float "zoomScale")
                (list 'maximum-zoom-scale generate-assign-float "maximumZoomScale")
                (list 'minimum-zoom-scale generate-assign-float "minimumZoomScale")
                (list 'bounces-zoom generate-assign-bool "bouncesZoom"))))

(define the-label-attribute-generators
  (append the-view-attribute-generators
          (list (list 'text generate-assign-string "text")
                (list 'font generate-assign-font "font")
                (list 'text-color generate-assign-color "textColor")
                (list 'text-alignment generate-assign-text-alignment "textAlignment")
                (list 'line-break-mode generate-assign-line-break-mode "lineBreakMode")
                (list 'enabled generate-assign-bool "enabled")
                (list 'adjusts-font-size-to-fit-width generate-assign-bool "adjustsFontSizeToFitWidth")
                (list 'baseline-adjustment generate-assign-baseline-adjustment "baselineAdjustment")
                (list 'minimum-font-size generate-assign-font-size "minimumFontSize")
                (list 'number-of-lines generate-assign-integer "numberOfLines")
                (list 'highlighted-text-color generate-assign-color "highlightedTextColor")
                (list 'highlighted generate-assign-bool "highlighted")
                (list 'shadow-color generate-assign-color "shadowColor")
                (list 'shadow-offset generate-assign-size "shadowOffset"))))

(define the-button-attribute-generators
  (append the-view-attribute-generators
          the-control-attribute-generators
          (list (list 'reverses-title-shadow-when-highlighted generate-assign-bool "reversesTitleShadowWhenHighlighted")
                (list 'title-for-state generate-title-for-state #f)
                (list 'title-color-for-state generate-set-color-for-state "setTitleColor")
                (list 'title-shadow-color-for-state generate-set-color-for-state "setTitleShadowColor")
                (list 'adjusts-image-when-highlighted generate-assign-bool "adjustsImageWhenHighlighted")
                (list 'adjusts-image-when-disabled generate-assign-bool "adjustsImageWhenDisabled")
                (list 'shows-touch-when-highlighted generate-assign-bool "showsTouchWhenHighlighted")
                (list 'background-image-for-state generate-set-image-for-state "setBackgroundImage")
                (list 'image-for-state generate-set-image-for-state "setImage")
                (list 'content-edge-insets generate-assign-edge-insets "contentEdgeInsets")
                (list 'title-edge-insets generate-assign-edge-insets "titleEdgeInsets")
                (list 'image-edge-insets generate-assign-edge-insets "imageEdgeInsets"))))

(define the-image-attribute-generators
  (list (list 'image generate-assign-image "image")
        (list 'highlighted-image generate-assign-image "highlightedImage")
        (list 'animation-images generate-assign-images "animationImages")
        (list 'highlighted-animation-images generate-assign-images "highlightedAnimationImages")
        (list 'animation-duration generate-assign-float "animationDuration")
        (list 'animation-repeat-count generate-assign-integer "animationRepeatCount")
        (list 'user-interaction-enabled generate-assign-bool "userInteractionEnabled")
        (list 'highlighted generate-assign-bool "highlighted")))

(define the-slider-attribute-generators
  (append the-view-attribute-generators
          the-control-attribute-generators
          (list (list 'value generate-assign-float "value")
                (list 'minimum-value generate-assign-float "minimumValue")
                (list 'maximum-value generate-assign-float "maximumValue")
                (list 'continuous generate-assign-bool "continuous")
                (list 'minimum-value-image generate-assign-image "minimumValueImage")
                (list 'maximum-value-image generate-assign-image "maximumValueImage")
                (list 'minimum-track-tint-color generate-assign-color "minimumTrackTintColor")
                (list 'minimum-track-image-for-state generate-minimum-track-image-for-state #f)
                (list 'maximum-track-tint-color generate-assign-color "maximumTrackTintColor")
                (list 'maximum-track-image-for-state generate-maximum-track-image-for-state #f)
                (list 'thumb-tint-color generate-assign-color "thumbTintColor")
                (list 'thumb-image-for-state generate-thumb-image-for-state #f))))

(define the-segmented-control-attribute-generators
  (append the-view-attribute-generators
          the-control-attribute-generators
          (list (list 'items fake-generate #f)
                (list 'selected-segment-index generate-assign-integer "selectedSegmentIndex")
                (list 'momentary generate-assign-bool "momentary")
                (list 'segmented-control-style generate-assign-segmented-control-style "segmentedControlStyle")
                (list 'apportions-segment-widths-by-content generate-assign-bool "apportionsSegmentWidthsByContent")
                (list 'tint-color generate-assign-color "tintColor")
                (list 'enabled-for-segment-at-index generate-enabled-for-segment-at-index #f)
                (list 'content-offset-for-segment-at-index generate-content-offset-for-segment-at-index #f)
                (list 'width-for-segment-at-index generate-width-for-segment-at-index #f)
                (list 'background-image-for-state-bar-metrics generate-background-image-for-state-bar-metrics #f)
                (list 'content-position-adjustment-for-segment-type-bar-metrics generate-content-position-adjustment-for-segment-type-bar-metrics #f)
                (list 'divider-image-for-left-segment-state-right-segment-state-bar-metrics generate-divider-image-for-left-segment-state-right-segment-state-bar-metrics #f)
                (list 'title-text-attributes-for-state generate-title-text-attributes-for-state #f))))

(define the-text-field-attribute-generators
  (append the-view-attribute-generators
          the-control-attribute-generators
          (list (list 'text generate-assign-string "text")
                (list 'placeholder generate-assign-string "placeholder")
                (list 'font generate-assign-font "font")
                (list 'text-color generate-assign-color "textColor")
                (list 'text-alignment generate-assign-text-alignment "textAlignment")
                (list 'adjusts-font-size-to-fit-width generate-assign-bool "adjustsFontSizeToFitWidth")
                (list 'minimum-font-size generate-assign-float "minimumFontSize")
                (list 'clears-on-begin-editing generate-assign-bool "clearsOnBeginEditing")
                (list 'border-style generate-assign-border-style "borderStyle")
                (list 'background generate-assign-image "background")
                (list 'disabled-background generate-assign-image "disabledBackground")
                (list 'clear-button-mode generate-assign-text-field-view-mode "clearButtonMode")
                (list 'left-view generate-assign-view-ref "leftView")
                (list 'left-view-mode generate-assign-text-field-view-mode "leftViewMode")
                (list 'right-view generate-assign-view-ref "rightView")
                (list 'right-view-mode generate-assign-text-field-view-mode "rightViewMode")
                (list 'input-view generate-assign-view-ref "inputView")
                (list 'input-accessory-view generate-assign-view-ref "accessoryView"))))

(define the-text-view-attribute-generators
  (append the-view-attribute-generators
          (list (list 'text generate-assign-string "text")
                (list 'font generate-assign-font "font")
                (list 'text-color generate-assign-color "textColor")
                (list 'editable generate-assign-bool "editable")
                (list 'data-detector-types generate-assign-data-detector-types "dataDetectorTypes")
                (list 'text-alignment generate-assign-text-alignment "textAlignment")
                (list 'selected-range generate-assign-range "selectedRange")
                (list 'input-view generate-assign-view-ref "inputView")
                (list 'input-accessory-view generate-assign-view-ref "accessoryView"))))

(define the-table-attribute-generators
  (append the-scroll-attribute-generators
          (list (list 'row-height generate-assign-float "rowHeight")
                (list 'separator-style generate-assign-separator-style "separatorStyle")
                (list 'separator-color generate-assign-color "separatorColor")
                (list 'background-view generate-assign-view-ref "backgroundView")
                (list 'table-header-view generate-assign-view-ref "tableHeaderView")
                (list 'table-footer-view generate-assign-view-ref "tableFooterView")
                (list 'section-header-height generate-assign-float "sectionHeaderHeight")
                (list 'section-footer-height generate-assign-float "sectionFooterHeight")
                (list 'section-index-minimum-display-row-count generate-assign-integer "sectionIndexMinimumDisplayRowCount")
                (list 'allows-selection generate-assign-bool "allowsSelection")
                (list 'allows-multiple-selection generate-assign-bool "allowsMultipleSelection")
                (list 'allows-selection-during-editing generate-assign-bool "allowsSelectionDuringEditing")
                (list 'allows-multiple-selection-during-editing generate-assign-bool "allowsMultipleSelectionDuringEditing")
                (list 'data-source generate-assign-data-source "dataSource")
                (list 'delegate generate-assign-delegate "delegate"))))
