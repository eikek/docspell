# Website

This is the docspell website and documentation.

## Building

The website is created using [zola](https://github.com/getzola/zola)
static site generator. The (very minimal) dynamic parts are written in
Elm.

Sbt is used to build the site.


## Development

Install things by running `yarn install`.

Use a dev [environment](https://docspell.org/docs/dev/development/)
and open terminal for each script below:

1. Starting the server
   ``` shell
   cd site && zola serve
   ```
2. Building the stylesheet
   ``` shell
   ./scripts/run-styles.sh
   ```
3. Building some javascript files
   ``` shell
   ./scripts/run-elm.sh
   ```

Open browser at `localhost:1111`.


## Publishing

The above is great when editing, but doesn't fully reflect what will
be finally deployed. To see this, start sbt and change into the
website project.

``` shell
$ sbt
sbt> project website
```

Build everything and check for dead links:

``` scala
sbt> zolaBuildTest
sbt> zolaCheck
```

### Testing

``` scala
sbt> ghpagesSynchLocal
```

The final site is now generated and a simple http server can be used
to see how it will look when deployed.

``` shell
cd ~/.sbt/ghpages/<some-hash>/com.github.eikek/docspell-website
python -m http.server 1234
```

Open http://localhost:1234 in a browser.
