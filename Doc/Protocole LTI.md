# Protocole LTI

### Liens :

* https://en.wikipedia.org/wiki/Learning_Tools_Interoperability
* http://www.imsglobal.org/activity/learning-tools-interoperability#LTIpublic
* http://www.imsglobal.org/spec/lti/v1p3/
* https://github.com/elaastic/elaastic-questions-server/tree/develop/src/main/kotlin/org/elaastic/questions/lti
* https://docs.moodle.org/38/en/External_tool_settings
* https://cssplice.github.io/lti.html

Spécifie des méthodes pour que des systèmes/structures d'apprentissages puissent communiquer avec des applications tierces.
Version standard : 1.3.
Systèmes utilisés : OAuth2, OpenID COnnect, JWT.

### Vocabulaire et définition :

**Tool Deployment** : Définit dans quel contexte l'outil peut être déployé. Si déployé hors de la plateforme mère : doit avoir un `deployment_id` et chaque message envoyé entre la plateforme mère et tierce doit se faire avec le `deployment_id` et le `client_id`.
Généralement le `deployment_id` correspond à un id de compte, potentiellement celui qui déploie l'outil.
Si l'outil est déployé plusieurs fois : chaque instance à son propre `development_id`. Le `client_id` reste le même.
Si déployé une fois par `client_id`, il peut avoir un `development_id` unique car la clé sera les deux id.

**LTI Links** : Un lien qui redirige vers un outil hébergé par la plateforme mère. Doit avoir un `message_type`. Il peut contenir des informations qui peuvent être utilisées dans l'outil. 
Chaque lien doit avoir un `deployment_id` unique.
Chaque lien connecté à une ressource doit contenir un identifiant unique de la plateforme `resource_link_id`. Cela fait référence à un *Ressource Link*.

**LTI Launch** : Un processus est lancé dans un outil quand un utilisateur interagit avec un *LTI Link* dans la plateforme mère. La *LTI plateform* et les outils utilisent des `messages` POST pour communiquer. Les données sont définies par un `message_type`.

**Contextes et ressources** : 

* **Contextes** : Tout ce qui va tourner autour des ressources : utilisateurs, rôles... Généralement ça va être le cours pour lequel l'outil est déployé.
* **Ressources** : Peut représenter un item, des ressources ou des classifications (Pre-work, Week 1). Dans une structure/ressource il peut y avoir plusieurs *LTI Links* afin de définir plusieurs contextes. Pour les distinguer il faut un `resource_link_id`.

**Utilisateurs et rôles** :

* **Utilisateur** : Un objet qui représente une personne qui utilise un outil spécifique dans la plateforme. La plateforme peut reléguer le système d'authentification à un autre système. Un utilisateur doit avoir un id unique dans la plateforme. Ses informations personnelles peuvent être partagées avec un outil, mais un(e) outil/plateforme ne doit pas utiliser d'autre attributs que l'id pour identifier l'utilisateur.
* **Rôle** : Une des trois propriétés que donne la plateforme lors d'un accès via *LTI Link* pour un outil (les deux autres sont `user_id` et le contexte). Il représente le niveau de privilège.

**Authentification, autorisation et moyens** :

* **Authentification** : Les plateformes LTI agissent comme OpenID et les *LTI Messages* sont donc des tokens OpenID. Mais on peut utiliser d'autres méthodes.
* **Autorisation** : L'accès aux ressources et fonctionnalités. Il y a deux niveaux : 
  * Dans une couche LTI : définit les moyens qu'un outil peut utiliser sur la plateforme.
  * Ou LTI peut transmettre les autorisations qu'un outil procure à travers la plateforme.
* **Moyens** : 3 grands types :
  * Expansion variable
  * Messages
  * Services

**Messages et services** :

* **Messages** : Via le navigateur client. Quand un utilisateur clique sur un lien vers une *LTI resource*, la plateforme initialise un *OpenID login* qui va passer par *LTI Message* avec son `id_token`jusqu'à l'outil désiré. Le receveur du message doit ignorer tout contexte qu'il ne comprend pas.
* **Service** : Via connexions entre la plateforme et l'outil. Quand un outil a besoin d’accéder directement à la plateforme (Ou vice-versa). REST peut être utilisé pour ça.

### LTI Message

**Optionnel** :

**`lti_message_hint`** : pour donner des informations sur le message.

**`lti_deployment_id` ** : Doit contenir le même`deployment_id` que pour l'envoi du message.

**`client_id`** : Spécifie le `client_id` qui doit être utilisé pour autoriser le message.  Utile pour une plateforme multi-inscription.

### Resource link launch request message

**Resource link** : fait référence à un lien qui pointe sur une ressource donnée par un outil.

