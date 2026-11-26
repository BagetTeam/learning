open Ass8_parser_lib

(** Exercise 1: Parse a Tree *)
let parse_tree_tests : (string * tree option) list = [
  ("", None);
  ("((. < 5 > .) < 4 > .)", Some (Node (Node (Leaf, 5, Leaf), 4, Leaf)))
]

let rec tree_parser i =
  let open Parser in
  let tree_parser_impl : tree Parser.t =
    first_of_2
      (const_map Leaf (symbol "."))
      (
        symbol "(" |>>
        tree_parser |*> fun l ->
        symbol "<" |>> 
        int_digits |*> fun v ->
        symbol ">" |>>
        tree_parser |*> fun r ->
        symbol ")" |>> of_value (Node (l, v, r))
      )
  in
  tree_parser_impl i

(** DO NOT Change This Definition *)
let parse_tree : string -> tree option =
  let open Parser in
  run (between spaces eof tree_parser)

(** Part 1: Parse an Arithmetic Expression *)
let parse_arith_tests : (string * arith option) list = [
  ("", None);
  ("5 + 4", Some (Bop (Const 5, Plus, Const 4)))
]

let rec arith_parser i =
  let open Parser in
  let atomic_exp_parser =
    (** You may need to use [arith_parser] here *)
    first_of_2 (int_digits |*> fun result -> of_value (Const result)) (
      symbol "(" |>> 
      arith_parser |*> fun result ->
      symbol ")" |>> of_value result
    )
  in
  let power_exp_parser =
    first_of_2 (
      right_assoc_op (symbol "^") (atomic_exp_parser) 
      (fun res1 op res2 -> Bop (res1, Power, res2))
    ) atomic_exp_parser
  in
  let multiplicative_exp_parser =
    first_of_2 (
      left_assoc_op (symbol "*") (power_exp_parser) 
      (fun res1 op res2 -> Bop (res1, Times, res2))
    ) power_exp_parser
  in
  let arith_exp_parser_impl =
    left_assoc_op (first_of_2 (const_map Plus (symbol "+")) (const_map Minus (symbol "-"))) multiplicative_exp_parser
    (fun res1 op res2 -> Bop (res1, op, res2))
  in
  arith_exp_parser_impl i

(** DO NOT Change This Definition *)
let parse_arith : string -> arith option =
  let open Parser in
  run (between spaces eof arith_parser)
