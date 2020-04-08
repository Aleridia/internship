# <center>Git commit </center>

> ```bash
> <type>(<scope>): <subject>
> 
> <body>
> 
> <footer>
> ```

Exemple :

```bash
fix(middleware): ensure Range headers adhere more closely to RFC 2616

Add one new dependency, use `range-parser` (Express dependency) to compute
range. It is more well-tested in the wild.

Fixes #2310
```

Règles avec les lignes :

* 1 : <70 caractères, généralement on s'arrête à 50
* 2 : Toujours un blanc
* 3 - body : pas plus de 80 caractères par ligne. Utiliser l'impératif présent. Justifier le changement
* 4 : Un blanc
* 5 - footer : peut-être un fix, closes... Indiquer aussi s'il y a des breaking change

Exemple de scope : init, runner, watcher, config, web-server, proxy
