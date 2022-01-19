{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.NotificationGotifyForm exposing (Model, Msg, init, initWith, update, view)

import Api.Model.NotificationGotify exposing (NotificationGotify)
import Comp.Basic as B
import Comp.FixedDropdown
import Data.DropdownStyle
import Data.NotificationChannel
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Messages.Comp.NotificationGotifyForm exposing (Texts)
import Styles as S
import Util.Maybe


type alias Model =
    { channel : NotificationGotify
    , prioModel : Comp.FixedDropdown.Model Int
    }


init : Model
init =
    { channel = Data.NotificationChannel.setTypeGotify Api.Model.NotificationGotify.empty
    , prioModel = Comp.FixedDropdown.init (List.range 0 10)
    }


initWith : NotificationGotify -> Model
initWith channel =
    { channel = Data.NotificationChannel.setTypeGotify channel
    , prioModel = Comp.FixedDropdown.init (List.range 0 10)
    }


type Msg
    = SetUrl String
    | SetAppKey String
    | SetName String
    | PrioMsg (Comp.FixedDropdown.Msg Int)



--- Update


update : Msg -> Model -> ( Model, Maybe NotificationGotify )
update msg model =
    let
        channel =
            model.channel

        newModel =
            case msg of
                SetUrl s ->
                    { model | channel = { channel | url = s } }

                SetAppKey s ->
                    { model | channel = { channel | appKey = s } }

                SetName s ->
                    { model | channel = { channel | name = Util.Maybe.fromString s } }

                PrioMsg lm ->
                    let
                        ( m, sel ) =
                            Comp.FixedDropdown.update lm model.prioModel
                    in
                    { model | channel = { channel | priority = sel }, prioModel = m }
    in
    ( newModel, check newModel.channel )


check : NotificationGotify -> Maybe NotificationGotify
check channel =
    Just channel



--- View


view : Texts -> Model -> Html Msg
view texts model =
    let
        cfg =
            { display = String.fromInt
            , icon = \n -> Nothing
            , selectPlaceholder = texts.priority
            , style = Data.DropdownStyle.mainStyle
            }
    in
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
                , value model.channel.url
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
                , value model.channel.appKey
                , name "appkey"
                , class S.textInput
                ]
                []
            ]
        , div
            [ class "mb-2"
            ]
            [ label
                [ for "prio"
                , class S.inputLabel
                ]
                [ text texts.priority
                ]
            , Html.map PrioMsg (Comp.FixedDropdown.viewStyled2 cfg False model.channel.priority model.prioModel)
            , span [ class "text-sm opacity-75" ]
                [ text texts.priorityInfo
                ]
            ]
        ]
