open Ass9_eval_substitution_lib

(** Substitution & Evaluation *)
let free_vars_test_helper_tests : (exp * ident list) list = [
  (ConstI 5, []);
  (Var "x", ["x"])
]

let rec free_vars (e : exp) : IdentSet.t =
  match e with
  | ConstI _ -> IdentSet.empty
  | PrimBop (e1, _, e2) -> IdentSet.union (free_vars e1) (free_vars e2)
  | PrimUop (_, e') -> free_vars e'

  | ConstB _ -> IdentSet.empty

  (* if e' e1 e2,   e' -> bool, e1 = e2 *)
  | If (e', e1, e2) -> IdentSet.union (free_vars e') 
                        (IdentSet.union (free_vars e1) (free_vars e2))
  | Comma (e1, e2) -> IdentSet.union (free_vars e1) (free_vars e2)

  (* let (x, y) = e1 in e2 *)
  | LetComma (x, y, e1, e2) -> IdentSet.union (free_vars e1)
                                (IdentSet.remove x (IdentSet.remove y (free_vars e2))) 
  (* fn x -> e' *)
  | Fn (x, tOpt, e') -> IdentSet.remove x (free_vars e')
  (* e1 e2 *)
  | Apply (e1, e2) -> IdentSet.union (free_vars e1) (free_vars e2)

  (* let rec f = e'  (where f might appear in e') *)
  | Rec (f, tOpt, e') -> IdentSet.remove f (free_vars e')
  (* let x = e1 in e2 *)
  | Let (x, e1, e2) -> IdentSet.union (free_vars e1)
                        (IdentSet.remove x (free_vars e2))
  | Var x -> IdentSet.singleton x

(** DO NOT Change This Definition *)
let free_vars_test_helper e = IdentSet.elements (free_vars e)

let subst_tests : (((exp * ident) * exp) * exp) list = [
  (((ConstI 5, "x"), PrimBop (ConstI 2, Plus, Var "x")), PrimBop (ConstI 2, Plus, ConstI 5))
]

let rec subst ((d, z) : exp * ident) (e : exp) : exp =
  (** [rename (x, e)] replace [x] appears in [e] with a fresh identifier
      and returns the fresh identifier and updated expression *)
  let rename ((x, e) : ident * exp) : ident * exp =
    let x' = fresh_ident x in
    (x', subst (Var x', x) e)
  in
  match e with
  | ConstI _ -> e
  | PrimBop (e1, bop, e2) -> PrimBop (subst (d, z) e1, bop, subst (d, z) e2)
  | PrimUop (uop, e') -> PrimUop (uop, subst (d, z) e')

  | ConstB _ -> e
  | If (e', e1, e2) -> raise NotImplemented

  | Comma (e1, e2) -> Comma (subst (d, z) e1, subst (d, z) e2)
  | LetComma (x, y, e1, e2) -> raise NotImplemented

  | Fn (x, tOpt, e') -> raise NotImplemented
  | Apply (e1, e2) -> raise NotImplemented

  | Rec (f, tOpt, e') -> raise NotImplemented

  | Let (x, e1, e2) -> raise NotImplemented
  | Var x ->
      if x = z
      then d
      else e

let eval_test_helper_tests : (exp * exp option) list = [
  (Var "x", None);
  (ConstI 5, Some (ConstI 5));
  (PrimBop (ConstI 5, Minus, ConstI 5), Some (ConstI 0))
]

let rec eval (e : exp) : exp =
  match e with
  | ConstI _ -> e
  | PrimBop (e1, bop, e2) ->
      begin
        match eval e1, eval e2 with
        | ConstI n1, ConstI n2 ->
            begin
              match bop with
              | Equals -> ConstB (n1 = n2)
              | LessThan -> ConstB (n1 < n2)
              | Plus -> ConstI (n1 + n2)
              | Minus -> ConstI (n1 - n2)
              | Times -> ConstI (n1 * n2)
            end
        | _ -> raise EvaluationStuck
      end
  | PrimUop (_, e) ->
      begin
        match eval e with
        | ConstI n -> ConstI (- n)
        | _ -> raise EvaluationStuck
      end

  | ConstB _ -> e
  | If (e', e1, e2) -> raise NotImplemented

  | Comma (e1, e2) -> Comma (eval e1, eval e2)
  | LetComma (x, y, e1, e2) -> raise NotImplemented

  | Fn (x, tOpt, e') -> raise NotImplemented
  | Apply (e1, e2) -> raise NotImplemented

  | Rec (f, tOpt, e') -> raise NotImplemented

  | Let (x, e1, e2) -> raise NotImplemented
  | Var _ -> raise EvaluationStuck

(** DO NOT Change This Definition *)
let eval_test_helper e =
  try
    Some (eval e)
  with
  | EvaluationStuck -> None
