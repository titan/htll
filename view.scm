(define (custom-value? value)
  (and (list? value)
       (> (length value) 0)
       (symbol? (car value))))

(define (invalid-data-type-error var attr want got)
  (error "Invalid data type for " (string->symbol (string-append var "." attr)) "want" want "got" got))

(define (generate-bool var attr value)
  (if (boolean? value)
      (if value
          (string-append var "." attr " = YES;")
          (string-append var "." attr " = NO;"))
      (invalid-data-type-error var attr "true/false" value)))

(define (generate-float var attr value)
  (if (number? value)
      (string-append var "." attr " = " (number->string value) ";")
      (invalid-data-type-error var attr "number" value)))

(define (generate-number var attr value)
  (generate-float var attr value))

(define (generate-size var attr value)
  (if (and (custom-value? value) (= (length value) 3) (eq? 'size (car value)) (number? (cadr value)) (number? (caddr value)))
      (string-append var "." attr " = (CGSize) {" (cadr value) ", " (caddr value) "};")
      (invalid-data-type-error var attr "size" value)))

(define (generate-rect var attr value)
  (if (and (custom-value? value) (= (length value) 5) (eq? 'rect (car value)) (number? (cadr value)) (number? (caddr value)) (number? (cadddr value)) (number? (car (cddddr value))))
      (string-append var "." attr " = (CGRect) {" (cadr value) ", " (caddr value) ", " (cadddr value) ", " (car (cddddr value)) "};")
      (invalid-data-type-error var attr "rect" value)))

(define (generate-edge-insets var attr value)
  (if (and (custom-value? value) (= (length value) 5) (eq? 'edge-insets (car value)) (number? (cadr value)) (number? (caddr value)) (number? (cadddr value)) (number? (car (cddddr value))))
      (string-append var "." attr " = UIEdgeInsetsMake(" (cadr value) ", " (caddr value) ", " (cadddr value) ", " (car (cddddr value)) ");")
      (invalid-data-type-error var attr "edge-insets" value)))

(define (generate-image-named value)
  (if (and (custom-value? value) (eq? 'image-named (car value)))
      (string-append "[UIImage imageNamed:" (generate-string (cadr value)) "]")
      (error "Invalid image type" value)))

(define (generate-assign-image var attr value)
  (string-append var "." attr " = " (generate-image-named value) ";"))

(define (generate-set-image-for-state var fun value)
  (if (and (pair? value) (list? (car value)) (symbol? (cdr value)))
      (let ((image (car value))
            (state (car value))
            (ref (lookup-variable-by-value-ignoring-root value)))
        (if ref
            (string-append "[" var " " fun ":" value " forState:" (generate-control-state state) "];")
            (string-append "[" var " " fun ":" (generate-image-named image) " forState:" (generate-control-state state) "];")))
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

(define (generate-array value)
  (let loop ((array value)
             (result "[NSArray arrayWithObjects:"))
    (if (null? array)
        (string-append result "nil]")
        (loop (cdr array) (string-append result (car array) ", ")))))

(define (generate-control-state state)
  (case state
    ((normal) "UIControlStateNormal")
    ((highlighted) "UIControlStateHighlighted")
    ((disabled) "UIControlStateDisabled")
    ((selected) "UIControlStateSelected")
    ((application) "UIControlStateApplication")
    (else "UIControlStateReserved")))

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
            (state (car value))
            (ref (lookup-variable-by-value-ignoring-root value)))
        (if ref
            (string-append "[" var " " fun ":" ref " forState:" (generate-control-state state) "];")
            (string-append "[" var " " fun ":" (generate-color color) " forState:" (generate-control-state state) "];")))
      (error (string-append "Invalid data type for [" var " " fun ":forState:]") value)))

(define (generate-background-color var value)
  (display (generate-assign-color var "backgroundColor" value))
  (newline))

(define (generate-enabled var value)
  (display (generate-bool var "enabled" value))
  (newline))

(define (generate-selected var value)
  (display (generate-bool var "selected" value))
  (newline))

(define (generate-hidden var value)
  (display (generate-bool var "hidden" value))
  (newline))

(define (generate-alpha var value)
  (display (generate-float var "alpha" value))
  (newline))

(define (generate-opaque var value)
  (display (generate-bool var "opaque" value))
  (newline))

(define (generate-clips-to-bounds var value)
  (display (generate-bool var "clipsToBounds" value))
  (newline))

(define (generate-clears-context-before-drawing var value)
  (display (generate-bool var "clearsContextBeforeDrawing" value))
  (newline))

(define (generate-user-interaction-enabled var value)
  (display (generate-bool var "userInteractionEnabled" value))
  (newline))

(define (generate-multiple-touch-enabled var value)
  (display (generate-bool var "multipleTouchEnabled" value))
  (newline))

(define (generate-exclusive-touch var value)
  (display (generate-bool var "exclusiveTouch" value))
  (newline))

(define the-predefined-autoresizings
  (list (cons 'none "UIViewAutoresizingNone")
        (cons 'flexible-left-margin "UIViewAutoresizingFlexibleLeftMargin")
        (cons 'flexible-width "UIViewAutoresizingFlexibleWidth")
        (cons 'flexible-right-margin "UIViewAutoresizingFlexibleRightMargin")
        (cons 'flexible-top-margin "UIViewAutoresizingFlexibleTopMargin")
        (cons 'flexible-height "UIViewAutoresizingFlexibleHeight")
        (cons 'flexible-bottom-margin "UIViewAutoresizingFlexibleBottomMargin")))

(define (generate-autoresizing-mask var value)
  (if (symbol? value)
      (let ((autoresizing (assq value the-predefined-autoresizings)))
        (if autoresizing
            (begin
              (display (string-append var ".autoresizingMask = " (cdr autoresizing) ";"))
              (newline))
            (error "Unknown autoresizing mask" value)))
      (invalid-data-type-error var "autoresizingMask" "none/flexible-left-margin/flexible-width/flexible-right-margin/flexible-top-margin/flexible-height/flexible-bottom-margin" value)))

(define (generate-autoresizes-subviews var value)
  (display (generate-bool var "autoresizesSubviews" value))
  (newline))

(define the-predefined-content-modes
  (list (cons 'scale-to-fill "UIViewContentModeScaleToFill")
        (cons 'scale-aspect-fit "UIViewContentModeScaleAspectFit")
        (cons 'scale-aspect-fill "UIViewContentModeScaleAspectFill")
        (cons 'redraw "UIViewContentModeRedraw")
        (cons 'center "UIViewContentModeCenter")
        (cons 'top "UIViewContentModeTop")
        (cons 'bottom "UIViewContentModeBottom")
        (cons 'left "UIViewContentModeLeft")
        (cons 'right "UIViewContentModeRight")
        (cons 'top-left "UIViewContentModeTopLeft")
        (cons 'top-right "UIViewContentModeTopRight")
        (cons 'bottom-left "UIViewContentModeBottomLeft")
        (cons 'bottom-right "UIViewContentModeBottomRight")))

(define (generate-content-mode var value)
  (if (symbol? value)
      (let ((content-mode (assq value the-predefined-content-modes)))
        (if content-mode
            (begin
              (display (string-append var ".contentMode = " (cdr content-mode) ";"))
              (newline))
            (error "Unknown content mode" value)))
      (invalid-data-type-error var "contentMode" "scale-to-fill/scale-aspect-fit/scale-aspect-fill/redraw/center/top/bottom/left/right/top-left/top-right/bottom-left/bottom-right" value)))

(define (generate-content-stretch var value)
  (display (generate-rect var "contentStretch" value))
  (newline))

(define (generate-content-scale-factor var value)
  (display (generate-float var "contentScaleFactor" value))
  (newline))

(define the-predefined-content-vertical-alignments
  (list (cons 'center "UIControlContentVerticalAlignmentCenter")
        (cons 'top "UIControlContentVerticalAlignmentTop")
        (cons 'bottom "UIControlContentVerticalAlignmentBottom")
        (cons 'fill "UIControlContentVerticalAlignmentFill")))

(define (generate-content-vertical-alignment var value)
  (if (symbol? value)
      (let ((alignment (assq value the-predefined-content-vertical-alignments)))
        (if alignment
            (begin
              (display (string-append var ".contentVerticalAlignment = " (cdr alignment) ";"))
              (newline))
            (error "Unknown content vertical alignment" value)))
      (invalid-data-type-error var "contentVerticalAlignment" "center/top/bottom/fill" value)))

(define the-predefined-content-horizontal-alignments
  (list (cons 'center "UIControlContentHorizontalAlignmentCenter")
        (cons 'left "UIControlContentHorizontalAlignmentLeft")
        (cons 'right "UIControlContentHorizontalAlignmentRight")
        (cons 'fill "UIControlContentHorizontalAlignmentFill")))

(define (generate-content-horizontal-alignment var value)
  (if (symbol? value)
      (let ((alignment (assq value the-predefined-content-horizontal-alignments)))
        (if alignment
            (begin
              (display (string-append var ".contentHorizontalAlignment = " (cdr alignment) ";"))
              (newline))
            (error "Unknown content horizontal alignment" value)))
      (invalid-data-type-error var "contentHorizontalAlignment" "center/top/bottom/fill" value)))

(define (generate-text var value)
  (display (string-append var ".text = " (generate-string value) ";"))
  (newline))

(define (generate-font var value)
  (cond
   ((and (tagged-list? value 'font) (string? (cadr value)) (number? (caddr value)))
    (let ((ref (lookup-variable-by-value-ignoring-root value)))
      (if ref
          (display (string-append var ".font = " (symbol->string ref) ";"))
          (display (string-append var ".font = [UIFont fontWithName:@\"" (cadr value) "\" size:" (number->string (caddr value)) "];"))))
    (newline))
   ((and (tagged-list? value 'system-font-of-size) (number? (cadr value)))
    (display (string-append var ".font = [UIFont systemFontOfSize:" (cadr value) "];"))
    (newline))
   ((and (tagged-list? value 'bold-system-font-of-size) (number? (cadr value)))
    (display (string-append var ".font = [UIFont boldSystemFontOfSize:" (cadr value) "];"))
    (newline))
   ((and (tagged-list? value 'italic-system-font-of-size) (number? (cadr value)))
    (display (string-append var ".font = [UIFont italicSystemFontOfSize:" (cadr value) "];"))
    (newline))
   (else (error "Invalid font " value))))

(define (generate-text-color var value)
  (display (generate-assign-color var "textColor" value))
  (newline))

(define the-ios5-predefined-text-alignments
  (list (cons 'left "UITextAlignmentLeft")
        (cons 'center "UITextAlignmentCenter")
        (cons 'right "UITextAlignmentRight")))

(define the-predefined-text-alignments
  (list (cons 'left "NSTextAlignmentLeft")
        (cons 'center "NSTextAlignmentCenter")
        (cons 'right "NSTextAlignmentRight")))

(define (generate-text-alignment var value)
  (if (symbol? value)
      (let ((predefined (if (eq? ios-version 'ios5) the-ios5-predefined-text-alignments the-predefined-text-alignments)))
        (let ((alignment (assq value predefined)))
          (if alignment
              (begin
                (display (string-append var ".textAlignment = " (cdr alignment) ";"))
                (newline))
              (error "Unknown text alignment" value))))
      (invalid-data-type-error var "textAlignment" "left/center/right" value)))

(define the-ios5-predefined-line-break-modes
  (list (cons 'word-wrap "UILineBreakModeWordWrap")
        (cons 'character-wrap "UILineBreakModeCharacterWrap")
        (cons 'clip "UILineBreakModeClip")
        (cons 'head-truncation "UILineBreakModeHeadTruncation")
        (cons 'tail-truncation "UILineBreakModeTailTruncation")
        (cons 'middle-truncation "UILineBreakModeMiddleTruncation")))

(define the-predefined-line-break-modes
  (list (cons 'word-wrap "NSLineBreakModeWordWrap")
        (cons 'character-wrap "NSLineBreakModeCharacterWrap")
        (cons 'clip "NSLineBreakModeClip")
        (cons 'head-truncation "NSLineBreakModeHeadTruncation")
        (cons 'tail-truncation "NSLineBreakModeTailTruncation")
        (cons 'middle-truncation "NSLineBreakModeMiddleTruncation")))

(define (generate-line-break-mode var value)
  (if (symbol? value)
      (let ((predefined (if (eq? ios-version 'ios5) the-ios5-predefined-line-break-modes the-predefined-line-break-modes)))
        (let ((line-break (assq value predefined)))
          (if line-break
              (begin
                (display (string-append var ".lineBreakMode = " (cdr line-break) ";"))
                (newline))
              (error "Unknow line break mode" value))))
      (invalid-data-type-error var "lineBreakMode" "word-wrap/character-wrap/clip/head-truncation/tail-truncation/middle-truncation" value)))

(define (generate-adjusts-font-size-to-fit-width var value)
  (display (generate-bool var "adjustsFontSizeToFitWidth" value))
  (newline))

(define the-predefined-baseline-adjustments
  (list (cons 'align-baselines "UIBaselineAdjustmentAlignBaselines")
        (cons 'align-centers "UIBaselineAdjustmentAlignCenters")
        (cons 'none "UIBaselineAdjustmentNone")))

(define (generate-baseline-adjustment var value)
  (if (symbol? value)
      (let ((baseline-adjustment (assq value the-predefined-baseline-adjustments)))
        (if baseline-adjustment
            (begin
              (display (string-append var ".baselineAdjustment = " (cdr baseline-adjustment) ";"))
              (newline))
            (error "Unknown baseline adjustment" value)))
      (invalid-data-type-error var "baselineAdjustment" "align-baselines/align-centers/none" value)))

(define (generate-minimum-font-size var value)
  (if (number? value)
      (begin
        (display (string-append var ".minimumFontSize = " (number->string value) ";"))
        (newline))
      (invalid-data-type-error var "minimumFontSize" 'number value)))

(define (generate-number-of-lines var value)
  (if (integer? value)
      (begin
        (display (string-append var ".numberOfLines = " (number->string value) ";")))
      (invalid-data-type-error var "numberOfLines" 'integer value)))

(define (generate-highlighted-text-color var value)
  (display (generate-assign-color var "highlightedTextColor" value))
  (newline))

(define (generate-highlighted var value)
  (display (generate-bool var "highlighted" value))
  (newline))

(define (generate-shadow-color var value)
  (display (generate-assign-color var "shadowColor" value))
  (newline))

(define (generate-shadow-offset var value)
  (if (and (custom-value? value) (tagged-list? value 'size) (= 3 (length value)) (number? (cadr value)) (number? (caddr value)))
      (begin
        (display (string-append var ".shadowOffset = (CGSize) {" (number->string (cadr value)) ", " (number->string (caddr value)) "};"))
        (newline))
      (invalid-data-type-error var "shadowOffset" "size" value)))

(define (generate-reverses-title-shadow-when-highlighted var value)
  (display (generate-bool var "reversesTitleShadowWhenHighlighted" value))
  (newline))

(define (generate-title-for-state var value)
  (if (and (pair? value) (string? (car value)) (symbol? (cdr value)))
      (let ((title (car value))
            (state (cdr value)))
        (display (string-append "[" var " setTitle:" (generate-string title) " forState:" (generate-control-state state) "];"))
        (newline))
      (error (string-append "Invalid data type for [" var " setTitle:forState:]") value)))

(define (generate-title-color-for-state var value)
  (display (generate-set-color-for-state var "setTitleColor" value))
  (newline))

(define (generate-title-shadow-color-for-state var value)
  (display (generate-set-color-for-state var "setTitleShadowColor" value))
  (newline))

(define (generate-adjusts-image-when-highlighted var value)
  (display (generate-bool var "adjustsImageWhenHighlighted" value))
  (newline))

(define (generate-adjusts-image-when-disabled var value)
  (display (generate-bool var "adjustsImageWhenDisabled" value))
  (newline))

(define (generate-shows-touch-when-highlighted var value)
  (display (generate-bool var "showsTouchWhenHighlighted" value))
  (newline))

(define (generate-background-image-for-state var value)
  (display (generate-set-image-for-state var "setBackgroundImage" value))
  (newline))

(define (generate-image-for-state var value)
  (display (generate-set-image-for-state var "setImage" value))
  (newline))

(define (generate-content-edge-insets var value)
  (display (generate-edge-insets var "contentEdgeInsets" value))
  (newline))

(define (generate-title-edge-insets var value)
  (display (generate-edge-insets var "titleEdgeInsets" value))
  (newline))

(define (generate-image-edge-insets var value)
  (display (generate-edge-insets var "imageEdgeInsets" value))
  (newline))

(define (generate-image var value)
  (display (generate-assign-image var "image" value))
  (newline))

(define (generate-highlighted-image var value)
  (display (generate-assign-image var "highlightedImage" value))
  (newline))

(define (generate-animation-images var value)
  (let loop ((array value)
             (result '()))
    (if (null? array)
        (begin
          (display (string-append var ".animationImages = " (generate-array result) ";"))
          (newline))
        (let ((ref (lookup-variable-by-value-ignoring-root (car array))))
          (if ref
              (loop (cdr array) (cons (symbol->string ref) result))
              (loop (cdr array) (cons (generate-image-named (car array)) result)))))))

(define (generate-highlighted-animation-images var value)
 (let loop ((array value)
             (result '()))
    (if (null? array)
        (begin
          (display (string-append var ".highlightedAnimationImages = " (generate-array result) ";"))
          (newline))
        (let ((ref (lookup-variable-by-value-ignoring-root (car array))))
          (if ref
              (loop (cdr array) (cons (symbol->string ref) result))
              (loop (cdr array) (cons (generate-image-named (car array)) result)))))))

(define (generate-animation-duration var value)
  (display (generate-float var "animationDuration" value))
  (newline))

(define (generate-animation-repeat-count var value)
  (display (generate-number var "animationRepeatCount" value))
  (newline))

(define (generate-interaction-enabled var value)
  (display (generate-bool var "interactionEnabled" value))
  (newline))

(define (generate-highlighted var value)
  (display (generate-bool var "highlighted" value))
  (newline))

(define (generate-tint-color var value)
  (display (generate-assign-color var "tintColor" value))
  (newline))

(define (generate-value var value)
  (display (generate-number var "value" value))
  (newline))

(define (generate-minimum-value var value)
  (display (generate-number var "minimumValue" value))
  (newline))

(define (generate-maximum-value var value)
  (display (generate-number var "maximumValue" value))
  (newline))

(define (generate-continuous var value)
  (display (generate-bool var "continuous" value))
  (newline))

(define (generate-minimum-value-image var value)
  (display (generate-assign-image var "minimumValueImage" value))
  (newline))

(define (generate-maximum-value-image var value)
  (display (generate-assign-image var "maximumValueImage" value))
  (newline))

(define (generate-minimum-track-tint-color var value)
  (display (generate-assign-color var "minimumTrackTintColor" value))
  (newline))

(define (generate-minimum-track-image-for-state var value)
  (display (generate-set-image-for-state var "setMinimumTrackImage" value))
  (newline))

(define (generate-maximum-track-tint-color var value)
  (display (generate-assign-color var "maximumTrackTintColor" value))
  (newline))

(define (generate-maximum-track-image-for-state var value)
  (display (generate-set-image-for-state var "setMaximumTrackImage" value))
  (newline))

(define (generate-thumb-tint-color var value)
  (display (generate-assign-color var "thumbTintColor" value))
  (newline))

(define (generate-thumb-image-for-state var value)
  (display (generate-set-image-for-state var "setThumbImage" value))
  (newline))

(define the-view-attribute-generators
  (list (cons 'background-color generate-background-color)
        (cons 'hidden generate-hidden)
        (cons 'alpha generate-alpha)
        (cons 'opaque generate-opaque)
        (cons 'clips-to-bounds generate-clips-to-bounds)
        (cons 'clears-context-before-drawing generate-clears-context-before-drawing)
        (cons 'user-interaction-enabled generate-user-interaction-enabled)
        (cons 'multiple-touch-enabled generate-multiple-touch-enabled)
        (cons 'exclusive-touch generate-exclusive-touch)
        (cons 'autoresizing-mask generate-autoresizing-mask)
        (cons 'autoresizes-subviews generate-autoresizes-subviews)
        (cons 'content-mode generate-content-mode)
        (cons 'content-stretch generate-content-stretch)
        (cons 'content-scale-factor generate-content-scale-factor)))

(define the-control-attribute-generators
  (list (cons 'enabled generate-enabled)
        (cons 'selected generate-selected)
        (cons 'highlighted generate-highlighted)
        (cons 'content-vertical-alignment generate-content-vertical-alignment)
        (cons 'content-horizontal-alignment generate-content-horizontal-alignment)))

(define the-label-attribute-generators
  (append the-view-attribute-generators
          (list (cons 'text generate-text)
                (cons 'font generate-font)
                (cons 'text-color generate-text-color)
                (cons 'text-alignment generate-text-alignment)
                (cons 'line-break-mode generate-line-break-mode)
                (cons 'enabled generate-enabled)
                (cons 'adjusts-font-size-to-fit-width generate-adjusts-font-size-to-fit-width)
                (cons 'baseline-adjustment generate-baseline-adjustment)
                (cons 'minimum-font-size generate-minimum-font-size)
                (cons 'number-of-lines generate-number-of-lines)
                (cons 'highlighted-text-color generate-highlighted-text-color)
                (cons 'highlighted generate-highlighted)
                (cons 'shadow-color generate-shadow-color)
                (cons 'shadow-offset generate-shadow-offset))))

(define the-button-attribute-generators
  (append the-view-attribute-generators
          the-control-attribute-generators
          (list (cons 'reverses-title-shadow-when-highlighted generate-reverses-title-shadow-when-highlighted)
                (cons 'title-for-state generate-title-for-state)
                (cons 'title-color-for-state generate-title-color-for-state)
                (cons 'title-shadow-color-for-state generate-title-shadow-color-for-state)
                (cons 'adjusts-image-when-highlighted generate-adjusts-image-when-highlighted)
                (cons 'adjusts-image-when-disabled generate-adjusts-image-when-disabled)
                (cons 'shows-touch-when-highlighted generate-shows-touch-when-highlighted)
                (cons 'background-image-for-state generate-background-image-for-state)
                (cons 'image-for-state generate-image-for-state)
                (cons 'content-edge-insets generate-content-edge-insets)
                (cons 'title-edge-insets generate-title-edge-insets)
                (cons 'image-edge-insets generate-title-edge-insets))))

(define the-image-attribute-generators
  (list (cons 'image generate-image)
        (cons 'highlighted-image generate-highlighted-image)
        (cons 'animation-images generate-animation-images)
        (cons 'highlighted-animation-images generate-highlighted-animation-images)
        (cons 'animation-duration generate-animation-duration)
        (cons 'animation-repeat-count generate-animation-repeat-count)
        (cons 'user-interaction-enabled generate-interaction-enabled)
        (cons 'highlighted generate-highlighted)
        (cons 'tint-color generate-tint-color)))

(define the-slider-attribute-generators
  (append the-view-attribute-generators
          the-control-attribute-generators
          (list (cons 'value generate-value)
                (cons 'minimum-value generate-minimum-value)
                (cons 'maximum-value generate-maximum-value)
                (cons 'continuous generate-continuous)
                (cons 'minimum-value-image generate-minimum-value-image)
                (cons 'maximum-value-image generate-maximum-value-image)
                (cons 'minimum-track-tint-color generate-minimum-track-tint-color)
                (cons 'minimum-track-image-for-state generate-minimum-track-image-for-state)
                (cons 'maximum-track-tint-color generate-maximum-track-tint-color)
                (cons 'maximum-track-image-for-state generate-maximum-track-image-for-state)
                (cons 'thumb-tint-color generate-thumb-tint-color)
                (cons 'thumb-image-for-state generate-thumb-image-for-state))))
