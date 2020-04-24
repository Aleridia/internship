open Format
open Lwt
open Cohttp
open Cohttp_lwt_unix
open Jwto
open Printf


let passwdD = ref "lapin"
let loginD = ref "pinpix"
let clientId = ref "SDF7ASDLSFDS9"

(* Rq = required; Re = recommended *)
exception Fail of string
let my_payload =
  [
    (* LTI launch *)
    ("oauth_consumer_key","Key OAuth");
    ("deployment_id", "1");                     (* Rq *)
    ("client_id", "1");                         (* Rq *)
    ("lti_version","1.3");                      (* Rq *)
    ("lti_message_type","Type msg LTI");        (* Rq *)
    ("lti_deployment_id","Pareil que le deployment_id"); 
    (* Contexte *)
    ("context_id","1");                                     (* Re *)
    ("context_title","Titre contexte");                     (* Re *)
    ("context_type","Type contexte");
    ("context_label","Label contexte");                     (* Re *)
    (* Ressource link *)
    ("ressource_link_id","1");                   (* Rq *)
    ("ressource_link_description","Desc RL");                (* Re *)
    ("ressource_link_title","Titre RL");
    (* User *)
    ("user_id","1");                                         (* Re *)
    ("lis_person_name_family","Lehcim");                     (* Re *)
    ("lis_person_name_given","Michel");                      (* Re *)
    ("lis_person_name_full","Michel");                       (* Re *)
    ("role","enseignant");                                   (* Re *)
    ("lis_person_contact_email_primary","michel@gmail.com"); (* Re *)
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

let contains s1 s2 =
    let re = Str.regexp_string s2
    in
        try ignore (Str.search_forward re s1 0); true
        with Not_found -> false

let traiter_token token = match Jwto.decode_and_verify my_secret token with
  | Ok s -> Server.respond_string ~status: `OK ~body: (Jwto.show_payload @@ Jwto.get_payload s) () 
  | Error e -> Server.respond_string ~status: `OK ~body: "Moodle t naze" ()


(* Extrait les arguments POST voulu dans l'ordre donné *)
let extract_args nom_args post = let liste_a_trier = String.split_on_char '&' post in
                                 (* Va ajouter dans liste_ret la cellule de liste_a_trier qui contient le terme recherché *)
                                 let rec trier_arg terme liste_a_trier =
                                   match liste_a_trier with
                                   | s::l -> if contains s terme then s
                                             else trier_arg terme l
                                   | _ -> ""
                                 in
                                               
                                 (* Retourne une liste triée dans l'ordre donné de liste_nom *)
                                 let rec liste_return liste_nom liste_a_trier =
                                   match liste_nom with
                                   | s :: l -> (trier_arg s liste_a_trier) :: liste_return l liste_a_trier
                                   | [] -> []
                                 in
                                 (*liste_return liste_a_trier @@ List.rev nom_args*)
                                 liste_return nom_args liste_a_trier
                                 

(* Puis pour chaque elem de la liste, prendre la première occurence du = et retourner le string du rang de = à la fin su string *)
let traiter_requete req = let tri = String.concat "" @@ extract_args ["iss";"login_hint";"target_link_uri";"lti_message_hint"] req in
                          if String.compare tri "" = 0 then   (* Ne pas oublier de changer le <> *)                      
                            Server.respond_string ~status: `OK ~body: req ()
                          else
                          let scope = "openid" in
                          let response_type = "id_token" in
                          let client_id = "yttrtfgrt" in
                          let state = "KnIINhyGGYYPezfrz" in (* Faire la fonction *)
                          let response_mode = "form_post" in
                          let nonce = "fdshuHBBjgVGVgvGVBGggVGHVgV" in (* Faire la fonction *)
                          let prompt = "none" in
                          let body = sprintf "scope=%s&response_type=%s&client_id=%s&redirect_url=http://localhost:8000/shutdown&login_hint=2&state=%s&response_mode=%s&nonce=%s&prompt=%s&lti_message_hint=3" scope response_type client_id state response_mode nonce prompt in
                          let headers = Cohttp.Header.init_with "content-type" "application/x-www-form-urlencoded" in
                          Server.respond_string ~headers ~status: `OK ~body ()
                             
let server =
  (* La réponse du serveur *)
  let callback _conn req body =
    let uri = Request.uri req in
    match Uri.path uri with (* Match l'URI *)
    |"/launch" ->
      (match req |> Request.meth with (* Type de requête *)
       | `GET -> async (fun () -> Lwt_unix.sleep 0.1 >>= fun () -> exit 0); (* TODO : Faire en sorte que la requête LTI puisse passer par un get *)
                 Server.respond_string ~status:`OK ~body:"shutting down" ()
       
       | `POST -> (match Request.has_body req with (* POST *)
                  |`Yes -> body |> Cohttp_lwt.Body.to_string >>= traiter_requete
                  | `No -> Server.respond_string ~status: `Bad_request ~body: "Missing POST body" ()
                  | _ -> Server.respond_string ~status: `Bad_request ~body: "Unknown POST body" ())
       | _ -> Server.respond_string ~status: `Not_acceptable ~body:"Unsuported request" () ) (* Si ce n'est ni GET ni POST *)

    | "/shutdown" ->  async (fun () -> Lwt_unix.sleep 0.1 >>= fun () -> exit 0); (* Pour shutdown le server *)
                      Server.respond_string ~status:`OK ~body:"shutting down" ()

    | "/get" -> let login = Uri.get_query_param uri "login" in (* Tester les requêtes GET *)
                 let psswd = Uri.get_query_param uri "mdp" in
                 (match login,psswd with
                  |Some l,Some p -> if l = !loginD && p = !passwdD then
                                      body |> Cohttp_lwt.Body.to_string >|= (fun body -> lireValeur l) >>= (fun body -> Server.respond_string ~status: `OK ~body ())
                                    else
                                      Server.respond_string ~status: `Not_acceptable ~body:("Invalid login/password") ()
                  |_,_ -> Server.respond_string ~status: `Not_acceptable ~body:"No param" ())

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
  return (exit 1)
  
let () =  match Lwt_unix.fork () with
  | 0 ->
     Unix.sleep 2;
     Printf.eprintf "client is %d\n%!" (Unix.getpid ());
     Lwt_main.run (client ())
  | pid ->
     Printf.eprintf "server is %d\n%!" (Unix.getpid ());
     Lwt_main.run server
