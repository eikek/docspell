module Comp.FieldListSelect exposing
    ( Model
    , Msg
    , update
    , view2
    )

import Comp.MenuBar as MB
import Data.Fields exposing (Field)
import Html exposing (..)
import Html.Attributes exposing (..)


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



--- View2


view2 : String -> Model -> Html Msg
view2 classes selected =
    div
        [ class "flex flex-col space-y-4 md:space-y-2"
        , class classes
        ]
        (List.map (fieldCheckbox2 selected) Data.Fields.all)


fieldCheckbox2 : Model -> Field -> Html Msg
fieldCheckbox2 selected field =
    let
        isChecked =
            List.member field selected
    in
    MB.viewItem <|
        MB.Checkbox
            { id = "field-toggle-" ++ Data.Fields.toString field
            , value = isChecked
            , tagger = \_ -> Toggle field
            , label = Data.Fields.label field
            }
