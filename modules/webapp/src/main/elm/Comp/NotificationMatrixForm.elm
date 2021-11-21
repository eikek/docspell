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


type alias Model =
    { hook : NotificationMatrix
    }


init : Model
init =
    { hook = Data.NotificationChannel.setTypeMatrix Api.Model.NotificationMatrix.empty
    }


initWith : NotificationMatrix -> Model
initWith hook =
    { hook = Data.NotificationChannel.setTypeMatrix hook
    }


type Msg
    = SetHomeServer String
    | SetRoomId String
    | SetAccessKey String



--- Update


update : Msg -> Model -> ( Model, Maybe NotificationMatrix )
update msg model =
    let
        newHook =
            updateHook msg model.hook
    in
    ( { model | hook = newHook }, check newHook )


check : NotificationMatrix -> Maybe NotificationMatrix
check hook =
    Just hook


updateHook : Msg -> NotificationMatrix -> NotificationMatrix
updateHook msg hook =
    case msg of
        SetHomeServer s ->
            { hook | homeServer = s }

        SetRoomId s ->
            { hook | roomId = s }

        SetAccessKey s ->
            { hook | accessToken = s }



--- View


view : Texts -> Model -> Html Msg
view texts model =
    div []
        [ div
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
                , value model.hook.homeServer
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
                , value model.hook.roomId
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
                , value model.hook.accessToken
                , name "accesskey"
                , class S.textAreaInput
                ]
                []
            ]
        ]
