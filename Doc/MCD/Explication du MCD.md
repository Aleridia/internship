# Explication du MCD

![MCD](/home/lapin/stage/Doc/MCD/MCD.png)

Voici la représentation de données que je propose.
J'ai utilisé le logiciel [looping][looping] pour le représenter.

#### Utilisateur :

* Token: c'est l'id unique de l'utilisateur. Il sera généré comme il l'est actuellement.

* login_moodle: c'est le login que donnera Moodle à Pfitaxel lors d'une connexion *LTI*. Le champ sera vide si l'utilisateur s'identifie uniquement via Pfitaxel.

* login_pfitaxel: le login utilisé pour s'identifier dans Pfitaxel. Il sera vide si l'utilisateur ne passe que par Moodle. Si l'utilisateur veut se connecter via Pfitaxel sans passer par Moodle et que ce champ est vide, il lui faudra alors créer un compte sur Pfitaxel en renseignant son token (Voir [maquette][maquette_token]).

* token_used: initialisé à **false**. C'est un booléen qui va être utilisé pour la migration du mode "token" au mode "login/password" ou pour lier un compte Moodle à un compte Pfitaxel.  

  * Cas 1 : lorsque la migration sera effectuée, l'authentification par token ne sera plus disponible. Ils devront alors créer un compte Pfitaxel en indiquant leur token (Voir [maquette][maquette_token]). 

  * Cas 2 : même démarche pour un utilisateur Moodle voulant passer par Pfitaxel : Il lui faudra créer un compte en indiquant son token. 

    Dans les deux cas, le booléen passera à **true**. Si le booléen est à **true**, le token ne sera plus utilisable.

* password_pfitaxel: le mot de passe pour le compte Pfitaxel. Il sera salé et crypté, avec une longueur minimum de 8 caractères et maximum de 128 caractères. Voir le fichier [Authentification.md][authentification] pour plus de détails.



#### OAuth :

* secret: le secret utilisé pour vérifier la signature OAuth.
* nonce: les nonce générés par les requêtes LTI. Il faut les vérifier pour s'assurer qu'une requête est bien unique. Ils sont associés au secret utilisé pour un gain de place et de temps : si le fichier (ou la table) est trop volumineux ou si le temps de recherche est trop grand, il suffit juste de changer le secret. Les nonce pourront être alors supprimés car s'ils sont réutilisés, la signature OAuth ne correspondra plus (car le secret a changé) et la requête sera refusée.





#### Liens :

[authentification]: https://github.com/Aleridia/internship/blob/master/Doc/Authentification.md
[looping]: https://www.looping-mcd.fr/
[maquette_token]: 