type 'a parser = char list -> (char list * 'a) option

let satisfy (f: char -> bool) : unit parser = fun cs ->
    match cs with 
    | c::cs when f c -> Some (cs, ())
    | _ -> None

let (|*>) (p: 'a parser) (k: 'a -> 'b parser) : 'b parser = fun input ->
    match p input with 
    | Some (cs, c) -> k c cs
    | None -> None


