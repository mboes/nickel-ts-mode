{
  x | Array String | doc "d" | default = [],
#   ^ font-lock-delimiter-face
#     ^ font-lock-type-face
#           ^ font-lock-type-face
#                    ^ font-lock-keyword-face
#                              ^ font-lock-keyword-face
#                                        ^ font-lock-bracket-face
  id : forall a. a -> a = fun x => x,
#      ^ font-lock-keyword-face
#             ^ font-lock-variable-name-face
#                ^ font-lock-type-face
#                  ^ font-lock-type-face
  p | Port = 80,
#     ^ font-lock-type-face
  r | forall r. { x : Number; r } = { x = 1 },
#                           ^ font-lock-type-face
}
