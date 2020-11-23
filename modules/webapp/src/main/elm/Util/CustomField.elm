module Util.CustomField exposing (renderValue)

import Api.Model.ItemFieldValue exposing (ItemFieldValue)
import Data.CustomFieldType
import Data.Icons as Icons
import Html exposing (..)
import Html.Attributes exposing (..)


renderValue : String -> ItemFieldValue -> Html msg
renderValue classes cv =
    let
        renderBool =
            if cv.value == "true" then
                i [ class "check icon" ] []

            else
                i [ class "minus icon" ] []
    in
    div [ class classes ]
        [ Icons.customFieldTypeIconString "" cv.ftype
        , Maybe.withDefault cv.name cv.label |> text
        , div [ class "detail" ]
            [ if Data.CustomFieldType.fromString cv.ftype == Just Data.CustomFieldType.Boolean then
                renderBool

              else
                text cv.value
            ]
        ]
