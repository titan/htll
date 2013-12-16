(load "view.scm")

(define the-layout-tree '())

(define the-variables '()) ; (list (cons var (cons value root)))

(define (lookup-variable-by-value val root)
  (let loop ((vars the-variables))
    (if (not (null? vars))
        (if (and (eq? val (cadar vars)) (eq? root (cddar vars)))
            (caar vars)
            (loop (cdr vars)))
        (error "No binding found for " val "in" root))))

(define (lookup-variable-by-value-ignoring-root val)
  (let loop ((vars the-variables))
    (if (not (null? vars))
        (if (eq? val (cadar vars))
            (caar vars)
            (loop (cdr vars)))
        #f)))

(define (scan-variable-value root env)
  (define (env-loop env)
    (define (scan vars vals)
      (if (null? vars)
          (env-loop (enclosing-environment env))
          (let ((var (car vars))
                (val (car vals)))
            (if (and (pair? val) (assq (view-type val) the-type-definitions))
                (let ((tmp (assq var the-variables)))
                  (if tmp
                      (if (not (eq? (cadr tmp) val))
                          (error var "binds to two values"))
                      (set! the-variables (cons (cons var (cons val root)) the-variables)))))
            (scan (cdr vars) (cdr vals)))))
    (if (not (eq? env the-empty-environment))
        (let ((frame (first-frame env)))
          (scan (frame-variables frame)
                (frame-values frame)))))
  (env-loop env))

(define (generate-normal-init type view)
  (string-append "[[" type " alloc] init]"))

(define (generate-button-init type view)
  (let ((tag (view-type view)))
    (string-append "[" type " buttonWithType:"
                   (cond ((eq? tag 'rounded-rect-button) "UIButtonTypeRoundedRect")
                         ((eq? tag 'detail-disclosure-button) "UIButtonTypeDetailDisclosure")
                         ((eq? tag 'info-light-button) "UIButtonTypeInfoLight")
                         ((eq? tag 'info-dark-button) "UIButtonTypeInfoDark")
                         ((eq? tag 'contact-add-button) "UIButtonTypeContactAdd")
                         (else "UIButtonTypeCustom")) "]")))

(define (generate-font-init type view)
  (let ((tag (view-type view)))
    (cond
     ((eq? tag 'font) (string-append "[" type " name:@\"" (cadr view) "\" size:" (number->string (caddr view)) "]"))
     ((eq? tag 'system-font-of-size) (string-append "[" type " systemFontOfSize:" (number->string (cadr view)) "]"))
     ((eq? tag 'bold-system-font-of-size) (string-append "[" type " boldSystemFontOfSize:" (number->string (cadr view)) "]"))
     ((eq? tag 'italic-system-font-of-size) (string-append "[" type " italicSystemFontOfSize:" (number->string (cadr view)) "]")))))

(define (generate-segmented-control-init type view)
  (let* ((attrs (view-attributes view))
         (items (assq 'items attrs)))
    (if items
        (let loop ((array (reverse (cdr items)))
                   (result '()))
          (if (null? array)
              (string-append "[[" type " alloc] initWithItems:" (generate-array result) "]")
              (let ((ref (lookup-variable-by-value-ignoring-root (car array))))
                (if ref
                    (loop (cdr array) (cons (symbol->string ref) result))
                    (cond
                     ((string? (car array)) (loop (cdr array) (cons (generate-string (car array)) result)))
                     ((eq? 'image-named (view-type (car array))) (loop (cdr array) (cons (generate-image-named (car array)) result)))
                     (else (error "Unsupported type " (car array) "need string or image")))))))
        (error "Missing items in " view))))

(define the-resource-types
  '(font system-font-of-size bold-system-font-of-size italic-system-font-of-size image-named hsba-color rgba-color))

(define the-type-definitions ; (list (cons view-type (cons type-string init-fun)))
  (list (cons 'view (cons "UIView" generate-normal-init))
        (cons 'scroll (cons "UIScrollView" generate-normal-init))
        (cons 'font (cons "UIFont" generate-font-init))
        (cons 'system-font-of-size (cons "UIFont" generate-font-init))
        (cons 'bold-system-font-of-size (cons "UIFont" generate-font-init))
        (cons 'italic-system-font-of-size (cons "UIFont" generate-font-init))
        (cons 'label (cons "UILabel" generate-normal-init))
        (cons 'custom-button (cons "UIButton" generate-button-init))
        (cons 'rounded-rect-button (cons "UIButton" generate-button-init))
        (cons 'detail-disclosure-button (cons "UIButton" generate-button-init))
        (cons 'info-light-button (cons "UIButton" generate-button-init))
        (cons 'info-dark-button (cons "UIButton" generate-button-init))
        (cons 'contact-add-button (cons "UIButton" generate-button-init))
        (cons 'image (cons "UIImageView" generate-normal-init))
        (cons 'slider (cons "UISlider" generate-normal-init))
        (cons 'segmented-control (cons "UISegmentedControl" generate-segmented-control-init))
        (cons 'text-field (cons "UITextField" generate-normal-init))
        (cons 'text-view (cons "UITextView" generate-normal-init))))

(define (type-definition-type definition)
  (car definition))

(define (type-definition-type-string definition)
  (cadr definition))

(define (type-definition-init-fun definition)
  (cddr definition))

(define (view-attributes view)
  (cadr view))

(define (view attrs)
  (list 'view attrs))

(define (scroll attrs)
  (list 'scroll attrs))

(define (label attrs)
  (list 'label attrs))

(define (custom-button attrs)
  (list 'custom-button attrs))

(define (rounded-rect-button attrs)
  (list 'rounded-rect-button attrs))

(define (detail-disclosure-button attrs)
  (list 'detail-disclosure-button attrs))

(define (info-light-button attrs)
  (list 'info-light-button attrs))

(define (info-dark-button attrs)
  (list 'info-dark-button attrs))

(define (contact-add-button attrs)
  (list 'contact-add-button attrs))

(define (image attrs)
  (let ((ref (assq 'image attrs)))
    (if ref
        (list 'image attrs)
        (error "Missing image" attrs))))

(define (slider attrs)
  (list 'slider attrs))

(define (segmented-control attrs)
  (list 'segmented-control attrs))

(define (text-field attrs)
  (list 'text-field attrs))

(define (text-view attrs)
  (list 'text-view attrs))

(define (localized key default)
  (if (and (string? key) (string? default))
      (list 'localized key default)
      (error "Invalid localized" key default)))

(define (localized-key value)
  (cadr value))

(define (localized-default value)
  (caddr value))

(define (hsba-color hue saturation brightness alpha)
  (if (and (real? hue) (real? saturation) (real? brightness) (real? alpha))
      (list 'hsba-color hue saturation brightness alpha)
      (error "Invalid hsba-color" hue saturation brightness alpha)))

(define (rgba-color red green blue alpha)
  (if (and (real? red) (real? green) (real? blue) (real? alpha))
      (list 'rgba-color red green blue alpha)
      (error "Invalid rgba-color" red green blue alpha)))

(define (system-font-of-size size)
  (if (number? size)
      (list 'system-font-of-size size)
      (error "Invalid system-font-of-size" size)))

(define (bold-system-font-of-size size)
  (if (number? size)
      (list 'bold-system-font-of-size size)
      (error "Invalid bold-system-font-of-size" size)))

(define (italic-system-font-of-size size)
  (if (number? size)
      (list 'italic-system-font-of-size size)
      (error "Invalid italic-system-font-of-size" size)))

(define (font name size)
  (if (and (string? name) (number? size))
      (list 'font name size)
      (error "Invalid font" name size)))

(define (label-font-size)
  (list 'label-font-size))

(define (button-font-size)
  (list 'button-font-size))

(define (small-system-font-size)
  (list 'small-system-font-size))

(define (system-font-size)
  (list 'system-font-size))

(define (image-named name)
  (if (string? name)
      (list 'image-named name)
      (error "Invalid image-named" name)))

(define (size width height)
  (if (and (number? width) (number? height))
      (list 'size width height)
      (error "Invalid size" width height)))

(define (rect x y width height)
  (if (and (number? x) (number? y) (number? width) (number? height))
      (list 'rect x y width height)
      (error "Invalid rect" x y width height)))

(define (edge-insets top left bottom right)
  (if (and (number? top) (number? left) (number? bottom) (number? right))
      (list 'edge-insets top left bottom right)
      (error "Invalid edge-insets" top left bottom right)))

(define (offset h v)
  (if (and (number? h) (number? v))
      (list 'offset h v)
      (error "Invalid offset" h v)))

(define (range loc len)
  (if (and (number? loc) (number? len))
      (list 'range loc len)
      (error "Invalid range" loc len)))

(define (blank)
  (list 'blank))

(define (in children parent)
  (scan-variable-value parent the-current-environment)
  (set! the-layout-tree (cons (cons parent children) the-layout-tree)))

(define (basic-relationship-type? view)
  (eq? 'above (view-type view)) (eq? 'on (view-type view)) (eq? 'beside (view-type view)) (eq? 'close-to (view-type view)))

(define (view-type view)
  (car view))

(define (view-ratio view)
  (cadddr view))

(define (view-margin view)
  (cadddr view))

(define (on up low margin)
  (list 'on up low margin))

(define (above up low ratio)
  (list 'above up low ratio))

(define (up-view view)
  (cadr view))

(define (low-view view)
  (caddr view))

(define (close-to left right margin)
  (list 'close-to left right margin))

(define (beside left right ratio)
  (list 'beside left right ratio))

(define (left-view view)
  (cadr view))

(define (right-view view)
  (caddr view))

(define (center view horizontal-ratio vertical-ratio)
  (let ((r1 (/ (- 1 (* 2 horizontal-ratio)) (- 1 horizontal-ratio)))
        (r2 (/ (- 1 (* 2 vertical-ratio)) (- 1 vertical-ratio))))
    (beside (blank) (beside (above (blank) (above view (blank) r2) vertical-ratio) (blank) r1) horizontal-ratio)))

(define (horizontal-sequence . views)
  (define (hseq views)
    (let ((head (car views))
          (tail (cdr views))
          (len (length views)))
      (if (= 1 len)
          head
          (beside head (hseq tail) (/ 1 len)))))
  (hseq views))

(define (vertical-sequence . views)
  (define (vseq views)
    (let ((head (car views))
          (tail (cdr views))
          (len (length views)))
      (if (= 1 len)
          head
          (above head (vseq tail) (/ 1 len)))))
  (vseq views))

(define dsl-procedures
  (list (list 'in in)
        (list 'on on)
        (list 'above above)
        (list 'close-to close-to)
        (list 'beside beside)
        (list 'center center)
        (list 'hseq horizontal-sequence)
        (list 'vseq vertical-sequence)
        (list 'view view)
        (list 'scroll scroll)
        (list 'label label)
        (list 'custom-button custom-button)
        (list 'rounded-rect-button rounded-rect-button)
        (list 'detail-disclosure-button detail-disclosure-button)
        (list 'info-light-button info-light-button)
        (list 'info-dark-button info-dark-button)
        (list 'contact-add-button contact-add-button)
        (list 'image image)
        (list 'slider slider)
        (list 'segmented-control segmented-control)
        (list 'text-field text-field)
        (list 'text-view text-view)
        (list 'localized localized)
        (list 'hsba-color hsba-color)
        (list 'rgba-color rgba-color)
        (list 'font font)
        (list 'image-named image-named)
        (list 'system-font-of-size system-font-of-size)
        (list 'bold-system-font-of-size bold-system-font-of-size)
        (list 'italic-system-font-of-size italic-system-font-of-size)
        (list 'label-font-size label-font-size)
        (list 'button-font-size button-font-size)
        (list 'small-system-font-size small-system-font-size)
        (list 'system-font-size system-font-size)
        (list 'size size)
        (list 'rect rect)
        (list 'edge-insets edge-insets)
        (list 'offset offset)
        (list 'range range)))

(define (dsl-procedure-names)
  (map car dsl-procedures))

(define (dsl-procedure-objects)
  (map (lambda (proc) (list 'primitive (cadr proc))) dsl-procedures))

(define (setup-dsl-environment env)
  (let ((initial-env (extend-environment (dsl-procedure-names)
                                         (dsl-procedure-objects)
                                         env)))
    (define-variable! 'blank (blank) initial-env)
    (define-variable! 'yes #t initial-env)
    (define-variable! 'no #f initial-env)
    (set! the-current-environment initial-env)
    initial-env))

(define (generate-property-by-type-definition type var)
  (display (string-append "@property (nonatomic, strong) " type " * " (symbol->string var) ";"))
  (newline))

(define (generate-property env)
  (let loop ((vars the-variables))
    (if (not (null? vars))
        (let ((definition (assq (view-type (cadar vars)) the-type-definitions)))
          (if definition
              (generate-property-by-type-definition (type-definition-type-string definition) (caar vars)))
          (loop (cdr vars))))))

(define (generate-synthesize env)
  (define (generate var)
    (display (string-append "@synthesize " (symbol->string var) ";"))
    (newline))
  (let loop ((vars the-variables))
    (if (not (null? vars))
        (begin
          (generate (caar vars))
          (loop (cdr vars))))))

(define (generate-view-did-load env)
  (define (generate type type-string init-fun root var view)
    (display (string-append (symbol->string var) " = " (init-fun type-string view) ";"))
    (newline)
    (let ((res (memq type the-resource-types)))
      (if (not res) ; resource types don't need to be add to root view
          (begin
            (display (string-append "[" (symbol->string root) " addSubview:" (symbol->string var) "];"))
            (newline)))))
  (let loop ((vars the-variables))
    (if (not (null? vars))
        (let ((definition (assq (view-type (cadar vars)) the-type-definitions)))
          (if definition
              (let ((type (type-definition-type definition))
                    (type-string (type-definition-type-string definition))
                    (init-fun (type-definition-init-fun definition))
                    (root (cddar vars))
                    (var (caar vars))
                    (view (cadar vars)))
                (generate type type-string init-fun root var view)))
          (loop (cdr vars))))))

(define (generate-view-attributes generators var view)
  (let ((varstr (symbol->string var)))
    (let loop ((attrs (view-attributes view)))
      (if (not (null? attrs))
        (let ((attr (car attrs)))
          (let ((generator (assq (car attr) generators)))
            (if generator
                (begin
                  (display ((cdr generator) (symbol->string var) (cdr attr)))
                  (newline))
                (error "Invalid attribute" (car attr) "for" var)))
          (loop (cdr attrs)))))))

(define the-attribute-generators
  (list (cons 'view the-view-attribute-generators)
        (cons 'scroll the-scroll-attribute-generators)
        (cons 'label the-label-attribute-generators)
        (cons 'custom-button the-button-attribute-generators)
        (cons 'rounded-rect-button the-button-attribute-generators)
        (cons 'detail-disclosure-button the-button-attribute-generators)
        (cons 'info-light-button the-button-attribute-generators)
        (cons 'info-dark-button the-button-attribute-generators)
        (cons 'contact-add-button the-button-attribute-generators)
        (cons 'image the-image-attribute-generators)
        (cons 'slider the-slider-attribute-generators)
        (cons 'segmented-control the-segmented-control-attribute-generators)
        (cons 'text-field the-text-field-attribute-generators)
        (cons 'text-view the-text-view-attribute-generators)))

(define (generate-view-will-appear env)
  (let loop ((vars the-variables))
    (if (not (null? vars))
        (let ((generators (assq (view-type (cadar vars)) the-attribute-generators)))
          (if generators
              (generate-view-attributes (cdr generators) (caar vars) (cadar vars)))
          (loop (cdr vars))))))

(define (exp-optimizer exp)
  (define (lift-snd op a b) ; (+ 1 (+ 2 x)) => (+ 3 x)
    (let ((c (cadr b))
          (d (caddr b))
          (subop (car b))
          (exp `(,op ,a ,b)))
      (cond
       ((number? c)
        (cond
         ((eq? op '+)
          (cond
           ((eq? subop '+) `(+ ,(+ a c) ,d))
           ((eq? subop '-) `(- ,(+ a c) ,d))
           (else exp)))
         ((eq? op '-)
          (cond
           ((eq? subop '+) `(- ,(- a c) ,d))
           ((eq? subop '-) `(+ ,(- a c) ,d))
           (else exp)))
         ((eq? op '*)
          (cond
           ((eq? subop '*) `(* ,(* a c) ,d))
           (else exp)))))
       ((number? d)
        (cond
         ((eq? op '+)
          (cond
           ((eq? subop '+) `(+ ,(+ a d) ,c))
           ((eq? subop '-) `(- ,(+ a d) ,c))
           (else exp)))
         ((eq? op '-)
          (cond
           ((eq? subop '+) `(- ,(- a d) ,c))
           ((eq? subop '-) `(+ ,(- a d) ,c))
           (else exp)))
         ((eq? op '*)
          (cond
           ((eq? subop '*) `(* ,(* a d) ,c))
           (else exp)))))
       (else exp))))
  (define (lift-fst op a b) ; (+ (+ 1 x) 2) => (+ 3 x)
    (let ((c (cadr a))
          (d (caddr a))
          (subop (car a))
          (exp `(,op ,a ,b)))
      (cond
       ((number? c)
        (cond
         ((eq? op '+)
          (cond
           ((eq? subop '+) `(+ ,(+ b c) ,d))
           ((eq? subop '-) `(- ,(+ b c) ,d))
           (else exp)))
         ((eq? op '-)
          (cond
           ((eq? subop '+) `(+ ,(- c b) ,d))
           ((eq? subop '-) `(- ,(- c b) ,d))
           (else exp)))
         ((eq? op '*)
          (cond
           ((eq? subop '*) `(* ,(* b c) ,d))
           (else exp)))))
       ((number? d)
        (cond
         ((eq? op '+)
          (cond
           ((eq? subop '+) `(+ ,c ,(+ b d)))
           ((eq? subop '-) `(+ ,c ,(- b d)))
           (else exp)))
         ((eq? op '-)
          (cond
           ((eq? subop '+) `(+ ,c ,(- d b)))
           ((eq? subop '-) `(- ,c ,(+ b d)))
           (else exp)))
         ((eq? op '*)
          (cond
           ((eq? subop '*) `(* ,c ,(* b d)))
           (else exp)))))
       (else exp))))
  (define (combine exp)
    (define (combine-single-b op fst snd) ; (+ (* 2 x) x) => (* 3 x)
      (let ((a (cadr fst))
            (b (caddr fst))
            (subop (car fst)))
        (cond
         ((eq? a snd)
          (if (number? b)
              (cond
               ((eq? op '+) `(,subop ,a ,(+ b 1)))
               ((eq? op '-) `(,subop ,a ,(- b 1)))
               (else `(,op ,fst ,snd)))
              `(,op ,fst ,snd)))
         ((eq? b snd)
          (if (number? a)
              (cond
               ((eq? op '+) `(,subop ,b ,(+ a 1)))
               ((eq? op '-) `(,subop ,b ,(- a 1)))
               (else `(,op ,fst ,snd)))
              `(,op ,fst ,snd)))
         (else `(,op ,fst ,snd)))))
    (define (combine-single-a op fst snd) ;; (- x (* 3 x)) => (* -2 x)
      (let ((a (cadr snd))
            (b (caddr snd))
            (subop (car snd)))
        (cond
         ((eq? a fst)
          (if (number? b)
              (cond
               ((eq? op '+) `(,subop ,a ,(+ 1 b)))
               ((eq? op '-) `(,subop ,a ,(- 1 b)))
               (else `(,op ,fst ,snd)))
              `(,op ,fst ,snd)))
         ((eq? b fst)
          (if (number? a)
              (cond
               ((eq? op '+) `(,subop ,b ,(+ 1 a)))
               ((eq? op '-) `(,subop ,b ,(- 1 a)))
               (else `(,op ,fst ,snd)))
              `(,op ,fst ,snd)))
         (else `(,op ,fst ,snd)))))
    (define (combine-both op fst snd) ;; (+ (* 2 x) (* x 3)) => (* 5 x)
      (let ((a (cadr fst))
            (b (caddr fst))
            (op1 (car fst))
            (c (cadr snd))
            (d (caddr snd))
            (op2 (car snd)))
        (cond
         ((eq? a c)
          (if (and (number? b) (number? d))
              (cond
               ((eq? op '+) `(,op1 ,a ,(+ b d)))
               ((eq? op '-) `(,op1 ,a ,(- b d)))
               (else `(,op ,fst ,snd)))
              `(,op1 ,a (,op b d))))
         ((eq? a d)
          (if (and (number? b) (number? c))
              (cond
               ((eq? op '+) `(,op1 ,a ,(+ b c)))
               ((eq? op '-) `(,op1 ,a ,(- b c)))
               (else `(,op ,fst ,snd)))
              `(,op1 ,a (,op b c))))
         ((eq? b c)
          (if (and (number? a) (number? c))
              (cond
               ((eq? op '+) `(,op1 ,b ,(+ a d)))
               ((eq? op '-) `(,op1 ,b ,(- a d)))
               (else `(,op ,fst ,snd)))
              `(,op1 ,b (,op a d))))
         ((eq? b d)
          (if (and (number? a) (number? c))
              (cond
               ((eq? op '+) `(,op1 ,b ,(+ a c)))
               ((eq? op '-) `(,op1 ,b ,(- a c)))
               (else `(,op ,fst ,snd)))
              `(,op1 ,b (,op a c))))
         (else `(,op ,fst ,snd)))))
    (let ((a (cadr exp))
          (b (caddr exp))
          (op (car exp)))
      (if (eq? op '*)
          exp
          (cond
           ((and (pair? a) (eq? (car a) '*) (pair? b) (eq? (car b) '*)) (combine-both op a b))
           ((and (pair? a) (eq? (car a) '*)) (combine-single-b op a b))
           ((and (pair? b) (eq? (car b) '*)) (combine-single-a op a b))
           (else exp)))))
  (define (reduce exp op sym)
    (let ((a (exp-optimizer (cadr exp)))
          (b (exp-optimizer (caddr exp))))
      (cond ((and (number? a) (number? b))
             (op a b))
            ((number? a)
             (if (= a 0)
                 (cond
                  ((eq? sym '+) b)
                  ((eq? sym '-) `(- 0 ,b))
                  ((eq? sym '*) 0))
                 (if (and (= a 1) (eq? sym '*))
                     b
                     (lift-snd sym a b))))
            ((number? b)
             (if (= b 0)
                 (if (eq? sym '*)
                     0
                     a)
                 (if (and (= b 1) (eq? sym '*))
                     a
                     (if (pair? a)
                         (lift-fst sym a b)
                         `(,sym ,a ,b)))))
            (else (combine `(,sym ,a ,b))))))
  (cond
   ((number? exp) exp)
   ((tagged-list? exp '+)
    (reduce exp + '+))
   ((tagged-list? exp '-)
    (reduce exp - '-))
   ((tagged-list? exp '*)
    (reduce exp * '*))
   (else exp)))

(define (layout-eval exp priority) ;; (+ x y) => x + y
  (let ((exp (exp-optimizer exp)))
    (cond
     ((number? exp)
      (if (< exp 0)
          (string-append "(" (number->string exp) ")")
          (number->string exp)))
     ((tagged-list? exp '+)
      (if (> priority 0)
          (string-append "(" (layout-eval (cadr exp) 0) " + " (layout-eval (caddr exp) 0) ")")
          (string-append (layout-eval (cadr exp) 0) " + " (layout-eval (caddr exp) 0))))
     ((tagged-list? exp '-)
      (if (> priority 1)
          (string-append "(" (layout-eval (cadr exp) 1) " - " (layout-eval (caddr exp) 1) ")")
          (string-append (layout-eval (cadr exp) 1) " - " (layout-eval (caddr exp) 1))))
     ((tagged-list? exp '*)
      (string-append (layout-eval (cadr exp) 2) " * " (layout-eval (caddr exp) 2)))
     (else (symbol->string exp)))))

(define (generate-view-frame var x y width height)
  (display (string-append (symbol->string var) ".frame = (CGRect) {" (layout-eval x 0) ", " (layout-eval y 0) ", " (layout-eval width 0) ", " (layout-eval height 0) "};"))
  (newline))

(define (generate-view-will-layout-subviews env)
  (define (layout-loop tree)
    (define (layout root view x y width height)
      (cond
       ((eq? 'above (view-type view))
        (let ((up (up-view view))
              (low (low-view view))
              (ratio (view-ratio view)))
          (layout root up x y width `(* ,height ,ratio))
          (layout root low x `(+ ,y (* ,height ,ratio)) width `(* ,height (- 1 ,ratio)))
          (list x y width height)))
       ((eq? 'on (view-type view))
        (let ((up (up-view view))
              (low (low-view view))
              (margin (view-margin view)))
          (let* ((frame1 (layout root up x y width 0))
                 (frame2 (layout root low x `(+ (+ ,y ,(cadddr frame1)) ,margin) width 0)))
            (list x y width `(+ (+ ,(cadddr frame1) ,(cadddr frame2)) ,margin)))))
       ((eq? 'beside (view-type view))
        (let ((left (left-view view))
              (right (right-view view))
              (ratio (view-ratio view)))
          (layout root left x y `(* ,width ,ratio) height)
          (layout root right `(+ ,x (* ,width ,ratio)) y `(* ,width (- 1 ,ratio)) height)
          (list x y width height)))
       ((eq? 'close-to (view-type view))
        (let ((left (left-view view))
              (right (right-view view))
              (margin (view-margin view)))
          (let* ((frame1 (layout root left x y 0 height))
                 (frame2 (layout root right `(+ (+ ,x ,(caddr frame1)) ,margin) y 0 height)))
            (list x y `(+ (+ ,(cadddr frame1) ,(cadddr frame2)) ,margin) height))))
       (else
        (let ((type-definition (assq (view-type view) the-type-definitions)))
          (if type-definition
              (let* ((var (lookup-variable-by-value view root))
                     (w (if (and (number? width) (= 0 width)) (string->symbol (string-append (symbol->string var) ".bounds.size.width")) width))
                     (h (if (and (number? height) (= 0 height)) (string->symbol (string-append (symbol->string var) ".bounds.size.height")) height)))
                (generate-view-frame var x y w h)
                (list x y w h))
              (list x y width height) ;; unknown view or blank
              )))))
    (if (not (null? tree))
        (let ((root (caar tree))
              (rootstr (symbol->string (caar tree)))
              (children (cdar tree)))
          (layout root children 0 0 (string->symbol (string-append rootstr ".bounds.size.width")) (string->symbol (string-append rootstr ".bounds.size.height")))
          (layout-loop (cdr tree)))))
  (layout-loop the-layout-tree))
