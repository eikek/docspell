module Main exposing (..)

import Browser
import Demo
import ExtraAttr exposing (..)
import Feature exposing (Feature)
import GetStarted
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Random
import Random.List



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



--- Model


type alias Flags =
    { version : String
    }


type alias Model =
    { navbarOpen : Bool
    , features : List Feature
    , flags : Flags
    }


type Msg
    = ToggleNavbarMenu
    | ShuffleFeatures
    | ListShuffled (List Feature)



--- Init


viewFeatureCount : Int
viewFeatureCount =
    10


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { navbarOpen = False
      , features = List.take viewFeatureCount Feature.features
      , flags = flags
      }
    , Cmd.none
    )


shuffleFeatures : Cmd Msg
shuffleFeatures =
    Random.List.shuffle Feature.features
        |> Random.map (List.take viewFeatureCount)
        |> Random.generate ListShuffled



--- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleNavbarMenu ->
            ( { model | navbarOpen = not model.navbarOpen }
            , Cmd.none
            )

        ShuffleFeatures ->
            ( model, shuffleFeatures )

        ListShuffled lf ->
            ( { model | features = lf }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



--- View


view : Model -> Html Msg
view model =
    node "body"
        [ class "text-gray-700" ]
        [ mainHero model
        , demoHeader
        , section [ class "container max-w-screen-xl mx-auto mb-2" ]
            [ div [ class "mt-3 flex flex-col space-y-4" ]
                [ Demo.demo Demo.processDemo
                , Demo.demo Demo.navigateDemo
                ]
            ]
        , featureHeader model
        , section [ class "mx-auto max-w-screen-xl  mb-2 mt-4" ]
            (List.indexedMap Feature.featureBox model.features
                ++ [ div
                        [ class "flex px-8 py-8 border rounded mb-5 shadow-lg text-2xl"
                        , class "sm:flex-row sm:space-y-0 sm-space-x-4"
                        , class "mx-2 sm:mx-8"
                        ]
                        [ div [ class "text-center w-full" ]
                            [ text "A more complete list can be found in "
                            , a [ href "/docs/features", class "link" ] [ text "here" ]
                            , text "."
                            ]
                        ]
                   ]
            )
        , getStartedHeader model
        , GetStarted.getStarted model.flags.version
        , footHero model
        ]


footHero : Model -> Html Msg
footHero model =
    footer
        [ id "footer"
        , class "footer"
        ]
        [ div [ class "text-center" ]
            [ span []
                [ text ("Docspell, " ++ model.flags.version)
                ]
            , span [ class "pr-1 pl-1" ]
                [ text " • "
                ]
            , a
                [ href "https://spdx.org/licenses/AGPL-3.0-or-later.html"
                , target "_blank"
                , class "link"
                ]
                [ text "AGPLv3+"
                ]
            , span [ class "pr-1 pl-1" ]
                [ text " • "
                ]
            , a
                [ href "https://github.com/eikek/docspell"
                , target "_blank"
                , class "link"
                ]
                [ text "Source Code"
                ]
            , span [ class "pr-1 pl-1" ]
                [ text " • "
                ]
            , span []
                [ a
                    [ href "https://gitter.im/eikek/docspell"
                    , target "_blank"
                    , class "link"
                    ]
                    [ text "Chat on Gitter"
                    ]
                ]
            ]
        ]


getStartedHeader : Model -> Html Msg
getStartedHeader _ =
    section
        [ id "get-started"
        , class "hero-header"
        ]
        [ text "Get Started"
        ]


demoHeader : Html msg
demoHeader =
    h2
        [ class "hero-header"
        , id "demos"
        ]
        [ text "Screencasts"
        ]


featureHeader : Model -> Html Msg
featureHeader _ =
    h2
        [ id "feature-selection"
        , class "hero-header"
        ]
        [ text "Feature Selection"
        ]


navBar : String -> Html Msg
navBar classes =
    nav
        [ id "top-nav"
        , class "top-0 z-50 w-full flex flex-row justify-start shadow-sm h-14 antialiased "
        , class classes
        ]
        [ a
            [ onClick ToggleNavbarMenu
            , href "#"
            , class "font-bold inline-flex items-center px-4 w-10 sm:hidden "
            ]
            [ i [ class "fa fa-bars" ] []
            ]
        , a
            [ class "inline-flex px-4 items-center hover:bg-gray-50 hover:bg-opacity-20"
            , href "/"
            ]
            [ div [ class "" ]
                [ Icons.logo
                ]
            , span [ class "ml-1 text-2xl font-semibold font-serif" ]
                [ text "Docspell" ]
            ]
        , a
            [ href "docs/"
            , class "px-4 flex items-center hover:bg-gray-50 hover:bg-opacity-20"
            , class " text-xl"
            ]
            [ Icons.docs
            , span [ class "ml-2 tracking-wide" ]
                [ text "Documentation"
                ]
            ]
        , a
            [ href "blog/"
            , class "px-4 flex items-center hover:bg-gray-50 hover:bg-opacity-20"
            , class " text-xl"
            ]
            [ Icons.blog
            , span [ class "ml-2 tracking-wide" ]
                [ text "Blog"
                ]
            ]
        , a
            [ target "_blank"
            , href "https://github.com/eikek/docspell"
            , class "px-4 flex items-center hover:bg-gray-50 hover:bg-opacity-20"
            , class " text-xl"
            ]
            [ Icons.github
            , span [ class "ml-2 tracking-wide" ]
                [ text "Github"
                ]
            ]
        ]


mainHero : Model -> Html Msg
mainHero _ =
    section
        [ id "hero-main"
        , class "min-h-screen text-white flex flex-col items-center main-background"
        ]
        [ navBar " text-white"
        , div [ class "flex-grow flex flex-col items-center justify-center w-full" ]
            [ Icons.logoWidth 112
            , h1 [ class "text-6xl font-semibold shadow font-serif" ]
                [ text "Docspell"
                ]
            , h2 [ class "text-3xl font-madium tracking-wide mt-2 mb-4 " ]
                [ text "Simple document organizer"
                ]
            , p [ class "px-2 text-center text-xl font-light shadow max-w-prose font-sans" ]
                [ text "Docspell assists in organizing your piles of "
                , text "digital documents, resulting from scanners, e-mails "
                , text "and other sources with minimal effort."
                ]
            , div
                [ class "mt-4 flex flex-col space-y-2 text-2xl"
                , class "sm:items-center sm:flex-row sm:space-y-0 sm:space-x-4"
                ]
                [ a
                    [ class "button info"
                    , href "#demos"
                    ]
                    [ text "Screencasts"
                    ]
                , a
                    [ class "button info"
                    , href "#feature-selection"
                    ]
                    [ text "Features"
                    ]
                , a
                    [ class "button primary"
                    , href "#get-started"
                    ]
                    [ text "Get Started"
                    ]
                ]
            ]
        , div [ class "text-right w-full" ]
            [ span [ class "opacity-40 text-xs" ]
                [ i [ class "fab fa-unsplash mr-1" ] []
                , text "Photo by "
                , a
                    [ href "https://unsplash.com/@numericcitizen"
                    , target "_blank"
                    ]
                    [ text "JF Martin"
                    ]
                ]
            ]
        ]
