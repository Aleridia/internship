open Lwt


let counter = ref 0
let listen_address = Unix.inet_addr_loopback (* En clair sur 127.0.0.1 *)
let port = 8080
let backlog = 10 (* Long max de la queue des co en attente *)
let passwd = ref "lapin"
let login = ref "pinpix"

(* Je passe sl au cas où on veut ajouter des choses dans le token  *)
let traiter_fichier login sl =
  let ic = open_in (String.concat "." [login;"txt"]) in
  try
    let line = input_line ic in
    flush stdout;
    close_in ic;
    line
  with e ->
        close_in_noerr ic;
        raise e

let traiter_msg msg =
  let sl = String.split_on_char ',' (String.sub msg 1 ((String.length msg) -2) )
  in
  let testLogin = match sl with
    | x::y::l -> (x, x = !login && y = !passwd)
    | _ -> ("DEFAULT",false)
  in if snd testLogin then traiter_fichier (fst testLogin) sl else "Erreur login/mdp" 


(* Le >>= c'est le bind en monade *)
(* Ca prend  ('a t -> ('a t -> 'b t)) *)
(* Donc ici val (>>=): 'a Lwt.t -> ('a -> 'b Lwt.t) -> 'b Lwt.t *)
let rec tenir_co ic oc () =
  (* Lwt_io.read_line_opt : input_channel -> string option Lwt.t *)
  Lwt_io.read_line_opt ic >>= (* Retourne un string option pour éviter de renvoyer une exception *)
    (fun msg ->     (* Equ : let x msg = Lwt_io... ic in match msg with...  *)
      match msg with
      | Some msg -> (* S'il y en a  on traite *)
         let reply = traiter_msg msg in (* Traitement qui renvoie un String *)
         Lwt_io.write_line oc reply >>= tenir_co ic oc (* On écrit le message et on bind sur le résulat *)
      | None -> Logs_lwt.info (fun m -> m "Connection fermée") >>= return)
      (* Si rad_line return None, on log que c'est close *)

(* Création d'un thread tenir_co *)
let accept_co conn =
  let fd, _ = conn in (* Conn est un couple, on ignore la seconde valeur *) 
  let ic = Lwt_io.of_fd Lwt_io.Input fd in 
  let oc = Lwt_io.of_fd Lwt_io.Output fd in
  (* Lwt.on_failure p f -> f run si p est rejeté *)(* Donc si tenir_co marche pas, on log une erreur *)
  Lwt.on_failure (tenir_co ic oc ()) (fun e -> Logs.err (fun m -> m "%s" (Printexc.to_string e) ));
  Logs_lwt.info (fun m -> m "Nouvelle co") >>= return


let creer_serv sock =
  let rec serve () =
    (* Lwt_unix prends un (fd,sockaddr) en param, donc on le sort et on le donne à accep_co*)
    Lwt_unix.accept sock >>= accept_co >>= serve
  in serve

let creer_sock () =
  let open Lwt_unix in
  (* socket: domaine -> type -> fd *)
  (* PF_INET : packet format *)
  (* SOCK_STREAM pour TCP, SOCK_DGRAM pour udp *)
  let sock = socket PF_INET SOCK_STREAM 0 in
  (* Warning car bind renvoie un unit Lwt.t au lieu d'un unit *)
  (* Bind : associe notre socket locale à la socket entrante *)
  bind sock @@ ADDR_INET(listen_address, port);
  (* Listen met la socket en mode passif *)
  listen sock backlog;
  sock

let () =
  let sock = creer_sock () in
  let serve = creer_serv sock in
  Lwt_main.run @@ serve ()
                        (* @@ ? *)
