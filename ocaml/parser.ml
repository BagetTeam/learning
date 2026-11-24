type 'a parser = char list -> (char list * 'a) option

let explode s =
    let rec go i acc =
        if i <= 0 then acc
        else go (i-1) (s.[i] :: acc)
    in
    go (String.length s) []

let omap (f: 'a -> 'b) = fun input ->
    match input with
    | None -> None
    | Some x -> Some (f x)

let satisfy (f: char -> bool) : unit parser = fun cs ->
    match cs with 
    | c::cs when f c -> Some (cs, ())
    | _ -> None

let (|*>) (p: 'a parser) (k: 'a -> 'b parser) : 'b parser = fun input ->
    match p input with 
    | Some (cs, c) -> k c cs
    | None -> None


let string1 s = 
  let rec go l = fun input ->
    match l with 
    | [] -> Some (input, ())
    | x::xs ->
        match satisfy (fun c -> c = x) input with 
        | None -> None
        | Some (rest, _) -> go xs rest
  in
  fun cs -> go (explode s) cs |> omap (fun (rest, _) -> (rest, s))
              
let test_string1 = string1 "i love cats" ['i';' ';'l'; 'o';'v';'e';' ';'c';'a';'t';'s';'t';'o';'o']
