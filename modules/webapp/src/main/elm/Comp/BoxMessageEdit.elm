{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.BoxMessageEdit exposing (Model, Msg, init, update, view)

import Data.BoxContent exposing (MessageData)
import Html exposing (Html, div, input, label, text, textarea)
import Html.Attributes exposing (autocomplete, class, name, placeholder, type_, value)
import Html.Events exposing (onInput)
import Messages.Comp.BoxMessageEdit exposing (Texts)
import Styles as S


type alias Model =
    { data : MessageData
    }


type Msg
    = SetTitle String
    | SetBody String


init : MessageData -> Model
init data =
    { data = data
    }



--- Update


update : Msg -> Model -> ( Model, MessageData )
update msg model =
    case msg of
        SetTitle str ->
            let
                data =
                    model.data

                data_ =
                    { data | title = str }
            in
            ( { model | data = data_ }, data_ )

        SetBody str ->
            let
                data =
                    model.data

                data_ =
                    { data | body = str }
            in
            ( { model | data = data_ }, data_ )



--- View


view : Texts -> Model -> Html Msg
view texts model =
    div []
        [ div []
            [ label [ class S.inputLabel ]
                [ text texts.titleLabel
                ]
            , input
                [ type_ "text"
                , name "message-title"
                , autocomplete False
                , onInput SetTitle
                , value model.data.title
                , placeholder texts.titlePlaceholder
                , class S.textInput
                ]
                []
            ]
        , div [ class "mt-2" ]
            [ label [ class S.inputLabel ]
                [ text texts.bodyLabel
                ]
            , textarea
                [ value model.data.body
                , onInput SetBody
                , class S.textAreaInput
                , placeholder texts.bodyPlaceholder
                ]
                []
            ]
        , div [ class "opacity-75 text-sm mt-1" ]
            [ text texts.infoText
            ]
        ]
