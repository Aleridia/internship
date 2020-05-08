# Explication de la maquette

Pour faire cette maquette j'ai utilisé le site [balsamiq][balsamiq].

* [login][login] : la page de login lorsque l'utilisateur dispose d'un compte pfitaxel.
* [créer un compte][creer_compte] : la page de création de compte. C'est ici qu'il va falloir renseigner son token pour effectuer une migration de compte : token vers login/password mais aussi Moodle vers Pfitaxel (voir les [explication MCD][explication_mcd]). Le point d'interrogation à côté du champ **Token** est une bulle d'aide. L'utilisateur devra accepter l'exploitation de données par Pfitaxel pour pouvoir créer son compte.
* [première connexion - 1][co1] : page vers laquelle l'utilisateur sera redirigé lorsqu'il voudra accéder à Pfitaxel pour la première fois depuis Moodle. S'il a un compte Pfitaxel, il sera redirigé vers la page de *login* et la liaison avec Moodle sera faite automatiquement. Sinon, il sera redirigé vers *première connexion - 2*. 
* [première connexion - 2][co2 ] : si l'utilisateur souhaite créer un compte Pfitaxel, il sera alors redirigé vers la page *créer un compte*. Il n'aura pas à remplir le champ **Token** car la migration sera automatique. Sinon, il sera redirigé vers *première connexion - 3*.
* [première connexion - 3][co3] : l'utilisateur arrive sur cette page s'il souhaite accéder à Pfitaxel qu'en passant par Moodle. Il devra accepter l'exploitation de données. S'il le fait (bouton continuer), son compte sera créé automatiquement. Sinon (bouton retour), il sera redirigé vers Moodle et son compte ne sera pas créé.





#### Liens :

[balsamiq]: https://balsamiq.cloud/
[login]: 
[creer_compte]: 
[explication_mcd]: 
[co1]: 
[co2 ]: 
[co3]: 