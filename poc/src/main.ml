
open Lwt
open Cohttp
open Cohttp_lwt_unix

let tmp = ref "Oui"
let passwdD = ref "lapin"
let loginD = ref "pinpix"

let payload =
  [
    ("user", "sam");
    ("age", "17");
  ]

(*let signe = Jwto.make Jwto.HS256 "secret" payload*)





let lireValeur login = 
  let nomF = String.concat "." [login;"txt"] in
  let ic = open_in (String.concat "/" ["usr";nomF]) in
  try
    let line = input_line ic in
    flush stdout;
    close_in ic;
    line
  with e ->
    close_in_noerr ic;
    raise e

exception Too_long_body

let string_of_stream ?(max_size = 1024 * 1024) s =
  let b = Buffer.create (64 * 1024) in
  let pos = ref 0 in
  let add_string s =
    pos := !pos + String.length s;
    if !pos > max_size then
      Lwt.fail Too_long_body
    else begin
      Buffer.add_string b s;
      Lwt.return_unit
    end
  in
  Lwt.catch begin function () ->
    Lwt_stream.iter_s add_string s >>= fun () ->
    Lwt.return (Some (Buffer.contents b))
  end begin function
    | Too_long_body -> Lwt.return None
    | e -> Lwt.fail e
  end

let server =
  (* La réponse du serveur *)
  let callback _conn req body =
    let uri = Request.uri req in
    match Uri.path uri with (* Match l'URI *)
    |"/launch" ->
      (match req |> Request.meth with (* Type de requête *)
       | `GET -> let login = Uri.get_query_param uri "login" in
                 let psswd = Uri.get_query_param uri "mdp" in
                 (match login,psswd with
                  |Some l,Some p -> if l = !loginD && p = !passwdD then
                                      body |> Cohttp_lwt.Body.to_string >|= (fun body -> lireValeur l) >>= (fun body -> Server.respond_string ~status: `OK ~body ())
                                    else
                                      Server.respond_string ~status: `Not_acceptable ~body:"Wrong login/passwd" ()
                  |_,_ -> Server.respond_string ~status: `Not_acceptable ~body:"No param" ())
       | `POST -> string_of_stream (Cohttp_lwt.Body.to_stream body) >>= (function
                  | Some s -> Server.respond_string ~status: `OK ~body: s ()
                  | None -> Server.respond_string ~status: `Bad_request ~body: "Missing POST body" ())
       | _ -> Server.respond_string ~status: `Not_acceptable ~body:"Unsuported request" () )
    |_ -> Server.respond_string ~status: `Not_found ~body:"Route not found" ()
  in
  
  (* Custom URL, doesn't work *)
  let%lwt ctx = Conduit_lwt_unix.init ~src:"127.0.0.1" () in
  let ctx = Cohttp_lwt_unix.Client.custom_ctx ~ctx () in
  
  Server.create ~backlog:10 ~ctx ~mode:(`TCP (`Port 8000)) (Server.make ~callback ())

let () = ignore (Lwt_main.run server)
