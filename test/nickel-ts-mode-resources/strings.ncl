[
  "plain \n %{x} end",
# ^ font-lock-string-face
#  ^ font-lock-string-face
#        ^ font-lock-escape-face
#           ^ font-lock-misc-punctuation-face
#             ^ font-lock-variable-use-face
#              ^ font-lock-misc-punctuation-face
#                ^ font-lock-string-face
  m%"say "hi" %{f x}"%,
# ^ font-lock-string-face
#        ^ font-lock-string-face
#               ^ font-lock-function-call-face
#                   ^ font-lock-string-face
]
