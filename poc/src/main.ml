
open Lwt
open Cohttp
open Cohttp_lwt_unix

let server =
  (* La réponse du serveur *)
  let callback _conn req body =
    body |> Cohttp_lwt.Body.to_string >|= (fun body ->
      ("SALUT A TOUSSE"))   
    >>= (fun body -> Server.respond_string ~status: `OK ~ body ())
  in
  
  (* Custom URL, doesn't work *)
  let%lwt ctx = Conduit_lwt_unix.init ~src:"launch" () in
  let ctx = Cohttp_lwt_unix.Client.custom_ctx ~ctx () in

  Server.create ~backlog:10 ~ctx ~mode:(`TCP (`Port 8000)) (Server.make ~callback ())

let () = ignore (Lwt_main.run server)
