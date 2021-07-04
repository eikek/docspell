{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Util.CustomField exposing
    ( boolValue
    , nameOrLabel
    , renderValue
    , renderValue2
    )

import Api.Model.ItemFieldValue exposing (ItemFieldValue)
import Data.CustomFieldType
import Data.Icons as Icons
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)


{-| This is how the server wants the value to a bool custom field
-}
boolValue : Bool -> String
boolValue b =
    if b then
        "true"

    else
        "false"


nameOrLabel : { r | name : String, label : Maybe String } -> String
nameOrLabel fv =
    Maybe.withDefault fv.name fv.label


renderValue : String -> ItemFieldValue -> Html msg
renderValue classes cv =
    renderValue2 [ ( classes, True ) ] Nothing cv


renderValue2 : List ( String, Bool ) -> Maybe msg -> ItemFieldValue -> Html msg
renderValue2 classes tagger cv =
    let
        renderBool =
            if cv.value == "true" then
                i [ class "fa fa-check" ] []

            else
                i [ class "fa fa-minus" ] []

        el : List (Html msg) -> Html msg
        el =
            case tagger of
                Just t ->
                    a
                        [ classList classes
                        , onClick t
                        , href "#"
                        ]

                Nothing ->
                    div [ classList classes ]
    in
    el
        [ Icons.customFieldTypeIconString2 "" cv.ftype
        , span [ class "ml-1 mr-2" ]
            [ nameOrLabel cv |> text
            ]
        , div [ class "detail" ]
            [ if Data.CustomFieldType.fromString cv.ftype == Just Data.CustomFieldType.Boolean then
                renderBool

              else
                text cv.value
            ]
        ]
