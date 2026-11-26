(* Local stand-ins for definitions the course's hidden prelude provides.
   Only here so ass10_inference.ml compiles locally; don't submit this. *)
open Ass10_inference_lib

let parse_exp (_ : string) : exp option = raise NotImplemented
let eval (_ : exp) : exp = raise NotImplemented