**Resource like launch request** : vient d'un *resource link* classique. Il doit identifier ce lien. Il faudrait inclure le contexte dans lequel le lien vient, que cela soit l'utilisateur qui fasse la demande (Sauf si anonyme) et inclure diverses informations (rôle, plateforme...).
Grâce à ça l'outil va définir s'il doit donner l'accès et si c'est le cas, comment présenter les données à l'utilisateur.  

**Format d'un Resource link**: 

* Doit avoir le lien vers lequel il pointe.
* Id : l'id doit être stable et unique localement pour un contexte donné. Il doit donc changer si le lien est cliqué depuis un autre environnement. L'id respecte la casse et doit être < 255 caractères ASCII.
* description - optionnel : Phrase courte de description.
* title - optionnel. 

**Format d'une identité utilisateur** :

* sub : comme un id. Doit être stable et uniquement localement. < 255 caractères ASCII et avec casse.
* given_name - optionnel : si multiple, les séparer par un espace.
* family_name - optionnel : si multiple, un espace.
* name - optionnel : le nom complet.
* email - optionnel.

**Format d'un contexte** :

* id.
* type - optionnel.
* label - optionnel.
* title - optionnel.

**Format d'une plateforme** :

* guid : comme un id.
* contact_email - optionnel.
* description - optionnel.
* name - optionnel.
* url - optionnel.
* product_family_code - optionnel : société qui détient le produit.
* version - optionnel.



# Pour Moodle

https://www.imsglobal.org/spec/security/v1p0

Pour enregistrer l'outil (LTI 2p0) :

Moodle va envoyer une ToolProxyRegistration request avec ces paramètres : 

* lti_message_type : Va indiquer le message.
* lti_version.
* reg_key et reg_password : Ce sont des logs que va utiliser le Tool Provider pour s'enregistrer dans le Tool Consumer. Valable une fois, pour une courte période (1H). Si on utilise  OAuth : ça remplace le oauth_consumer_key et le oauth_consumer_secret.
* reg_url : (Supposition, doc manquante) Url sur lequel le Tool Consumer s'enregistre.

* tc_profile_url : L'adresse sur laquelle il va falloir faire une requête GET pour récupérer le Tool Consumer Profile (Donc le profil de Moodle).

* launch_presentation : Lien vers lequel le Tool Provider (Nous) doit rediriger une fois qu'il a fini son traitement d'enregistrement. Il faut mettre en paramètre de la requête deux champs 

  * status=succes | failure
  * tool_proxy_guid=<Identifiant unique pour le Tool Proxy>

   Normalement c'est censé rediriger l'admin de Moodle vers une fenêtre la console du Tool Consumer pour qu'il l'enregistre. 

Au début il envoie une requête à l'outil pour se login avec 4 paramètres :

* iss : issuer identifier. Il identifie Moodle.
* login_hint : la trace de login.
* target_link_uri : le lien vers lequel l'outil va rediriger quand il aura fini ses trucs de login.
* lti_message_hint : la trace du message LTI.

L'outil doit faire sa vie (Potentiellement demander un login pour bien confirmer qu'il s'agisse de l'user) et renvoyer vers le target_link_uri avec différents paramètres POST de cette forme :

* scope: openid
* response_type: id_token
* cliend_id: l'id qu'on veut donner à Moodle
* redirect_url: là où on veut rediriger l'user une fois que Moodle a fait sa vie. Correspond au target_link_uri.
* login_hint: le même que donné
* state: Une valeur opaque (Encodé et tout) pour pouvoir ajouter une sécurité et éviter le CSRF.
* response_mode: form_post
* nonce: String qui associe une session client avec un ID Token. La valeur est transmise sans modification de la demande d'authentification au jeton ID.
* prompt:none
* lti_message_hint: le même que donné



Pour LTI 1p0 Moodle envoie juste un payload et on doit vérifier la signature OAuth :

* Code OAuth de Moodle : https://github.com/moodle/moodle/blob/master/mod/lti/OAuth.php

* Leur fonction d'urlencode (L138) : http://api.drupalhelp.net/api/oauth/lib--OAuth.php/function/OAuthUtil%3A%3Aurlencode_rfc3986/7.3
  Replace "+" par " " et "%7E" par "~"

Découpage de la classe "OAuthSignatureMethod_HMAC_SHA1" :

* Récupération du payload
* Récupération de la signin_key :
  * Séparation de la key en deux parties : consumer et token (Secret)
  * Encodage selon urlencode des deux parties de la clé
  * Rassemblement de la clé avec "&" comme glue
* Création de la signature :
  * Utilisation de la fonction hash_hmac avec comme paramètre ["sha1", le payload, la clé et true]. Le dernier argument (Bool) : si on veut des données binaires "true" ou sinon c'est de l'hexa
  * Encodage du résultat en base 64