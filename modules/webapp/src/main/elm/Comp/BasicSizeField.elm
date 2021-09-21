{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.BasicSizeField exposing
    ( Msg
    , update
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
