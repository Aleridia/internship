open Format
open Lwt
open Cohttp
open Cohttp_lwt_unix
open Jwto
open Printf

let passwdD = ref "lapin"
let loginD = ref "pinpix"

exception Fail of string
let my_payload =
  [
    (* LTI launch *)
    ("oauth_consumer_key","Key OAuth");
    ("deployment_id", "1");
    ("client_id", "1");
    ("lti_version","1.3");
    ("lti_message_type","Type msg LTI");
    (* Contexte *)
    ("context_id","1");
    ("context_title","Titre contexte");
    ("context_type","Type contexte");
    ("context_label","Label contexte");
    (* Ressource link *)
    ("id_ressource_link","1");
    ("description_ressource_link","Desc RL");
    ("title_ressource_link","Titre RL");
    (* User *)
    ("user_id","1");
    ("user_given_name","Michel");
    ("user_name","Michel");
    ("user_mail","michel@gmail.com");
    ("user_role","Enseignant");
    (* Plateforme *)
    ("plateform_guid","1");
    ("plateform_contact_email","plt@gmail.com");
    ("plateform_url","Moodle.fr");
    ("plateform_version","1.15.2");
  ]

let my_secret =
  "My$ecretK3y"

(* Lis la valeur dans un sous dossier *)
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


let traiter_token token = match Jwto.decode_and_verify my_secret token with
  | Ok s -> Server.respond_string ~status: `OK ~body: "Token OK" () 
  | Error e -> Server.respond_string ~status: `Not_acceptable ~body: e () 


let server =
  (* La réponse du serveur *)
  let callback _conn req body =
    let uri = Request.uri req in
    match Uri.path uri with (* Match l'URI *)
    |"/launch" ->
      (match req |> Request.meth with (* Type de requête *)
       | `GET -> let login = Uri.get_query_param uri "login" in (* GET *)
                 let psswd = Uri.get_query_param uri "mdp" in
                 (match login,psswd with
                  |Some l,Some p -> if l = !loginD && p = !passwdD then
                                      body |> Cohttp_lwt.Body.to_string >|= (fun body -> lireValeur l) >>= (fun body -> Server.respond_string ~status: `OK ~body ())
                                    else
                                      Server.respond_string ~status: `Not_acceptable ~body:("Invalid login/password") ()
                  |_,_ -> Server.respond_string ~status: `Not_acceptable ~body:"No param" ())
       | `POST -> string_of_stream (Cohttp_lwt.Body.to_stream body) >>= (function  (* POST *)
                  | Some s -> traiter_token s
                  | None -> Server.respond_string ~status: `Bad_request ~body: "Missing POST body" ())
       | _ -> Server.respond_string ~status: `Not_acceptable ~body:"Unsuported request" () ) (* Si ce n'est ni GET ni POST *)
    | "/shutdown" ->  async (fun () -> Lwt_unix.sleep 0.1 >>= fun () -> exit 0); (* Pour shutdown le server *)
                     Server.respond_string ~status:`OK ~body:"shutting down" ()
    | _ -> Server.respond_string ~status: `Not_found ~body:"Error 404" ()  (* Error 404 *)
  in

  Server.create ~backlog:10 ~mode:(`TCP (`Port 8000)) (Server.make ~callback ())


(* Client side *)

let token_test = Jwto.encode Jwto.HS256 my_secret my_payload

let body_token = function
  | Ok v -> Cohttp_lwt__Body.of_string v
  | Error e -> raise (Fail e)

let port = 8000
let address = "127.0.0.1"
let url = Uri.of_string (sprintf "http://%s:%d/launch" address port)
let url_shutdown = Uri.of_string (sprintf "http://%s:%d/shutdown" address port)

let client () = 
  let body = body_token token_test in (* Création du body *)
  Cohttp_lwt_unix.Client.post ~body url >>= fun (resp,body) ->
  Cohttp_lwt__Body.to_string body >>= fun body -> (*Affichage de la réponse*)
  print_string "Body : ";
  print_string body;
  print_string " Status : ";
  print_string @@ Cohttp__.Code.string_of_status @@ Cohttp__Response.status resp;
  print_newline ();
  Client.get url_shutdown >>= fun _ -> return (exit 1) 
 
let () =  match Lwt_unix.fork () with
  | 0 ->
     Unix.sleep 2;
     Printf.eprintf "client is %d\n%!" (Unix.getpid ());
     Lwt_main.run (client ());
  | pid ->
     Printf.eprintf "server is %d\n%!" (Unix.getpid ());
     Lwt_main.run server
