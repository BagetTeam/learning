open Ass10_inference_lib
open Ass10_prelude

(** Part 3: Type Inference *)
let typ_infer_test_helper_tests : ((Context.t * exp) * typ option) list = [
  ((Context.empty, ConstB true), Some Bool)
]

let rec typ_infer (ctx : Context.t) (e : exp) : typ =
  match e with
  | ConstI _ -> Int
  | PrimBop (e1, bop, e2) ->
      let ((t1, t2), t3) = bop_type bop in
      if typ_infer ctx e1 = t1 && typ_infer ctx e2 = t2
      then t3
      else raise TypeInferenceError
  | PrimUop (uop, e') ->
      let (t1, t2) = uop_type uop in
      if typ_infer ctx e' = t1
      then t2
      else raise TypeInferenceError

  | ConstB _ -> Bool
  | If (e', e1, e2) -> raise NotImplemented

  | Comma (e1, e2) -> Pair (typ_infer ctx e1, typ_infer ctx e2)
  | LetComma (x, y, e1, e2) -> raise NotImplemented

  | Fn (x, Some t, e') -> raise NotImplemented
  | Apply (e1, e2) -> raise NotImplemented

  | Rec (f, Some t, e') -> raise NotImplemented

  | Let (x, e1, e2) -> raise NotImplemented
  | Var x ->
      begin
        match Context.lookup ctx x with
        | Some t -> t
        | None -> raise TypeInferenceError
      end

  (** You can ignore these cases for Part 2 *)
  | Fn (_, None, _) -> raise IgnoredInPart3
  | Rec (_, None, _) -> raise IgnoredInPart3

(** DO NOT Change This Definition *)
let typ_infer_test_helper ctx e =
  try
    Some (typ_infer ctx e)
  with
  | TypeInferenceError -> None

(** Part 4: Unification & Advanced Type Inference *)
let unify_test_case1 () =
  let x = new_tvar () in
  let y = new_tvar () in
  y := Some Int;
  (TVar x, TVar y)

let unify_test_case2 () =
  let x = new_tvar () in
  (TVar x, Arrow (TVar x, TVar x))

let unify_test_helper_tests : ((unit -> typ * typ) * bool) list = [
  ((fun () -> (Int, Int)), true);
  ((fun () -> (Int, Bool)), false);
  (unify_test_case1, true);
  (unify_test_case2, false)
]

let rec unify : typ -> typ -> unit =
  let rec occurs_check (x : typ option ref) (t : typ) : bool =
    let t = rec_follow_tvar t in
    match t with
    | Int -> false
    | Bool -> false
    | Pair (t1, t2) -> raise NotImplemented
    | Arrow (t1, t2) -> raise NotImplemented
    | TVar y -> raise NotImplemented
  in
  fun ta tb ->
    let ta = rec_follow_tvar ta in
    let tb = rec_follow_tvar tb in
    match ta, tb with
    | Int, Int -> ()
    | Bool, Bool -> ()
    | Pair (ta1, ta2), Pair (tb1, tb2) -> raise NotImplemented
    | Arrow (ta1, ta2), Arrow (tb1, tb2) -> raise NotImplemented
    | TVar xa, TVar xb when is_same_tvar xa xb -> ()
    | TVar xa, _ -> raise NotImplemented
    | _, TVar xb -> unify tb ta
    | _, _ -> raise UnificationFailure

(** DO NOT Change This Definition *)
let unify_test_helper f =
  let ta, tb = f () in
  try
    unify ta tb; true
  with
  | UnificationFailure -> false
  | OccursCheckFailure -> false

let adv_typ_infer_test_case1 =
  let x = new_tvar () in
  ((Context.empty, Fn ("y", None, Var "y")), Some (Arrow (TVar x, TVar x)))

let adv_typ_infer_test_helper_tests : ((Context.t * exp) * typ option) list = [
  adv_typ_infer_test_case1
]

let rec adv_typ_infer (ctx : Context.t) (e : exp) : typ =
  match e with
  | ConstI n -> raise NotImplemented
  | PrimBop (e1, bop, e2) -> raise NotImplemented
  | PrimUop (uop, e') -> raise NotImplemented

  | ConstB b -> raise NotImplemented
  | If (e', e1, e2) -> raise NotImplemented

  | Comma (e1, e2) -> raise NotImplemented
  | LetComma (x, y, e1, e2) -> raise NotImplemented

  | Fn (x, Some t, e') -> raise NotImplemented
  | Fn (x, None, e') -> raise IgnoredInPart3
  | Apply (e1, e2) -> raise NotImplemented

  | Rec (f, Some t, e') -> raise NotImplemented
  | Rec (f, None, e') -> raise IgnoredInPart3

  | Let (x, e1, e2) -> raise NotImplemented
  | Var x -> raise NotImplemented

(** DO NOT Change This Definition *)
let adv_typ_infer_test_helper ctx e =
  try
    Some (adv_typ_infer ctx e)
  with
  | UnificationFailure -> None
  | OccursCheckFailure -> None
  | TypeInferenceError -> None

(**
 ************************************************************
 You Don't Need to Modify Anything After This Line
 ************************************************************

 Following definitions are the helper entrypoints
 so that you can do some experiments in the top-level.
 Once you implement [typ_infer] you can test it with
 [infer_main] in the top-level.
 Likewise, once you implement [adv_typ_infer] you can
 test it with [adv_infer_main] in the top-level.
 *)
let infer_main exp_str =
  match parse_exp exp_str with
  | None -> raise ParserFailure
  | Some e ->
      print_string "input expression       : "; print_exp e; print_newline ();
      let t = typ_infer Context.empty e in
      print_string "type of the expression : "; print_typ t; print_newline ();
      print_string "evaluation result      : "; print_exp (eval e); print_newline ()

let adv_infer_main exp_str =
  match parse_exp exp_str with
  | None -> raise ParserFailure
  | Some e ->
      print_string "input expression       : "; print_exp e; print_newline ();
      let t = adv_typ_infer Context.empty e in
      print_string "type of the expression : "; print_typ t; print_newline ();
      print_string "evaluation result      : "; print_exp (eval e); print_newline ()
