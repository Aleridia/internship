open Lwt

let counter = ref 0
let listen_address = Unix.inet_addr_loopback
let port = 8080
let backlog = 10

let traiter_message msg =
  match msg with
  | "read" -> string_of_int !counter
  | "inc" -> counter := !counter + 1; "Cpt incr"
  | _ -> "Unknown command"

let rec maintenir_co ic oc () =
  Lwt_io.read_line_opt ic >>=
    (fun msg ->
      match msg with
      | Some msg ->
         let reply = traiter_message msg in
         Lwt_io.write_line oc reply >>= maintenir_co ic oc
      | None -> Logs_lwt.info (fun m -> m "Connection closed") >>= return)
