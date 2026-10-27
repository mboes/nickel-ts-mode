[
  fun p1 p2 f => p1 f && p2 f,
# ^ font-lock-keyword-face
#     ^ font-lock-variable-name-face
#           ^ font-lock-variable-name-face
#             ^ font-lock-operator-face
#                ^ font-lock-function-call-face
#                   ^ font-lock-variable-use-face
#                     ^ font-lock-operator-face
#                        ^ font-lock-function-call-face
  std.string.join ", " xs,
# ^ font-lock-builtin-face
#     ^ font-lock-property-use-face
#            ^ font-lock-function-call-face
#                      ^ font-lock-variable-use-face
  xs |> std.array.map f,
#    ^ font-lock-operator-face
#                 ^ font-lock-function-call-face
  %typeof% x,
# ^ font-lock-builtin-face
  { a = 1 } & { b = 2 },
#           ^ font-lock-operator-face
]
