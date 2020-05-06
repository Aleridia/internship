open Lwt
open Cohttp
open Cohttp_lwt_unix
open Printf

(*************************** Variables ******************)

let my_secret = "b7f70b00-48e1-47ea-9184-850b3ec867f1"
let url = "http://localhost:8000/launch"
let oauth_timestamp = ref "tmp"
let oauth_nonce = ref "tmp"
let oauth_signature_method = ref "HMAC-SHA1"
let oauth_signature = ref "tmp"
let oauth_consumer_key = ref "tmp"
let oauth_version = ref "tmp"

(*************************   Traitement POST ****************************)

 (* Renvoie la value d'une key dans une liste de couple de type (key,value) *)
let rec get_value key =
  function
  | (k,v)::l -> if k = key then v
            else get_value key l
  | _ -> "Error"


let rec verifier_oauth liste_args =
  (* Traitement de la requête POST *)
      oauth_signature := get_value "oauth_signature" liste_args;
      oauth_timestamp := get_value "oauth_timestamp" liste_args;
      oauth_nonce := get_value "oauth_nonce" liste_args; (* Penser à vérifier le nonce pour savoir s'il n'a pas été déjà utilisé *)
      oauth_version := get_value "oauth_version" liste_args;
      oauth_consumer_key := get_value "oauth_consumer_key" liste_args;
      !oauth_version <> "Error"
      && !oauth_consumer_key <> "Error"
      && !oauth_signature <> "Error"
      && !oauth_nonce <> "Error"
      && !oauth_timestamp <> "Error"


let remove_args liste = 
 List.filter (fun (a,b) -> a <> "oauth_signature") liste


(*Avant : Uri.pct_encode *) (* Netencoding.Url.encode ~plus:false *)
let signature_oauth liste_args http_method basic_uri secret =
  let couple_encode = (* 1 : encoder les keys/values *)
    List.map (
        fun (k,v) -> (Netencoding.Url.encode ~plus:false k, Netencoding.Url.encode ~plus:false v))
    @@ remove_args liste_args
  in
  let couple_trie =   (* 2 : Trier par valeur de key *)
    List.sort   
      (fun (k1, v1) (k2,v2) ->
        let res = compare k1 k2 in
        if res = 0 then compare v1 v2 else res)
      couple_encode
  in 
  let liste_concat =  (* 3 : Les mettre sous la forme key=value&key2=value2*)
    String.concat "&"
    @@ List.map
         (fun (k,v) -> k ^ "=" ^ v) couple_trie
  in 
  let signature_base_string =     (* 4 : Ajouter la méthode HTTP ainsi que l'uri *)
    sprintf "%s&%s&%s" (String.uppercase_ascii http_method) (Netencoding.Url.encode ~plus:false basic_uri) (Netencoding.Url.encode ~plus:false liste_concat)
  in
  let signing_key = (Netencoding.Url.encode ~plus:false secret) ^ "&" in  (* 5 : Créer la signing_key *)
  let encodage = Netencoding.Base64.encode @@ Cstruct.to_string @@ Nocrypto.Hash.SHA1.hmac ~key:(Cstruct.of_string signing_key) (Cstruct.of_string signature_base_string)
  in
  encodage  

                   (**************************** Serveur et lancement du serveur *******************************)

(* Traitement de la requête POST *)
let traiter_requete req =
  let liste_args = Netencoding.Url.dest_url_encoded_parameters req in
  if get_value "oauth_signature_method" liste_args <> !oauth_signature_method then (* Si ce n'est pas HMAC-SHA1 *)
    Server.respond_error ~status:`Not_implemented ~body:(sprintf "Try with %s oauth signature method" !oauth_signature_method) ()
  else
    (
      if not (verifier_oauth liste_args) then
        Server.respond_error ~status:`Bad_request ~body:"Missing oauth args" ()
      else 
        (* Vérifier la signature *)
        let fun_perso = signature_oauth liste_args "post" url my_secret in
        (* Req = les parameters déjà encodés et mis comme il faut *)
        if fun_perso = !oauth_signature then
          Server.respond_string ~status:`OK ~body:("Signature OK (" ^ fun_perso ^ ")") ()
        else
          Server.respond_string ~status:`Unauthorized ~body:"OAuth signature does not match" ()
    )

         
let server =
    let callback _conn req body =
    let uri = Request.uri req in
    match Uri.path uri with (* Match l'URI *)
      
    |"/launch" ->
      (match req |> Request.meth with (* Type de requête *)
       | `POST -> (match Request.has_body req with (* POST *)
                   | `Yes -> body |> Cohttp_lwt.Body.to_string >>= traiter_requete
                   | `No -> Server.respond_string ~status: `Bad_request ~body: "Missing POST body" ()
                   | _ -> Server.respond_string ~status: `Bad_request ~body: "Unknown POST body" ())
       | _ -> Server.respond_string ~status: `Not_acceptable ~body:"Unsuported request" () ) (* Si ce n'est pas POST *)

    | _ -> Server.respond_string ~status: `Not_found ~body:"Error 404" ()  (* Error 404 *)
  in

  Server.create ~backlog:10 ~mode:(`TCP (`Port 8000)) (Server.make ~callback ())


let () = Lwt_main.run server
