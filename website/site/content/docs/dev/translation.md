+++
title = "Translating Web-UI"
weight = 10
+++

# UI Translation

Help with translating the web-ui is greatly appreciated. I can only
provide translations for English and German, and these may be wrong -
so pointing out mistakes is also appreciated :).

Here is a detailed walkthrough for adding a new language. It requires
to code in [Elm](https://elm-lang.org). But even if you're not a
programmer, you will be comfortable as it's not difficult for this
task. Elm is also a nice and friendly language, provding helpful error
messages.

This guide assumes no knowledge about Elm at all.

## TL;DR

If you are already familiar with Elm, here is the TL;DR:

1. Goto `Messages.UiLanguage` in `modules/webapp/src/main/elm` and add
   another language to the union type and also to the `all` list.
2. Fix all compile errors by providing a different `Texts` value for
   the new language.


# Prepare

You need to install [git](https://git-scm.org),
[sbt](https://scala-sbt.org), [Elm](https://elm-lang.org) and
[nodejs](https://www.npmjs.com/get-npm) (for the `npm` command) to
compile and run the project.

It is also recommended to install `elm-format` as it will help you to
format the elm source code. Look
[here](https://github.com/avh4/elm-format) for how to install it with
your editor of choice.

## Checkout the source code

Note: These steps are only required to do once. If you come back to
translating, just start the application.


Use git to clone the docspell repository to your machine. In a
terminal type:

``` bash
❯ git clone https://github.com/eikek/docspell.git
Cloning into 'docspell'...
remote: Enumerating objects: 1861, done.
remote: Counting objects: 100% (1861/1861), done.
remote: Compressing objects: 100% (861/861), done.
remote: Total 30276 (delta 821), reused 1604 (delta 668), pack-reused 28415
Receiving objects: 100% (30276/30276), 60.89 MiB | 23.62 MiB/s, done.
Resolving deltas: 100% (14658/14658), done.

/tmp took 4s
❯
```

This creates a new directory `docspell`. Change into it, create a
`DOCSPELL_ENV` environment variable and run sbt:

``` bash
❯ cd docspell
docspell on  master via 🌳 v0.19.1 via ☕ v11.0.9 via ⬢ v12.21.0
❯ export DOCSPELL_ENV=dev
❯ sbt
[info] welcome to sbt 1.5.0 (Oracle Corporation Java 1.8.0_212)
[info] loading settings for project global-plugins from plugins.sbt ...
[info] loading settings for project docspell-build from plugins.sbt ...
[info] loading project definition from /tmp/docspell/project
[info] compiling 6 Scala sources to /tmp/docspell/project/target/scala-2.12/sbt-1.0/classes ...
[info] loading settings for project root from build.sbt,version.sbt ...
[info] resolving key references (24191 settings) ...
[info] set current project to docspell-root (in build file:/tmp/docspell/)
[info] sbt server started at local:///home/eike/.sbt/1.0/server/3cf61b9ad9af43ee6032/sock
[info] started sbt server
sbt:docspell-root>
```

This downloads some stuff and puts you in the sbt shell. Now compile
everything (only needed the first time after checkout):

``` sbt
sbt:docspell-root> make
```

This will take a while, you need to wait until this is finished.


### Start the application

If sbt is not started, start sbt from within the source root. Also
export the `DOCSPELL_ENV` variable *before* starting sbt:

``` bash
> export DOCSPELL_ENV=dev
> sbt
```

Then start the application:

``` sbt
sbt:docspell-root> reStart
```

This starts docspell (joex and the restserver). Once the output gets a
bit quiter, open a browser and navigate to `http://localhost:7880`.
You can create a new account (if not already done so) and login.

Note that the database is created in your `/tmp` directory, so it
might be cleared once you restart your machine. For translating this
should not be a problem.

## Make webui updates faster

The sbt build tool could be used to watch the elm sources and
re-compile everything on change. This however also restarts the server
and takes quite long. When only coding on the webui the server can be
just left as is. Only the new compiled webapp must be made available
to the running server. For this, a script is provided in the
`project/` folder.

Now open two more terminals and `cd` into the docspell folder as before
and run the following in one:

``` bash
❯ ./project/dev-ui-build.sh watch-js
Compile elm to js …
Success!

    Main ───> /tmp/docspell/modules/webapp/target/scala-2.13/classes/META-INF/resources/webjars/docspell-webapp/0.22.0-SNAPSHOT/docspell-app.js

Watching elm sources. C-c to quit.
Setting up watches.  Beware: since -r was given, this may take a while!
Watches established.
```

And in the other run this:

``` bash
❯ ./project/dev-ui-build.sh watch-css
Watching css …
```

Once you have this, you're all set. The docspell application is
running and changes to elm and css files are detected, the webapp is
compiled and the resulting javascript and css file is copied to the
correct location. To see your changes, a refresh in the browser is
necessary.

If this script is not working, install inotify-tools. The
`inotifywait` command is required.

You'll notice that compiling elm and css is very fast.


## Find the webapp sources

The web-ui is implemented in the `webapp` module. The sources can be
found in the folder `modules/webapp/src/main/elm`.

All translated strings are in the files below `Messages` directory.
You should start with the file `UiLanguage.elm` to add a new language
to the list. Then start with `App.elm` to provide transalations. See
below for details.


# Example: Add German

## Add the new language

Start by editing `UiLanguage.elm` and add another language to the
list:

``` elm
type UiLanguage
    = English
    | German
```

More languaes are simply appended using the `|` symbol. Use the
English name here, because this is source code.


Also add it to the list of all languages below. Simply add the new
language separated by a comma `,`.

``` elm
all : List UiLanguage
all =
    [ English
    , German
    ]
```

If you make a mistake, the elm compiler will tell you with usually
quite helpful messages. Now, after adding this, there will be errors
when compiling the elm files. You should see something like this:

```
Detected problems in 1 module.
-- MISSING PATTERNS ------------------- modules/webapp/src/main/elm/Messages.elm

This `case` does not have branches for all possibilities:

45|>    case lang of
46|>        English ->
47|>            gb

Missing possibilities include:

    German

I would have to crash if I saw one of those. Add branches for them!

Hint: If you want to write the code for each branch later, use `Debug.todo` as a
placeholder. Read <https://elm-lang.org/0.19.1/missing-patterns> for more
guidance on this workflow.
```

So around line 45 in `Messages.elm` there is something wrong. This is
the place where a record of all strings is returned given some
lanugage. Currently, there is only one set of strings for English.
Open this file, you see at the and a value of name `gb` for English.
Copy it to another name, `de` for this example (it's good practice to
stick to the two letter country code).

``` elm
de : Messages
de =
    { lang = German
    , iso2 = "de"
    , label = "Deutsch"
    , flagIcon = "flag-icon flag-icon-de"
    , app = Messages.App.gb
    , collectiveSettings = Messages.Page.CollectiveSettings.gb
    , login = Messages.Page.Login.gb
    , register = Messages.Page.Register.gb
    , newInvite = Messages.Page.NewInvite.gb
    , upload = Messages.Page.Upload.gb
    , itemDetail = Messages.Page.ItemDetail.gb
    , queue = Messages.Page.Queue.gb
    , userSettings = Messages.Page.UserSettings.gb
    , manageData = Messages.Page.ManageData.gb
    , search = Messages.Page.Search.gb
    }
```

Change `lang`, `iso2`, `label` and `flagIcon` appropriately. For the
`label` use the native language name (not English), as this is the
label shown to users when selecting a language. The flag icon can be
copied and only the last two letters need to be changed to the country
code. You may look [here](https://github.com/lipis/flag-icon-css) for
additional information.

Now the error can be fixed. Go to line 45 and add another branch to
the `case` expression:

``` elm
get : UiLanguage -> Messages
get lang =
    case lang of
        English ->
            gb

        German ->
            de
```

This makes the compiler happy again. If you refresh the browser, you
should see the new language in the dropdown menu. You can already
choose the new language, but nothing happens in the application. Of
course, we just copied the English strings for now. So now begins the
translation process.


## Translating

Now translation can begin. If you look at the newly created value
`de`, you'll see some entries in the record. Each corresponds to a
page: `login` is for the login page, `home` for the "home page" etc;
and `app` is for the top menu.

Take one of them and start translating. For the example, I use the
first one which is `Messages.App`. The file to this is
`Messages/App.em`. You can always replace the dots with slashes to
find a file to an elm module. Open this file and you'll see again a
`gb` value at the end. Copy it to `de` and start translating:

``` elm
de : Texts
de =
    { collectiveProfile = "Kollektiv-Profil"
    , userProfile = "Benutzer-Profil"
    , lightDark = "Hell/Dunkel"
    , logout = "Abmelden"
    , items = "Dokumente"
    , manageData = "Daten verwalten"
    , uploadFiles = "Dateien hochladen"
    , processingQueue = "Verarbeitung"
    , newInvites = "Neue Einladung"
    , help = "Hilfe (English)"
    }
```

Then go to the beginning of the file and add the new `de` value to the
list of "exposed" values. This is necessary so it can be used from
within the `Messages.elm` module.

``` elm
module Messages.App exposing
    ( Texts
    , de {- the new value -}
    , gb
    )
```

Now you can go back to `Messages.elm` and exchange `Messages.App.gb`
with `Messages.App.de`.

``` elm
de : Messages
de =
    { lang = German
    , iso2 = "de"
    , label = "Deutsch"
    , flagIcon = "flag-icon flag-icon-de"
    , app = Messages.App.de
    , collectiveSettings = Messages.Page.CollectiveSettings.gb
    , login = Messages.Page.Login.gb
    , register = Messages.Page.Register.gb
    , newInvite = Messages.Page.NewInvite.gb
    , upload = Messages.Page.Upload.gb
    , itemDetail = Messages.Page.ItemDetail.gb
    , queue = Messages.Page.Queue.gb
    , userSettings = Messages.Page.UserSettings.gb
    , manageData = Messages.Page.ManageData.gb
    , search = Messages.Page.Search.gb
    }
```

If you refresh the browser, you should now see the new values. Then
take the next entry and start over. It happens that some files contain
other string-sets of certain components. Then just follow this guide
recursively.


# Publishing

You can publish your work to this repo in various ways:

## Github PR

This is the preferred way, because it means less work for me :). If
you have a github account, you can create a pull request. Here is a
quick walk-through. There is a thorough help [at
github](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork).

1. Fork this repository in the github webapp
2. Go to the docspell source root you checked out in the terminal. Run:
   ```
   git remote rename origin upstream
   git remote add origin git@github.com:<your-github-name>/docspell.git
   git fetch --all
   ```
3. Create a new git branch:
   ```
   git checkout -b translate origin/master
   ```
4. Make a commit of your changes:
   ```
   git config user.name "Your Name"
   git config user.email "Your Email" #(note that this email will be publicly viewable! a dummy address is fine, too)
   git commit -am 'Add translation for German'
   ```
   Modify the message to your needs.
5. Push the change to your fork:
   ```
   git push origin translate
   ```
6. Go to the github webapp and create a pull request from your branch.

## E-Mail

You can send me the patch via e-mail. You can use `git send-email` or
your favorite e-mail client. For this do step 4 from above and then:

```
git bundle create translation.bundle origin/master..HEAD
```

Then send the created `translate.bundle` file. If this command doesn't
work, try:

```
git format-patch origin/master..HEAD
```

This results in one or more `0001-…` files that you can send.

## Any other

Contact me by mail or create an issue.
