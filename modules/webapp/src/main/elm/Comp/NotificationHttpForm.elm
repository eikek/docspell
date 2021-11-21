{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.NotificationHttpForm exposing (Model, Msg, init, initWith, update, view)

import Api.Model.NotificationHttp exposing (NotificationHttp)
import Comp.Basic as B
import Data.NotificationChannel
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Messages.Comp.NotificationHttpForm exposing (Texts)
import Styles as S


type alias Model =
    { hook : NotificationHttp
    }


init : Model
init =
    { hook =
        Data.NotificationChannel.setTypeHttp
            Api.Model.NotificationHttp.empty
    }


initWith : NotificationHttp -> Model
initWith hook =
    { hook = Data.NotificationChannel.setTypeHttp hook
    }


type Msg
    = SetUrl String



--- Update


update : Msg -> Model -> ( Model, Maybe NotificationHttp )
update msg model =
    let
        newHook =
            updateHook msg model.hook
    in
    ( { model | hook = newHook }, check newHook )


check : NotificationHttp -> Maybe NotificationHttp
check hook =
    if hook.url == "" then
        Nothing

    else
        Just hook


updateHook : Msg -> NotificationHttp -> NotificationHttp
updateHook msg hook =
    case msg of
        SetUrl s ->
            { hook | url = s }



--- View


view : Texts -> Model -> Html Msg
view texts model =
    div []
        [ div
            [ class "mb-2"
            ]
            [ label
                [ for "httpurl"
                , class S.inputLabel
                ]
                [ text texts.httpUrl
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , onInput SetUrl
                , placeholder texts.httpUrl
                , value model.hook.url
                , name "httpurl"
                , class S.textInput
                ]
                []
            ]
        ]
