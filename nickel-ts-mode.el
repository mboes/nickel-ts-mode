;;; nickel-ts-mode.el --- Major mode for Nickel using tree-sitter -*- lexical-binding: t; -*-

;; Copyright © 2025-2026 Mathieu Boespflug

;; Author: Mathieu Boespflug <m@boespfl.ug>
;; Assisted-by: Claude:claude-opus-5-5
;; URL: https://github.com/mboes/nickel-ts-mode
;; Version: 0.1.0
;; Keywords: languages nickel tree-sitter
;; Homepage: https://nickel-lang.org/
;; Package-Requires: ((emacs "29.1"))

;; This file is not part of GNU Emacs.

;;; Commentary:

;; A major mode for the Nickel configuration language, leveraging
;; Tree-sitter.  It provides:
;;
;; - Syntax highlighting according to the tree-sitter-nickel grammar
;; - Navigation between let bindings, record fields and array elements
;; - Formatting with `nickel format', bound to C-c C-f.
;;
;; Install the grammar once with M-x treesit-install-language-grammar RET
;; nickel RET.

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

(require 'treesit)
;; Defines `replace-region-contents' before Emacs 31.
(require 'subr-x)
(eval-when-compile (require 'rx))

(defgroup nickel-ts nil
  "Major mode for Nickel, using Tree-sitter."
  :group 'languages
  :prefix "nickel-ts-"
  :link '(url-link :tag "GitHub" "https://github.com/mboes/nickel-ts-mode")
  :link '(emacs-commentary-link :tag "Commentary" "nickel-ts-mode"))

(defcustom nickel-ts-command "nickel"
  "The Nickel executable, used for formatting."
  :type 'string)

(add-to-list 'treesit-language-source-alist
             '(nickel "https://github.com/nickel-lang/tree-sitter-nickel"))

(defvar nickel-ts-mode--syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?\n ">" table)
    (modify-syntax-entry ?\" "\"" table)
    (modify-syntax-entry ?\\ "\\" table)
    ;; Identifiers may contain these characters, as in `foo-bar'.
    (modify-syntax-entry ?_ "_" table)
    (modify-syntax-entry ?- "_" table)
    (modify-syntax-entry ?' "_" table)
    table)
  "Syntax table for `nickel-ts-mode'.")

;;; Font lock

(defvar nickel-ts-mode--keywords
  '("let" "in" "rec" "fun" "if" "then" "else" "match" "forall" "import"
    "include" "or" "default" "doc" "force" "optional" "priority"
    "not_exported")
  "Nickel keywords, as tokens of the tree-sitter grammar.")

(defvar nickel-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :language 'nickel
   :feature 'comment
   '((comment) @font-lock-comment-face)

   :language 'nickel
   :feature 'string
   '([(str_start) (str_end) (multstr_start) (multstr_end)
      (chunk_literal_single) (chunk_literal_multi)]
     @font-lock-string-face)

   :language 'nickel
   :feature 'escape
   :override t
   '((str_esc_char) @font-lock-escape-face
     [(interpolation_start) (interpolation_end)]
     @font-lock-misc-punctuation-face)

   :language 'nickel
   :feature 'keyword
   `([,@nickel-ts-mode--keywords] @font-lock-keyword-face)

   :language 'nickel
   :feature 'constant
   :override t
   '((enum_tag) @font-lock-constant-face
     [(bool) "null"] @font-lock-constant-face)

   :language 'nickel
   :feature 'number
   '([(num_literal) (signed_num_literal)] @font-lock-number-face)

   :language 'nickel
   :feature 'builtin
   '((builtin) @font-lock-builtin-face
     ((ident) @font-lock-builtin-face
      (:equal "std" @font-lock-builtin-face)))

   :language 'nickel
   :feature 'definition
   '((pattern (ident) @font-lock-variable-name-face)
     (pattern_fun (ident) @font-lock-variable-name-face)
     (field_pattern id: (ident) @font-lock-variable-name-face)
     (forall ids: (ident) @font-lock-variable-name-face)
     (field_def
      path: (field_path
             (field_path_elem (ident) @font-lock-property-name-face))))

   :language 'nickel
   :feature 'function
   '((applicative
      t1: (applicative
           :anchor (record_operand
                    (atom (ident) @font-lock-function-call-face))))
     (applicative
      t1: (applicative
           :anchor (record_operand
                    (record_operation_chain
                     id: (ident) @font-lock-function-call-face))))
     (infix_expr
      op: (infix_b_op_6 "|>")
      t2: (infix_expr
           (applicative
            :anchor (record_operand
                     [(atom (ident) @font-lock-function-call-face)
                      (record_operation_chain
                       id: (ident) @font-lock-function-call-face)])))))

   :language 'nickel
   :feature 'property
   '((record_operation_chain id: (ident) @font-lock-property-use-face))

   :language 'nickel
   :feature 'type
   :override 'keep
   '([(type_builtin) "Array"] @font-lock-type-face
     (types) @font-lock-type-face)

   :language 'nickel
   :feature 'variable
   '((atom (ident) @font-lock-variable-use-face))

   :language 'nickel
   :feature 'operator
   '((infix_expr op: _ @font-lock-operator-face)
     ["=" "=>" "@" "?" ".."] @font-lock-operator-face)

   :language 'nickel
   :feature 'bracket
   '(["(" ")" "[" "]" "{" "}" "[|" "|]"] @font-lock-bracket-face)

   :language 'nickel
   :feature 'delimiter
   '(["," ";" "." ":" "|"] @font-lock-delimiter-face)

   :language 'nickel
   :feature 'error
   :override t
   '((ERROR) @font-lock-warning-face))
  "Tree-sitter font-lock settings for `nickel-ts-mode'.")

;;; Navigation

(defvar nickel-ts-mode--defun-regexp
  (rx bos (or "let_binding" "field_def") eos)
  "Nodes that `beginning-of-defun' and `end-of-defun' move between.")

(defun nickel-ts-mode--defun-name (node)
  "Return the name of NODE, a let binding or record field."
  (pcase (treesit-node-type node)
    ("let_binding"
     (treesit-node-text (treesit-node-child-by-field-name node "pat") t))
    ("field_def"
     (treesit-node-text (treesit-node-child-by-field-name node "path") t))))

(defun nickel-ts-mode--defun-skipper ()
  "Skip the separator after a record field or let binding, then whitespace."
  (when (looking-at (rx (* blank) (or "," (seq "in" symbol-end))))
    (goto-char (match-end 0)))
  (treesit-default-defun-skipper))

(defun nickel-ts-mode--list-p (node)
  "Return non-nil if NODE is delimited, like a record, array or string.
Arrays and parenthesized terms have no node type of their own, so
look at the first child."
  (or (member (treesit-node-type node) '("str_chunks" "static_string"))
      (member (treesit-node-type (treesit-node-child node 0))
              '("{" "[" "(" "[|"))))

;;; Formatting

(defun nickel-ts-format-buffer ()
  "Format the current buffer with `nickel format'.
On a parse error, leave the buffer unchanged and show the error."
  (interactive)
  (let ((output (generate-new-buffer " *nickel-format*"))
        (errors (make-temp-file "nickel-format")))
    (unwind-protect
        (if (zerop (save-restriction
                     (widen)
                     (call-process-region (point-min) (point-max)
                                          nickel-ts-command nil
                                          (list output errors) nil
                                          "format" "--color" "never")))
            (progn
              (save-restriction
                (widen)
                ;; Unlike erasing and reinserting, these preserve point
                ;; and markers.
                (if (>= emacs-major-version 31)
                    (replace-region-contents (point-min) (point-max) output)
                  (with-no-warnings (replace-buffer-contents output))))
              (message "Formatted buffer"))
          (with-current-buffer (get-buffer-create "*nickel-format-errors*")
            (let ((inhibit-read-only t))
              (erase-buffer)
              (insert-file-contents errors)
              (special-mode))
            (display-buffer (current-buffer)))
          (user-error "Formatting failed"))
      (kill-buffer output)
      (delete-file errors))))

;;; Mode

(defvar-keymap nickel-ts-mode-map
  :doc "Keymap for `nickel-ts-mode'."
  "C-c C-f" #'nickel-ts-format-buffer)

;;;###autoload
(define-derived-mode nickel-ts-mode prog-mode "Nickel"
  "Major mode for editing Nickel, using tree-sitter.

\\{nickel-ts-mode-map}"
  :syntax-table nickel-ts-mode--syntax-table
  (when (treesit-ready-p 'nickel)
    (treesit-parser-create 'nickel)

    (setq-local comment-start "# ")
    (setq-local comment-start-skip "#+[ \t]*")
    (setq-local comment-end "")

    (setq-local treesit-font-lock-settings nickel-ts-mode--font-lock-settings)
    (setq-local treesit-font-lock-feature-list
                '((comment definition)
                  (keyword string type)
                  (builtin constant escape number)
                  (bracket delimiter error function operator property
                           variable)))

    (setq-local treesit-defun-type-regexp nickel-ts-mode--defun-regexp)
    (setq-local treesit-defun-name-function #'nickel-ts-mode--defun-name)
    (setq-local treesit-defun-skipper #'nickel-ts-mode--defun-skipper)
    (setq-local treesit-simple-imenu-settings
                `(("Binding" ,(rx bos "let_binding" eos) nil nil)
                  ("Field" ,(rx bos "field_def" eos) nil nil)))
    ;; Headings must start their line, so use the whole `let' block
    ;; rather than the binding.
    (setq-local treesit-outline-predicate
                (rx bos (or "let_in_block" "field_def") eos))
    ;; Emacs 31 and later use this for `forward-sexp', `up-list' and
    ;; related commands, `show-paren-mode' and `hs-minor-mode'.
    (setq-local treesit-thing-settings
                `((nickel (list ,#'nickel-ts-mode--list-p))))

    (treesit-major-mode-setup)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.ncl\\'" . nickel-ts-mode))

(provide 'nickel-ts-mode)

;;; nickel-ts-mode.el ends here
