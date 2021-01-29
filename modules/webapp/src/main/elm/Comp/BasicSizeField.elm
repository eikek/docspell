module Comp.BasicSizeField exposing
    ( Msg
    , update
    , view
    , view2
    )

import Data.BasicSize exposing (BasicSize)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck)
import Styles as S


type Msg
    = Toggle BasicSize


update : Msg -> Maybe BasicSize
update msg =
    case msg of
        Toggle bs ->
            Just bs



--- View


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



--- View2


view2 : String -> String -> BasicSize -> Html Msg
view2 classes labelTxt current =
    div [ class classes ]
        [ label [ class S.inputLabel ]
            [ text labelTxt ]
        , div [ class "flex flex-col" ]
            (List.map (makeField2 current) Data.BasicSize.all)
        ]


makeField2 : BasicSize -> BasicSize -> Html Msg
makeField2 current element =
    label [ class "inline-flex items-center" ]
        [ input
            [ type_ "radio"
            , checked (current == element)
            , onCheck (\_ -> Toggle element)
            , class S.radioInput
            ]
            []
        , span [ class "ml-2" ]
            [ text (Data.BasicSize.label element) ]
        ]
