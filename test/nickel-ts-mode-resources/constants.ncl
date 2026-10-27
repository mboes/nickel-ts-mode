[
  'Ok, true, null, 0x1F, 1.5e3,
# ^ font-lock-constant-face
#      ^ font-lock-constant-face
#            ^ font-lock-constant-face
#                  ^ font-lock-number-face
#                        ^ font-lock-number-face
  match { 'Some x => x, _ => 0 },
# ^ font-lock-keyword-face
#         ^ font-lock-constant-face
#               ^ font-lock-variable-name-face
#                    ^ font-lock-variable-use-face
  if c then 1 else 2,
# ^ font-lock-keyword-face
#      ^ font-lock-keyword-face
#             ^ font-lock-keyword-face
  match { 'A or 'B => 1, _ => 0 },
#            ^ font-lock-keyword-face
]
