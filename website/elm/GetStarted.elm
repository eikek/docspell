module GetStarted exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Icons
import Markdown


getStarted : String -> List (Html msg)
getStarted version =
    [ div [ class "content container" ]
        [ Markdown.toHtml []
            """Docspell consists of several components. The easiest way to get started is probably to use docker and
[docker-compose](https://docs.docker.com/compose/)."""
        , Markdown.toHtml []
            """1. Clone the github repository
   ```bash
   $ git clone https://github.com/eikek/docspell
   ```
   Alternatively, [download](https://github.com/eikek/docspell/archive/master.zip) the sources and extract the zip file.
2. Change into the `docker` directory:
   ```bash
   $ cd docspell/docker
   ```
3. Run `docker-compose up`:

   ```bash
   $ export DOCSPELL_HEADER_VALUE="my-secret-123"
   $ docker-compose up
   ```

   The environment variable defines a secret that is shared between
   some containers. You can define whatever you like. Please see the
   [`consumedir.sh`](doc/tools/consumedir#docker) docs for additional
   info.
4. Goto <http://localhost:7880>, signup and login. When signing up,
   you can choose the same name for collective and user. Then login
   with this name and the password.

5. (Optional) Create a folder `./docs/<collective-name>` (the name you
   chose for the collective at registration) and place files in there
   for importing them.

The directory contains a file `docspell.conf` that you can
[modify](docs/configure) as needed.
    """
        ]
    , div [ class "content container" ]
        [ div [ class "notification is-info is-light" ]
            [ text "If you don't use docker, there are other ways that are "
            , text "described in the relevant "
            , a [ href "/docs/install" ]
                [ text "documentation page"
                ]
            ]
        ]
    , div [ class "content container" ]
        [ div [ class "notification is-success is-light" ]
            [ div [ class "content is-medium" ]
                [ h3 [ class "title" ]
                    [ text "Where to go from here?"
                    ]
                , ul []
                    [ li []
                        [ text "The "
                        , a [ href "/docs/intro" ]
                            [ text "introduction" ]
                        , text " writes about the goals and basic idea."
                        ]
                    , li []
                        [ text "There is a comprehensive "
                        , a [ href "/docs" ]
                            [ text "documentation"
                            ]
                        , text " available."
                        ]
                    , li []
                        [ text "The source code is hosted on "
                        , a [ href "https://github.com/eikek/docspell" ]
                            [ text "github"
                            ]
                        , text "."
                        ]
                    ]
                ]
            ]
        ]
    ]
