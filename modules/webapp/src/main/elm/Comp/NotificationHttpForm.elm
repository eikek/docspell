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
import Util.Maybe


type alias Model =
    { channel : NotificationHttp
    }


init : Model
init =
    { channel =
        Data.NotificationChannel.setTypeHttp
            Api.Model.NotificationHttp.empty
    }


initWith : NotificationHttp -> Model
initWith channel =
    { channel = Data.NotificationChannel.setTypeHttp channel
    }


type Msg
    = SetUrl String
    | SetName String



--- Update


update : Msg -> Model -> ( Model, Maybe NotificationHttp )
update msg model =
    let
        newChannel =
            updateChannel msg model.channel
    in
    ( { model | channel = newChannel }, check newChannel )


check : NotificationHttp -> Maybe NotificationHttp
check channel =
    if channel.url == "" then
        Nothing

    else
        Just channel


updateChannel : Msg -> NotificationHttp -> NotificationHttp
updateChannel msg channel =
    case msg of
        SetUrl s ->
            { channel | url = s }

        SetName s ->
            { channel | name = Util.Maybe.fromString s }



--- View


view : Texts -> Model -> Html Msg
view texts model =
    div []
        [ div
            [ class "mb-2"
            ]
            [ label
                [ for "name"
                , class S.inputLabel
                ]
                [ text texts.basics.name
                ]
            , input
                [ type_ "text"
                , onInput SetName
                , placeholder texts.basics.name
                , value (Maybe.withDefault "" model.channel.name)
                , name "name"
                , class S.textInput
                ]
                []
            ]
        , div
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
                , value model.channel.url
                , name "httpurl"
                , class S.textInput
                ]
                []
            ]
        ]
