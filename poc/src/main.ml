open Lwt
open Cohttp
open Cohttp_lwt_unix
open Printf
open GapiOAuth1

(*************************** Variables ******************)

let passwdD = ref "lapin"
let loginD = ref "pinpix"
let my_secret = "secret"
let url = "http://localhost:8000/launch"
let oauth_timestamp = ref "tmp"
let oauth_nonce = ref "tmp"
let oauth_signature_method = ref "HMAC-SHA1"
let oauth_signature = ref "tmp"
let oauth_consumer_key = ref "tmp"
let oauth_version = ref "tmp"
let oauth_callback = ref "tmp"

(********************* Fonctions annexes de traitement ***************************)


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


(*************************   Traitement POST ****************************)

let contains s1 s2 =
    let re = Str.regexp_string s2
    in
        try ignore (Str.search_forward re s1 0); true
        with Not_found -> false

 (* Renvoie le terme recherché dans la liste*)
let rec trouver_arg terme =
  function
  | s::l -> if contains s terme then s
            else trouver_arg terme l
  | _ -> "Error"

(* Renvoie le terme recherché dans la liste mais décodé (Encodage en HTTP) *)
let trouver_et_decoder terme liste =  Uri.pct_decode @@ trouver_arg terme liste

(* Extrait les arguments POST voulu dans l'ordre donné *)
let trier_args nom_args post =
  let liste_a_trier = String.split_on_char '&' post in
  
  (* Retourne une liste triée dans l'ordre donné de liste_nom *)
  let rec liste_return liste_nom liste_args =
    match liste_nom with
    | s :: l -> (trouver_arg s liste_args) :: liste_return l liste_args
    | [] -> []
  in
  (*liste_return liste_a_trier @@ List.rev nom_args*)
  liste_return nom_args liste_a_trier


(* Extrait le body d'un string : arg=body *)
exception Not_found
let extraire arg =
  let index =
    match String.index_opt arg '=' with
    | Some x -> x + 1
    | None -> raise Not_found
  in 
  String.sub arg index @@ (String.length arg) - index

let extraire_et_decoder terme liste = Uri.pct_decode @@ extraire @@ trouver_arg terme liste

(* prend une liste d'arg avec cette syntaxe = "arg1=body1;arg2=body2" et renvoie simplement le body*)
let rec extract_args = function
  | s::l -> (extraire s) :: extract_args l
  | [] -> []
 

let verifier_oauth =
  !oauth_version <> "Error" && !oauth_consumer_key <> "Error" && !oauth_signature <> "Error" && !oauth_nonce <> "Error" && !oauth_timestamp <> "Error"

(* Transforme une liste de string de type key=value en liste de couple (key*secret) *)
let convert_to_gapi liste =
  let extraire_both arg =
    let index =
      match String.index_opt arg '=' with
      | Some x -> x + 1
      | None -> raise Not_found
    in 
    (Uri.pct_decode @@ String.sub arg 0 (index-1), Uri.pct_decode @@ String.sub arg index @@ (String.length arg) - index)
  in
  let rec eval = function
    | x::l -> (extraire_both x):: eval l
    | [] -> []
  in
  eval liste


(*Avant : Uri.pct_encode *) (* Netencoding.Url.encode ~plus:false *)
let signature_oauth liste_args http_method basic_uri consumer_key secret =
        let couple_encode = (* 1 : encoder les keys/values *)
          List.map (
              fun (k,v) -> (Netencoding.Url.encode k, Netencoding.Url.encode v))
          @@ convert_to_gapi liste_args
        in 
        let couple_trie =   (* 2 : Trier par valeur de key *)
          List.sort   
            (fun (k1, v1) (k2,v2) ->
              let res = compare k1 k2 in
              if res = 0 then compare v1 v2 else res) couple_encode
        in 
        let liste_concat =  (* 3 : Les mettre sous la forme key=value&key2=value2*)
          String.concat "&"
          @@ List.map
               (fun (k,v) -> k ^ "=" ^ v) couple_trie
        in 
        let signature_base_string =     (* 4 : Ajouter la méthode HTTP ainsi que l'uri *)
          sprintf "%s&%s&%s" (String.uppercase_ascii http_method) (Netencoding.Url.encode basic_uri) (Netencoding.Url.encode liste_concat)
        in
        let signing_key = (Netencoding.Url.encode consumer_key) ^ "&" ^ (Netencoding.Url.encode secret) in  (* 5 : Créer la signing_key *)
        let encodage = Netencoding.Base64.encode
                       @@ Cstruct.to_string
                       @@ Nocrypto.Hash.SHA1.hmac (Cstruct.of_string signing_key) (Cstruct.of_string signature_base_string)
        in
        encodage  

                   (**************************** Serveur et lancement du serveur *******************************)

(* Traitement de la requête POST *)
let traiter_requete req =
  let liste_args = String.split_on_char '&' req in
  (* Init variables *)
  if extraire_et_decoder "oauth_signature_method" liste_args <> !oauth_signature_method then
    Server.respond_error ~status:`Not_implemented ~body:(sprintf "Try with %s oauth signature method" !oauth_signature_method) ()
  else
    (
      oauth_signature := extraire_et_decoder "oauth_signature" liste_args;
      oauth_timestamp := extraire_et_decoder "oauth_timestamp" liste_args;
      oauth_nonce := extraire_et_decoder "oauth_nonce" liste_args;
      oauth_version := extraire_et_decoder "oauth_version" liste_args;
      oauth_consumer_key := extraire_et_decoder "oauth_consumer_key" liste_args;
      oauth_callback := extraire_et_decoder "oauth_callback" liste_args;
      if not verifier_oauth then
        Server.respond_error ~status:`Bad_request ~body:"Missing oauth args" ()
      else 
        (* Vérifier la signature *)
        let test = generate_signature GapiCore.HttpMethod.POST "http://localhost:8000/launch" (convert_to_gapi liste_args) GapiCore.SignatureMethod.HMAC_SHA1 !oauth_consumer_key my_secret in
        let rep = (signature_oauth liste_args "post" "http://localhost:8000/launch" !oauth_consumer_key my_secret) in
        let reservse_gapi = String.concat "&" @@ List.map (fun (a,b) -> a ^ b) (convert_to_gapi liste_args) in
              (* Req = les parameters déjà encodés et mis comme il faut*)
        Server.respond_string ~status:`OK ~body:req () 
    )

      (* Après l'enco changer le + par " " et "%7" par ~ *)



          
let server =
  (* La réponse du serveur *)
  let callback _conn req body =
    let uri = Request.uri req in
    match Uri.path uri with (* Match l'URI *)
      
    |"/launch" ->
      (match req |> Request.meth with (* Type de requête *)
       | `GET -> async (fun () -> Lwt_unix.sleep 0.1 >>= fun () -> exit 0);
                 Server.respond_string ~status:`OK ~body:"shutting down" ()
       
       | `POST -> (match Request.has_body req with (* POST *)
                  |`Yes -> body |> Cohttp_lwt.Body.to_string >>= traiter_requete
                  |`No -> Server.respond_string ~status: `Bad_request ~body: "Missing POST body" ()
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

let port = 8000
let address = "127.0.0.1"
let url = Uri.of_string (sprintf "http://%s:%d/launch" address port)
let url_shutdown = Uri.of_string (sprintf "http://%s:%d/shutdown" address port)

let client () = 
 let body = Cohttp_lwt__Body.of_string "teste body" in
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
  (* Lwt_main.run (client ())*)
  | pid ->
     Printf.eprintf "server is %d\n%!" (Unix.getpid ());
     Lwt_main.run server
