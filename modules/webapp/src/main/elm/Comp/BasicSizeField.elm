module Comp.BasicSizeField exposing (Msg, update, view)

import Data.BasicSize exposing (BasicSize)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck)


type Msg
    = Toggle BasicSize


update : Msg -> Maybe BasicSize
update msg =
    case msg of
        Toggle bs ->
            Just bs


view : String -> BasicSize -> Html Msg
view labelTxt current =
    div [ class "grouped fields" ]
        (label [] [ text labelTxt ]
            :: List.map (makeField current) Data.BasicSize.all
        )


makeField : BasicSize -> BasicSize -> Html Msg
makeField current element =
    div [ class "field" ]
        [ div [ class "ui radio checkbox" ]
            [ input
                [ type_ "radio"
                , checked (current == element)
                , onCheck (\_ -> Toggle element)
                ]
                []
            , label [] [ text (Data.BasicSize.label element) ]
            ]
        ]
