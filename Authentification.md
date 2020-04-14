# Authentification

### Validation de données/caractères extérieur(e)s  : 

* Syntactique : renforcer la syntaxes des champs prédéfinis (Casse, caractères spéciaux).
* Sémantique : renforcer les données dans leur contexte (Date de début - fin, tranche de prix).

* Préférer une whitelist plutôt qu'une blacklist sur les données autorisées. Il faut donc mettre en place un fort pattern de validation pour que cela soit optimal.
* Faire la validation côté serveur.
* Passer les données sous des fonctions de conversion de balises HTML, et autre.

### Authentification :

Ne pas laisser s'authentifier des comptes sensibles.

**Mot de passe** :

* Longueur minimum de 8 caractères.
* Maximum de 128.
* Vérifier l'algo de hashage : Il peut tronquer et ne pas aller jusqu'à 128 caractères.
* Saler les mot de passes
* Donner l'accès à tous les caractères possibles.
* Avoir la possibilité de le changer ainsi que l'email (Avec validation par email avec token, questions secrètes...). Faire changer le mot de passe sur le site et ne pas l'envoyer par email.
* Donner une indication sur la robustesse du mot de passe (zxcvbn ou pwned passwords).
* Transmettre le mot de passe via TLS ou un transport sûr + le crypter et le hasher.

**Autre** :

* Redemander une authentification pour les parties sensibles du site.
* Si erreur de login : mettre quelque chose de générique ("Le compte n'existe pas") ou autre, ne pas indiquer ce qui ne va pas.
* Mettre en place un CAPTCHA pour éviter le bruteforce.
* Mettre une multi-authentification
* Bloquer le compte si trop d'erreurs
* Rediriger l'utilisateur vers une autre page après le login
* Pour les sessions : le faire via une session ID par rapport à l'ip client.
* Mettre en place des logs pour pouvoir tracer les problèmes.
* Désactiver le X-Frame : `X-Frame-Options : DENY`