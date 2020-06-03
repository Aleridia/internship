open Yojson
open Printf
open Lwt

let mutex_json_token = Lwt_mutex.create ()


let to_json_string (value:string) = (`String value : Yojson.Basic.t)

let get_fichier nom () = if Sys.file_exists nom then Yojson.Basic.from_file nom
                         else
                           (close_out @@ open_out nom;
                            Yojson.Basic.from_file nom)

let get_token () =
  let json = get_fichier "token.json" () in
  String.concat "&" @@ List.map (fun e -> Yojson.Basic.Util.to_string e) @@ Yojson.Basic.Util.to_list json

(* Transtype une liste de string en `String Yojson *)
let rec transformation_liste liste =
  match liste with
  | x::l -> to_json_string x :: transformation_liste l
  | [] -> []


let creer_index liste () = 
  (* Lui passer un channel output *)
  Lwt.ignore_result (Lwt_mutex.lock mutex_json_token);
  let oo = open_out "token.json" in
  let cast liste = (`List (transformation_liste liste) : Yojson.Basic.t) in
  let a_ecrire liste channel = Yojson.Basic.pretty_to_channel channel @@ cast liste in 
  a_ecrire liste oo;
  close_out oo;
  Lwt_mutex.unlock mutex_json_token;
  ()

let ajouter_token token () =
  let json_list = Yojson.Basic.Util.to_list @@ get_fichier "token.json" () in 
  let token = to_json_string token in
  Lwt.ignore_result (Lwt_mutex.lock mutex_json_token);
  let oo = open_out "token.json" in
  let cast = (`List (token::json_list)) in 
  Yojson.Basic.pretty_to_channel oo cast;
  close_out oo;
  Lwt_mutex.unlock mutex_json_token;
  ()
  
