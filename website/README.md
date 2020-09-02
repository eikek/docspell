# Website

This is the docspell website and documentation.

## Building

The website is created using [zola](https://github.com/getzola/zola)
static site generator. The (very minimal) dynamic parts are written in
Elm.

The `build.sh` script builds the site.


## Development

Install things by running `yarn install`.

Open two terminals. In first run:

``` shell
nix-shell --run ./run-elm.sh
```

and in the second

``` shell
nix-shell --run "cd site && zola serve"
```

Open browser at `localhost:1111`.


## Publishing

``` shell
nix-shell website/shell.nix --run sbt
sbt> project website
```

### Check Links

``` scala
sbt> zolaBuild
sbt> zolaCheck
```

### Testing

``` scala
sbt> zolaBuildTest
sbt> ghpagesSynchLocal
```

Other terminal:

``` shell
cd ~/.sbt/ghpages/<some-hash>/com.github.eikek/docspell-website
python -m SimpleHTTPServer 1234
```

Open http://localhost:1234 in a browser.

### Publish

``` scala
sbt> zolaBuild
sbt> ghpagesPushSite
```
