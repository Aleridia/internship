# Notes OCaml

* **|>** : Ca reverse une fonction et ça peut éviter de déclarer un let. 
  `e |> f = f e` ou bien `12 |> fun x -> e` <=> `let x = 12 in e`
  
* **>>=** : Bind pour les Monades. Signature pour Lwt : `'a Lwt.t -> ('a -> 'b Lwt.t') -> 'b Lwt.t`

* Lwt_io.read_line_opt : `Lwt_io.read_line_opt : input_channel -> string option Lwt.t`

* Nestat : `netstat -tulpn`

* Variables nommées : `~var:var` <=> `~var` 

* Variables optionnelles : `?(step=1)`:  A une valeur par défaut et peut être remplacé.

  