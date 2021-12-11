(defcustom fold-template-error-text-length-limit 40
  "When the length of a piece of text wrapped in a innermost
bracket exceeds the limit, it will be folded.")

(defcustom fold-template-error-open-markers '(?< ?{ ?\[)
  "Characters indicating the opening of brackets.")

(defcustom fold-template-error-close-markers '(?> ?} ?\])
  "Characters indicating the closing of brackets.")

(defcustom fold-template-error-generate-replacement-text
  (lambda (text)
    (format "<%s...>" (substring text 0 fold-template-error-text-length-limit)))
  "The function is used to generate the replacement of folded text.")

;; simple parsers
(defun fold-template-error--parse (message)
  (multiple-value-bind
        (children next) (fold-template-error--parse-many-text-or-angle message 1)
    (list :type 'angle :children children)))

(defun fold-template-error--is-open-marker (char)
  (find char fold-template-error-open-markers))

(defun fold-template-error--is-close-marker (char)
  (find char fold-template-error-close-markers))

(defun fold-template-error--parse-many-text-or-angle(message cursor)
  (let (children)
    (loop while (and
                 (< cursor (length message))
                 (not (fold-template-error--is-close-marker (aref message cursor)))) do
         (if (fold-template-error--is-open-marker (aref message cursor))
             (progn
               (incf cursor)
               (multiple-value-bind
                     (child next) (fold-template-error--parse-angle message cursor)
                 (push child children)
                 (setf cursor next)))
           (multiple-value-bind
                 (child next) (fold-template-error--parse-text message cursor)
             (push child children)
             (setf cursor next))))
    (values (reverse children) cursor)))

(defun fold-template-error--parse-angle (message cursor)
  (let ((first cursor))
    (multiple-value-bind
          (children next) (fold-template-error--parse-many-text-or-angle message cursor)
      (if (and (< next (length message)) (fold-template-error--is-close-marker (aref message next)))
          (incf next)
        (message "unbalanced angle bracket!"))
      (values (list :type 'angle :first first :last next :children children) next))))

(defun fold-template-error--parse-text (message cursor)
  (let ((first cursor))
    (loop while (and
                 (< cursor (length message))
                 (not
                  (let ((char (aref message cursor)))
                    (or (fold-template-error--is-open-marker char )
                        (fold-template-error--is-close-marker char))))) do
         (incf cursor))
    (values (list :type 'text :first first :last cursor) cursor)))

(defun fold-template-error--is-angle (tree)
  (let ((type (getf tree :type)))
    (eq type 'angle)))

(defun fold-template-error--is-text (tree)
  (let ((type (getf tree :type)))
    (eq type 'text)))

(defun fold-template-error--mapc-inner-most-angles (func tree)
  (when (fold-template-error--is-angle tree)
    (let* ((children (getf tree :children))
           (subangles (remove-if-not #'fold-template-error--is-angle children)))
      (if subangles ;; not inner-most
          (cl-flet ((g (subtree)
                      (fold-template-error--mapc-inner-most-angles func subtree)))
            (mapc #'g subangles))
        (funcall func tree)))))

(defun fold-template-error--init-overlay (overlay text type)
  (overlay-put overlay 'name "fold-template-error")
  (let ((threshold fold-template-error-text-length-limit))
    (if (> (length text) threshold)
        (let ((replacement
               (format "<%s...>" (substring text 0 threshold))))
          (overlay-put overlay 'display replacement))))
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd "RET")
      (lambda ()
        (interactive)
        (if (overlay-get overlay 'display)
            (overlay-put overlay 'display nil)
          (overlay-put overlay 'display "<..>"))))
    (overlay-put overlay 'local-map keymap)))

(defun fold-template-error--create-overlays-for-inner-most-angles (buffer tree)
  (cl-flet ((func (subtree)
              (let ((first (getf subtree :first)) ;; points to '<'
                    (last (getf subtree :last))) ;; points to the last char before '>'
                (let* ((buffer-text (with-current-buffer buffer (buffer-string)))
                       (inner-text (substring-no-properties buffer-text first (- last 1)))
                       (overlay (make-overlay first (+ last 1) buffer)))
                  (fold-template-error--init-overlay overlay inner-text (aref buffer-text (- first 1)))))))
            (fold-template-error--mapc-inner-most-angles #'func tree)))

(defun fold-template-error--clear-inner-most-angles (buffer tree)
  (remove-overlays (point-min) (point-max) "fold-template-error"))

(set (make-local-variable 'fold-template-error--folded) nil)

(defun fold-template-error-fold-all ()
  (interactive)
  (let ((tree (fold-template-error--parse (substring-no-properties (buffer-string)))))
    (fold-template-error--create-overlays-for-inner-most-angles(current-buffer) tree))
  (setf fold-template-error--folded t))

(defun fold-template-error-unfold-all ()
  (interactive)
  (remove-overlays (point-min) (point-max) "fold-template-error")
  (setf fold-template-error--folded nil))

(defun fold-template-error-toggle-all ()
  (interactive)
  (if fold-template-error--folded
      (fold-template-error-unfold-all)
    (fold-template-error-fold-all)))

(add-hook 'compilation-finish-functions
          (lambda (buffer message)
            (fold-template-error-fold-all)))