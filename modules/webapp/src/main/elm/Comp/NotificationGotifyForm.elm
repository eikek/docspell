{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.NotificationGotifyForm exposing (Model, Msg, init, initWith, update, view)

import Api.Model.NotificationGotify exposing (NotificationGotify)
import Comp.Basic as B
import Data.NotificationChannel
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Messages.Comp.NotificationGotifyForm exposing (Texts)
import Styles as S


type alias Model =
    { hook : NotificationGotify
    }


init : Model
init =
    { hook = Data.NotificationChannel.setTypeGotify Api.Model.NotificationGotify.empty
    }


initWith : NotificationGotify -> Model
initWith hook =
    { hook = Data.NotificationChannel.setTypeGotify hook
    }


type Msg
    = SetUrl String
    | SetAppKey String



--- Update


update : Msg -> Model -> ( Model, Maybe NotificationGotify )
update msg model =
    let
        newHook =
            updateHook msg model.hook
    in
    ( { model | hook = newHook }, check newHook )


check : NotificationGotify -> Maybe NotificationGotify
check hook =
    Just hook


updateHook : Msg -> NotificationGotify -> NotificationGotify
updateHook msg hook =
    case msg of
        SetUrl s ->
            { hook | url = s }

        SetAppKey s ->
            { hook | appKey = s }



--- View


view : Texts -> Model -> Html Msg
view texts model =
    div []
        [ div
            [ class "mb-2"
            ]
            [ label
                [ for "gotifyurl"
                , class S.inputLabel
                ]
                [ text texts.gotifyUrl
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , onInput SetUrl
                , placeholder texts.gotifyUrl
                , value model.hook.url
                , name "gotifyurl"
                , class S.textInput
                ]
                []
            ]
        , div
            [ class "mb-2"
            ]
            [ label
                [ for "appkey"
                , class S.inputLabel
                ]
                [ text texts.appKey
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , onInput SetAppKey
                , placeholder texts.appKey
                , value model.hook.appKey
                , name "appkey"
                , class S.textInput
                ]
                []
            ]
        ]
