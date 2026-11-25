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
      (symbol "(" |>>                     (* Remove `(` and call tree_parser *)
        tree_parser |*>
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
    raise NotImplemented
  in
  let power_exp_parser =
    raise NotImplemented
  in
  let multiplicative_exp_parser =
    raise NotImplemented
  in
  let arith_exp_parser_impl =
    raise NotImplemented
  in
  arith_exp_parser_impl i

(** DO NOT Change This Definition *)
let parse_arith : string -> arith option =
  let open Parser in
  run (between spaces eof arith_parser)
