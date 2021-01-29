module Util.CustomField exposing
    ( nameOrLabel
    , renderValue
    , renderValue1
    , renderValue2
    )

import Api.Model.ItemFieldValue exposing (ItemFieldValue)
import Data.CustomFieldType
import Data.Icons as Icons
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)


nameOrLabel : { r | name : String, label : Maybe String } -> String
nameOrLabel fv =
    Maybe.withDefault fv.name fv.label


renderValue : String -> ItemFieldValue -> Html msg
renderValue classes cv =
    renderValue1 [ ( classes, True ) ] Nothing cv


renderValue1 : List ( String, Bool ) -> Maybe msg -> ItemFieldValue -> Html msg
renderValue1 classes tagger cv =
    let
        renderBool =
            if cv.value == "true" then
                i [ class "check icon" ] []

            else
                i [ class "minus icon" ] []

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
        [ Icons.customFieldTypeIconString "" cv.ftype
        , nameOrLabel cv |> text
        , div [ class "detail" ]
            [ if Data.CustomFieldType.fromString cv.ftype == Just Data.CustomFieldType.Boolean then
                renderBool

              else
                text cv.value
            ]
        ]


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
