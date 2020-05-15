# Token.Index.get

#### Fonction Token.Index.get :

Se trouve dans /state/learnocaml_store.ml L.377.

Utilisée dans deux fichiers :

* /server/learnocaml_server.ml : L.353 et L.512
* /state/learnocaml_store.ml : L.527

Fonctionnement :

* **aux** : va vérifier le rendu du stream passé. Prend en paramètre un `Lwt_stream`, un 'a (liste) et renvoie un `'a Lwt.t`. Le `_stream.get` remove l'élément.
  * Si c'est ( "." | ".." )  (Un dossffier vide) alors il s'appelle lui même.
  * S'il y a quelque chose, il appelle scan en concaténant le dossier courant avec le chemin trouvé, puis il s'appelle lui-même avec le résultat de scan. En gros s'il trouve un dossier il va appeler scan qui va explorer l'intérieur de ce dossier (grâce à aux). Et il stocke le résultat (quand c'est la fin du dossier) dans une liste de type 'a lwt.
  * S'il n'y a rien il retourne la liste.
* **scan**: Prend en paramètre une fonction un `string` (qui est en réalité le dossier courant), un `'a` qui est une liste vide et renvoie un `'a Lwt.t` qui est une liste de token.
  * Fonction de scan : Prend en paramètre un `string` qui est le dossier courant, un `'a` qui est la liste des tokens et renvoie un `'a Lwt.t`.dfgddf
    Si on est à la fin, alors on renvoie le cdgddhemin du dossier courant, sinon on renvoie le d
    Stok : Va prendre le d et va le formater pour en faire un token (Changer les "/" par "-").
    Puis elle va essayer de parse le token (string -> string list). Si ça passe on renvoie la liste avec le parse d'inséré, sinon on renvoie la liste.



Propositions d'amélioration :

* Mettre un paramètre en plus : Quand cette fonction est utilisée, elle est suivie d'un `List.filter` qui renvoie les student ou les teacher. On peut simplement mettre en place un paramètre pour raccourcir le traitement. Ex : Si c'est un teacher, on vérifie si un dossier "X" existe. Si non on renvoie une liste vide, sinon on se place directement dans le dossier "X",  comme ça pas besoin de traiter les élèves. 
* Changer le système de sauvegarde par fichier en système de sauvegarde par BDD.



Ce qui n'est pas possible :

* Mettre en place un index par fichier : En soi l'index est déjà mis en place via la création des dossiers qui correspondent à une partie du token.





Modifications :

En réalité j'ai juste changé le traitement en rajoutant un booléen `teacher` dans la fonction, qui indique si on veut les token teacher ou non 

* Si true : Je vérifie que le dossier "X" existe.
  * Si false : Je renvoie une liste vide.
  * Si true, je fais le traitement mais en mettant "X"  comme paramètre de la fonction scan (le dossier courant).
* Si false : Aucun changement.



Le gain de temps est non négligeable !



Réflexion : 

Si le booléen est à false, est-ce que ça vaut le coup de changer la fonction pour exclure le dossier "X" du traitement ? Car il y a peu de teachers donc en soi cela prend peu de temps. Car la modification de la fonction risque d'augmenter un peu le temps de traitement.

