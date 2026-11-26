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
  | If (e', e1, e2) -> If (subst (d, z) e', subst (d, z) e1, subst (d, z) e2)

  | Comma (e1, e2) -> Comma (subst (d, z) e1, subst (d, z) e2)
  | LetComma (x, y, e1, e2) -> 
    let (x', e2') = rename (x, e2) in
    let (y', e2') = rename (y, e2') in  
    LetComma(x', y', subst (d, z) e1, subst (d, z) e2')

  | Fn (x, tOpt, e') -> (
    let (x', e'') = rename (x, e') in
    Fn (x', tOpt, subst (d, z) e'')
  )
  | Apply (e1, e2) -> Apply (subst (d, z) e1, subst (d, z) e2)

  | Rec (f, tOpt, e') -> 
    let (f', e') = rename (f, e') in
    Rec (f', tOpt, subst (d, z) e')

  | Let (x, e1, e2) -> let (x', e2') = rename (x, e2) in 
      Let (x', subst (d, z) e1, subst (d, z) e2')
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
  | If (e', e1, e2) -> 
      begin
        match eval e' with
        | ConstB b -> 
          if b then
            eval e1
          else eval e2
        | _ -> raise EvaluationStuck
      end

  | Comma (e1, e2) -> Comma (eval e1, eval e2)
  | LetComma (x, y, e1, e2) -> 
      begin
        match eval e1 with 
        | Comma (a, b) -> eval (subst (a, x) (subst (b, y) e2))
        | _ -> raise EvaluationStuck
      end

  | Fn (x, tOpt, e') -> e
  | Apply (e1, e2) -> 
      begin
        match eval e1 with 
        | Fn (x, tOpt, e1') -> eval (subst (eval e2, x) e1')   (* x = e2 *)
        | _ -> raise EvaluationStuck
      end 

  | Rec (f, tOpt, e') -> 
        eval (subst (Rec (f, tOpt, e'), f) e')     (*. f = (e' =  f ...) *)
  | Let (x, e1, e2) -> eval (subst (eval e1, x) e2)
  | Var _ -> raise EvaluationStuck

(** DO NOT Change This Definition *)
let eval_test_helper e =
  try
    Some (eval e)
  with
  | EvaluationStuck -> None




  (*
  Rec (
    "fact", None, Fn (
      "n", None, Apply (Var "fact", n - 1)
    )
  )
    
  Rec (
    "fact", None, Fn (
      "n", None, Apply (
        Rec (
          "fact", None, Fn (
            "n", None, Apply (Var "fact", n - 1)     and so on
          )
        ), n - 1)     we apply n-1 to subRec
    )
  )
  
  *)