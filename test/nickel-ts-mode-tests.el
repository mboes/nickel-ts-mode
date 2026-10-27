;;; nickel-ts-mode-tests.el --- Tests for nickel-ts-mode -*- lexical-binding: t; -*-

;;; Commentary:

;; Run with `eldev test'.  Highlighting tests live in
;; nickel-ts-mode-resources/: each file is a Nickel expression annotated
;; with comments whose carets point at the expected face (see
;; `ert-font-lock-deftest-file').  Every test is skipped when the grammar
;; is not installed; highlighting tests are also skipped before Emacs 30,
;; which lacks ert-font-lock, and formatting tests without `nickel'.

;;; Code:

(require 'ert)
(require 'ert-font-lock nil t)
(require 'ert-x)
(require 'nickel-ts-mode)

(defmacro nickel-ts-test-with-buffer (contents &rest body)
  "Run BODY in a `nickel-ts-mode' buffer holding CONTENTS.
Point starts at the `|' in CONTENTS, which is removed."
  (declare (indent 1))
  `(progn
     (skip-unless (treesit-ready-p 'nickel t))
     (with-temp-buffer
       (insert ,contents)
       (goto-char (point-min))
       (search-forward "|")
       (delete-char -1)
       (nickel-ts-mode)
       ,@body)))

;;; Font lock

(ert-deftest nickel-ts-queries-compile ()
  "Every font-lock query compiles against the installed grammar."
  (skip-unless (treesit-ready-p 'nickel t))
  (with-temp-buffer
    (treesit-parser-create 'nickel)
    ;; An invalid query signals `treesit-query-error'.
    (dolist (setting nickel-ts-mode--font-lock-settings)
      (treesit-query-capture 'nickel (car setting)))))

(defmacro nickel-ts-deftest-faces (name file)
  "Define test NAME checking the faces annotated in FILE, at level 4."
  `(ert-deftest ,name ()
     (skip-unless (and (treesit-ready-p 'nickel t)
                       (featurep 'ert-font-lock)))
     (let ((treesit-font-lock-level 4))
       (ert-font-lock-test-file (ert-resource-file ,file) 'nickel-ts-mode))))

(nickel-ts-deftest-faces nickel-ts-faces-comments "comments.ncl")
(nickel-ts-deftest-faces nickel-ts-faces-constants "constants.ncl")
(nickel-ts-deftest-faces nickel-ts-faces-definitions "definitions.ncl")
(nickel-ts-deftest-faces nickel-ts-faces-functions "functions.ncl")
(nickel-ts-deftest-faces nickel-ts-faces-strings "strings.ncl")
(nickel-ts-deftest-faces nickel-ts-faces-types "types.ncl")

;;; Navigation

(ert-deftest nickel-ts-end-of-defun-skips-separator ()
  "`end-of-defun' steps over the `in' or `,' that ends a block."
  (nickel-ts-test-with-buffer "|let x = 1 in\n{\n  a = x,\n  b = 2,\n}\n"
    (end-of-defun)
    (should (looking-at-p "{"))
    (search-forward "a")
    (end-of-defun)
    (should (looking-at-p "  b = 2"))))

(ert-deftest nickel-ts-forward-sexp-over-lists ()
  "`forward-sexp' moves over strings and arrays as single units."
  (skip-unless (>= emacs-major-version 31))
  (nickel-ts-test-with-buffer "[|m%\"say \"hi\"\"%, [1, 2]]"
    (forward-sexp)
    (should (looking-at-p ", \\["))
    (forward-sexp)
    (should (looking-at-p "]\\'"))))

;;; Formatting

(ert-deftest nickel-ts-format ()
  (skip-unless (executable-find nickel-ts-command))
  (nickel-ts-test-with-buffer "let x={a=1,\n      b=|2} in x\n"
    (nickel-ts-format-buffer)
    (should (equal (buffer-string) "let x = {\n  a = 1,\n  b = 2\n}\nin x\n"))
    ;; Point stays before the same token.  Emacs 30 puts it before the
    ;; space inserted ahead of the token, Emacs 31 after.
    (should (looking-at-p " ?2\n}"))))

(ert-deftest nickel-ts-format-error ()
  (skip-unless (executable-find nickel-ts-command))
  (nickel-ts-test-with-buffer "|let x = {"
    (should-error (nickel-ts-format-buffer) :type 'user-error)
    (should (equal (buffer-string) "let x = {"))
    (with-current-buffer "*nickel-format-errors*"
      (should (string-match-p "error" (buffer-string))))))

(provide 'nickel-ts-mode-tests)
;;; nickel-ts-mode-tests.el ends here
