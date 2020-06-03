
val mutex_json_token : Lwt_mutex.t
val to_json_string : string -> Yojson.Basic.t
val get_fichier : string -> unit -> Yojson.Basic.t
val get_token : unit -> string
val transformation_liste : string list -> Yojson.Basic.t list
val creer_index :  string list -> unit -> unit
val ajouter_token : string -> unit -> unit
