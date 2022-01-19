{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.NotificationMatrixForm exposing (Model, Msg, init, initWith, update, view)

import Api.Model.NotificationMatrix exposing (NotificationMatrix)
import Comp.Basic as B
import Data.NotificationChannel
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Messages.Comp.NotificationMatrixForm exposing (Texts)
import Styles as S
import Util.Maybe


type alias Model =
    { channel : NotificationMatrix
    }


init : Model
init =
    { channel = Data.NotificationChannel.setTypeMatrix Api.Model.NotificationMatrix.empty
    }


initWith : NotificationMatrix -> Model
initWith channel =
    { channel = Data.NotificationChannel.setTypeMatrix channel
    }


type Msg
    = SetHomeServer String
    | SetRoomId String
    | SetAccessKey String
    | SetName String



--- Update


update : Msg -> Model -> ( Model, Maybe NotificationMatrix )
update msg model =
    let
        newChannel =
            updateChannel msg model.channel
    in
    ( { model | channel = newChannel }, check newChannel )


check : NotificationMatrix -> Maybe NotificationMatrix
check channel =
    Just channel


updateChannel : Msg -> NotificationMatrix -> NotificationMatrix
updateChannel msg channel =
    case msg of
        SetHomeServer s ->
            { channel | homeServer = s }

        SetRoomId s ->
            { channel | roomId = s }

        SetAccessKey s ->
            { channel | accessToken = s }

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
                [ for "homeserver"
                , class S.inputLabel
                ]
                [ text texts.homeServer
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , onInput SetHomeServer
                , placeholder texts.homeServer
                , value model.channel.homeServer
                , name "homeserver"
                , class S.textInput
                ]
                []
            ]
        , div
            [ class "mb-2"
            ]
            [ label
                [ for "roomid"
                , class S.inputLabel
                ]
                [ text texts.roomId
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , onInput SetRoomId
                , placeholder texts.roomId
                , value model.channel.roomId
                , name "roomid"
                , class S.textInput
                ]
                []
            ]
        , div
            [ class "mb-2"
            ]
            [ label
                [ for "accesskey"
                , class S.inputLabel
                ]
                [ text texts.accessKey
                , B.inputRequired
                ]
            , textarea
                [ onInput SetAccessKey
                , placeholder texts.accessKey
                , value model.channel.accessToken
                , name "accesskey"
                , class S.textAreaInput
                ]
                []
            ]
        ]
