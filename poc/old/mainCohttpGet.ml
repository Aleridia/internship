
open Lwt
open Cohttp
open Cohttp_lwt_unix

let tmp = ref "Oui"
let passwdD = ref "lapin"
let loginD = ref "pinpix"

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

let server =
  (* La réponse du serveur *)
  let callback _conn req body =
    let uri = Request.uri req in
    match Uri.path uri with
    |"/launch" -> let login = Uri.get_query_param uri "login" in
                  let psswd = Uri.get_query_param uri "pass" in
                  (match login,psswd with
                   |Some l,Some p -> if l = !loginD && p = !passwdD then
                                       body |> Cohttp_lwt.Body.to_string >|= (fun body -> lireValeur l) >>= (fun body -> Server.respond_string ~status: `OK ~body ())
                                     else
                                       Server.respond_string ~status: `Not_acceptable ~body:"Wrong login/passwd" ()
                  |_,_ -> Server.respond_string ~status: `Not_acceptable ~body:"No param" ())
    |_ -> Server.respond_string ~status: `Not_found ~body:"Route not found" ()
  in

  (* Custom URL, doesn't work *)
  let%lwt ctx = Conduit_lwt_unix.init ~src:"127.0.0.1" () in
  let ctx = Cohttp_lwt_unix.Client.custom_ctx ~ctx () in

  Server.create ~backlog:10 ~ctx ~mode:(`TCP (`Port 8000)) (Server.make ~callback ())

let () = ignore (Lwt_main.run server)
