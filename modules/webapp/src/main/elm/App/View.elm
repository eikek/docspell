module App.View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)

import App.Data exposing (..)
import Page exposing (Page(..))
import Page.Home.View
import Page.Login.View

view: Model -> Html Msg
view model =
    case model.page of
        LoginPage ->
            loginLayout model
        _ ->
            defaultLayout model

loginLayout: Model -> Html Msg
loginLayout model =
    div [class "login-layout"]
        [ (viewLogin model)
        , (footer model)
        ]

defaultLayout: Model -> Html Msg
defaultLayout model =
    div [class "default-layout"]
        [ div [class "ui fixed top sticky attached large menu black-bg"]
              [div [class "ui fluid container"]
                   [ a [class "header item narrow-item"
                       ,Page.href HomePage
                       ]
                         [i [classList [("lemon outline icon", True)
                                       ]]
                              []
                         ,text model.flags.config.appName]
                   , (loginInfo model)
                   ]
              ]
        , div [ class "ui fluid container main-content" ]
            [ (case model.page of
                   HomePage ->
                       viewHome model
                   LoginPage ->
                       viewLogin model
              )
            ]
        , (footer model)
        ]

viewLogin: Model -> Html Msg
viewLogin model =
    Html.map LoginMsg (Page.Login.View.view model.loginModel)

viewHome: Model -> Html Msg
viewHome model =
    Html.map HomeMsg (Page.Home.View.view model.homeModel)


loginInfo: Model -> Html Msg
loginInfo model =
    div [class "right menu"]
        (case model.flags.account of
            Just acc ->
                [a [class "item"
                   ]
                     [text "Profile"
                     ]
                ,a [class "item"
                   ,Page.href model.page
                   ,onClick Logout
                   ]
                     [text "Logout "
                     ,text (acc.collective ++ "/" ++ acc.user)
                     ]
                ]
            Nothing ->
                [a [class "item"
                   ,Page.href LoginPage
                   ]
                     [text "Login"
                     ]
                ]
        )

footer: Model -> Html Msg
footer model =
    div [ class "ui footer" ]
        [ a [href "https://github.com/eikek/docspell"]
              [ i [class "ui github icon"][]
              ]
        , span []
            [ text "Docspell "
            , text model.version.version
            , text " (#"
            , String.left 8 model.version.gitCommit |> text
            , text ")"
            ]
        ]
