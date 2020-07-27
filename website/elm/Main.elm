module Main exposing (..)

import Browser exposing (Document)
import Browser.Navigation exposing (Key)
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
        []
        [ mainHero model
        , featureHero model
        , section [ class "section" ]
            [ div [ class "container" ]
                (List.indexedMap Feature.featureBox model.features
                    ++ [ div [ class "columns box" ]
                            [ div [ class "column is-full" ]
                                [ div [ class "content has-text-centered is-medium" ]
                                    [ text "A more complete list can be found in "
                                    , a [ href "/docs/features" ] [ text "here" ]
                                    , text "."
                                    ]
                                ]
                            ]
                       ]
                )
            ]
        , getStartedHero model
        , div [ class "section" ]
            (GetStarted.getStarted model.flags.version)
        , footHero model
        ]


footHero : Model -> Html Msg
footHero model =
    footer
        [ id "footer"
        , class "footer"
        ]
        [ div [ class "has-text-centered" ]
            [ span []
                [ text ("Docspell, " ++ model.flags.version)
                ]
            , span [ class "pr-1 pl-1" ]
                [ text " • "
                ]
            , a
                [ href "https://spdx.org/licenses/GPL-3.0-or-later.html"
                , target "_blank"
                ]
                [ text "GPLv3+"
                ]
            , span [ class "pr-1 pl-1" ]
                [ text " • "
                ]
            , a
                [ href "https://github.com/eikek/docspell"
                , target "_blank"
                ]
                [ text "Source Code"
                ]
            , span [ class "pr-1 pl-1" ]
                [ text " • "
                ]
            , span []
                [ text "© 2020 "
                ]
            , a
                [ href "https://github.com/eikek"
                , target "_blank"
                ]
                [ text "@eikek"
                ]
            ]
        ]


getStartedHero : Model -> Html Msg
getStartedHero _ =
    section
        [ id "get-started"
        , class "hero is-primary is-bold"
        ]
        [ div [ class "hero-body" ]
            [ div [ class "container" ]
                [ h2 [ class "title" ]
                    [ text "Get Started"
                    ]
                ]
            ]
        ]


featureHero : Model -> Html Msg
featureHero model =
    section
        [ id "feature-selection"
        , class "hero is-info is-bold"
        ]
        [ div
            [ class "hero-body"
            ]
            [ div [ class "container" ]
                [ h2 [ class "title" ]
                    [ text "Feature Selection"
                    ]
                ]
            ]
        ]


mainHero : Model -> Html Msg
mainHero model =
    section
        [ id "hero-main"
        , class "hero is-fullheight is-primary"
        ]
        [ div [ class "hero-head" ]
            [ nav [ class "navbar" ]
                [ div [ class "navbar-brand" ]
                    [ a
                        [ class "navbar-item"
                        , href "/"
                        ]
                        [ span [ class "icon is-large" ]
                            [ Icons.logo
                            ]
                        , text "Docspell"
                        ]
                    , a
                        [ role "button"
                        , onClick ToggleNavbarMenu
                        , classList
                            [ ( "navbar-burger", True )
                            , ( "is-active", model.navbarOpen )
                            ]
                        , ariaLabel "menu"
                        , ariaExpanded False
                        ]
                        [ span [ ariaHidden True ] []
                        , span [ ariaHidden True ] []
                        , span [ ariaHidden True ] []
                        ]
                    ]
                , div
                    [ classList
                        [ ( "navbar-menu", True )
                        , ( "is-active", model.navbarOpen )
                        ]
                    ]
                    [ div [ class "navbar-start" ]
                        [ a
                            [ href "docs/"
                            , class "navbar-item"
                            ]
                            [ span [ class "icon" ]
                                [ Icons.docs
                                ]
                            , span []
                                [ text "Documentation"
                                ]
                            ]
                        , a
                            [ target "_blank"
                            , href "https://github.com/eikek/docspell"
                            , class "navbar-item"
                            ]
                            [ span [ class "icon" ]
                                [ Icons.github
                                ]
                            , span []
                                [ text "Github"
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        , div [ class "hero-body" ]
            [ div
                [ class "container has-text-centered"
                ]
                [ Icons.logoWidth 112
                , h1 [ class "title main-title is-2" ]
                    [ text "Docspell"
                    ]
                , h2 [ class "subtitle is-3" ]
                    [ text "Simple document organizer"
                    ]
                , p [ class "content is-medium" ]
                    [ text "Docspell can assist in organizing your piles of "
                    , text "digital documents, resulting from scanners, e-mails "
                    , text "and other sources with miminal effort."
                    ]
                , div [ class " buttons is-centered" ]
                    [ a
                        [ class "button is-primary is-medium"
                        , href "#get-started"
                        ]
                        [ text "Get Started"
                        ]
                    , a
                        [ class "button is-info is-medium"
                        , href "#feature-selection"
                        ]
                        [ text "Features"
                        ]
                    ]
                ]
            ]
        ]
