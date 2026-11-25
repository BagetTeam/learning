type 'a stream = {head: 'a; tail: unit -> 'a stream}

let rec unfold (f: 's -> 'a * 's) (state: 's) : 'a stream =
  let (cur, next_state) = f state in
  {
    head=cur;
    tail= fun () -> unfold f next_state
  }