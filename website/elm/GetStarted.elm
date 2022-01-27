module GetStarted exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Markdown


getStarted : String -> Html msg
getStarted _ =
    div [ class "container max-w-screen-lg mx-auto text-xl px-10 lg:px-0 leading-relaxed min-h-screen" ]
        [ Markdown.toHtml [ class "my-4 markdown-view" ]
            """Docspell consists of several components. The easiest way to get started is probably to use docker and
[docker-compose](https://docs.docker.com/compose/)."""
        , Markdown.toHtml [ class "my-4 markdown-view " ]
            """1. Clone the github repository
   ```bash
   $ git clone https://github.com/eikek/docspell
   ```
   Alternatively, [download](https://github.com/eikek/docspell/archive/master.zip) the sources and extract the zip file.
2. Change into the `docker-compose` directory:
   ```bash
   $ cd docspell/docker/docker-compose
   ```
3. Run `docker-compose up`:
   ```bash
   $ docker-compose up -d
   ```
4. Goto <http://localhost:7880>, signup and login. When signing up,
   choose the same name for collective and user. Then login
   with this name and the password.
5. (Optional) Create a folder `./docs/<collective-name>` (the name you
   chose for the collective at registration) and place files in there
   for importing them.

The `docker-compose.yml` file defines some environment variables to
configure docspell. You can [modify](docs/configure) them as needed.
    """
        , div [ class "blue-message" ]
            [ text "If you don't use docker, there are other ways that are "
            , text "described in the relevant "
            , a [ href "/docs/install", class "link" ]
                [ text "documentation page"
                ]
            ]
        , div [ class "green-message mt-4 " ]
            [ h3 [ class "text-4xl font-bold font-serif py-2 mb-2" ]
                [ text "Where to go from here?"
                ]
            , ul [ class "list-disc list-inside " ]
                [ li []
                    [ text "Find out "
                    , a [ href "/docs/feed" ]
                        [ text "how files can get into Docspell."
                        ]
                    ]
                , li []
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
                , li []
                    [ text "Chat on "
                    , a [ href "https://gitter.im/eikek/docspell" ]
                        [ text "Gitter"
                        ]
                    , text " for questions and feedback."
                    ]
                ]
            ]
        ]
