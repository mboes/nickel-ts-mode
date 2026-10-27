let or = 1 in
#   ^ font-lock-variable-name-face
let rec x = 1 in
# <- font-lock-keyword-face
#   ^ font-lock-keyword-face
#       ^ font-lock-variable-name-face
#         ^ font-lock-operator-face
#             ^ font-lock-keyword-face
let { a, b ? 2 } = r in
#     ^ font-lock-variable-name-face
#        ^ font-lock-variable-name-face
#          ^ font-lock-operator-face
#                  ^ font-lock-variable-use-face
{ server.port = 80, "quoted" = 1 }
# <- font-lock-bracket-face
# ^ font-lock-property-name-face
#       ^ font-lock-delimiter-face
#        ^ font-lock-property-name-face
#                 ^ font-lock-delimiter-face
#                   ^ font-lock-string-face
