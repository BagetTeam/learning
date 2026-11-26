type 'a parser = char list -> (char list * 'a) option

let explode s =
    let rec go i acc =
        if i < 0 then acc
        else go (i-1) (s.[i] :: acc)
    in
    go (String.length s - 1) []

let omap (f: 'a -> 'b) = fun input ->
    match input with
    | None -> None
    | Some x -> Some (f x)

let satisfy (f: char -> bool) : char parser = fun cs ->
    match cs with 
    | c::cs when f c -> Some (cs, c)
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


let string2 s : string parser = 
    let rec go l : unit parser =
        match l with
        | [] -> fun cs -> Some (cs, ())
        | x::xs -> 
            satisfy (fun c -> c = x) |*> 
            fun _ -> go xs |*> 
            fun _ -> fun ys -> Some (ys, ())
        in
    go (explode s) |*> fun _ -> fun ys -> Some (ys, s)

let test_string2 = string2 "i love cate" ['i';' ';'l'; 'o';'v';'e';' ';'c';'a';'t';'s';'t';'o';'o']


let of_value x = fun input -> Some (input, x)

let string2 s : string parser = 
    let rec go l : unit parser =
        match l with
        | [] -> of_value ()
        | x::xs -> 
            satisfy (fun c -> c = x) |*> 
            fun _ -> go xs |*> 
            fun _ -> of_value ()
        in
    go (explode s) |*> fun _ -> of_value s


type 'a stream = {head: 'a; tail: unit -> 'a stream}

let rec unfold (f: 's -> 'a * 's) (state: 's) : 'a stream =
  let (cur, next_state) = f state in
  {
    head=cur;
    tail= fun () -> unfold f next_state
  }


let is_digit : char -> bool = fun x -> match x with '0' .. '9' -> true | _ -> false

let digit : int parser = 
    satisfy (fun d -> is_digit d) |*> 
    fun d -> String.make 1 d |> int_of_string |> of_value

let rec digit_sum = 
    fun input -> (
        match digit input with 
        | None -> Some (input, 0)
        | Some (rest, x) -> (
            digit_sum |*>
            fun sum -> of_value (x + sum)
        ) rest
    ) 
    
let test_digit_sum = digit_sum ['1';'5';'4']