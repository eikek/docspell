module Comp.FieldListSelect exposing (..)

import Data.Fields exposing (Field)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck)


type alias Model =
    List Field


type Msg
    = Toggle Field



--- Update


update : Msg -> Model -> Model
update msg model =
    case msg of
        Toggle field ->
            if List.member field model then
                removeField model field

            else
                addField model field


removeField : Model -> Field -> Model
removeField selected field =
    List.filter (\f -> f /= field) selected
        |> Data.Fields.sort


addField : Model -> Field -> Model
addField selected field =
    Data.Fields.sort (field :: selected)



--- View


view : Model -> Html Msg
view selected =
    div [ class "grouped fields" ]
        (List.map (fieldCheckbox selected) Data.Fields.all)


fieldCheckbox : Model -> Field -> Html Msg
fieldCheckbox selected field =
    let
        isChecked =
            List.member field selected
    in
    div [ class "field" ]
        [ div [ class "ui checkbox" ]
            [ input
                [ type_ "checkbox"
                , checked isChecked
                , onCheck (\_ -> Toggle field)
                ]
                []
            , label [] [ text (Data.Fields.label field) ]
            ]
        ]
