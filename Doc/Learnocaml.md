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

Utilisation de irmin 1.4 et de irmin-unix 1.3.3.

On peut mettre tous les champs dans les key et le token dans la value. Pas besoin de vérifier si le token est unique car on a la certitude qu'il l'est grâce au système de création de dossier.



#### Problème :

##### Comment avoir toutes les keys ? 

* Avoir la dernière version et utiliser fold
* Essayer un truc avec Tree.diff (Comment manipuler des Irmin.diff ?)
* Essayer de naviguer dans un Tree avec les nodes (Mais si plusieurs nodes, comment je passe au suivant dans le Tree ?)
* Mettre les tokens dans un fichier à part (Au moins on esquive le soucis et ça nous fait un index qui est moins lourd)



##### Comment organiser les données ?

Si je mets le token comme key, il y a un problème. Car l'utilisateur va se login avec soit son login_moodle soit son login_pfitaxel. Mais si c'est l'ancienne version il va se login avec son token.

Solutions : 

* Faire deux représentations de données : 
  * Une avec le token comme key et des données en value (Comme le nickname)
  * Une autre pour la nouvelle implémentation :
    * On garde le token comme key, et il servira de login pour l'utilisateur. L'email sera là pour la récupération du compte. En value on met le `record` utilisateur.
    * On met en place un système de mapping de données. On va séparer le login_moodle et le login_pfitaxel en deux représentations, mais qui seront identiques dans le concept. Le login sera la key, et la value sera le token associé à ce login. Une fois le token récupéré, il nous suffira de faire comme le point ci-dessus. C'est plus simple pour l'association de compte car il suffira juste de créer une entrée dans le "registre" irmin voulu.



#### Concurrence

Voir : https://mirage.github.io/irmin/irmin-unix/Irmin_unix/Git/FS/KV/index.html#val-with_tree
Pour le moment j'ai mis à `Merge

### Problèmes à régler

* Stockage des tokens dans l'index : un String n'est pas trop "petit" ? Si on a beaucoup de tokens à stocker. Passer pas une liste ? Un big string ?
* L'ajout d'un Token : il faut aussi l'ajouter dans l'index. Faire une fonction qui regroupe les deux ? Ajouter un appel pour l'ajout dans l'index après le traitement originel ?