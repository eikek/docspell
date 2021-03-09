module Comp.SearchStatsView exposing
    ( nameOrLabel
    , sortFields
    , view2
    )

import Api.Model.FieldStats exposing (FieldStats)
import Api.Model.SearchStats exposing (SearchStats)
import Comp.Basic as B
import Data.Icons as Icons
import Data.Money
import Html exposing (..)
import Html.Attributes exposing (..)
import Styles as S


nameOrLabel : FieldStats -> String
nameOrLabel f =
    Maybe.withDefault f.name f.label


sortFields : List FieldStats -> List FieldStats
sortFields fields =
    List.sortBy nameOrLabel fields



--- View2


view2 : String -> SearchStats -> Html msg
view2 classes stats =
    let
        isNumField f =
            f.sum > 0

        statValues f =
            tr [ class "border-0 border-t  dark:border-bluegray-600" ]
                [ td [ class "text-left text-sm" ]
                    [ div
                        [ class S.basicLabel
                        , class "max-w-min"
                        ]
                        [ Icons.customFieldTypeIconString2 "" f.ftype
                        , span [ class "pl-2" ]
                            [ text (nameOrLabel f)
                            ]
                        ]
                    ]
                , td [ class "text-center py-2" ]
                    [ f.count |> String.fromInt |> text
                    ]
                , td [ class "text-center py-2" ]
                    [ f.sum |> Data.Money.format |> text
                    ]
                , td [ class "text-center py-2 hidden md:table-cell" ]
                    [ f.avg |> Data.Money.format |> text
                    ]
                , td [ class "text-center py-2 hidden md:table-cell" ]
                    [ f.min |> Data.Money.format |> text
                    ]
                , td [ class "text-center py-2 hidden md:table-cell" ]
                    [ f.max |> Data.Money.format |> text
                    ]
                ]

        fields =
            List.filter isNumField stats.fieldStats
                |> sortFields
    in
    div [ class classes ]
        [ div [ class "flex flex-col md:flex-row" ]
            [ div [ class "px-8 py-4" ]
                [ B.stats
                    { rootClass = ""
                    , valueClass = "text-4xl"
                    , value = String.fromInt stats.count
                    , label = "Items"
                    }
                ]
            , div [ class "flex-grow" ]
                [ table
                    [ class "w-full text-sm"
                    , classList [ ( "hidden", List.isEmpty fields ) ]
                    ]
                    [ thead []
                        [ tr [ class "" ]
                            [ th [ class "py-2 text-left" ] []
                            , th [ class "py-2 text-center" ]
                                [ text "Count" ]
                            , th [ class "py-2 text-center" ]
                                [ text "Sum" ]
                            , th [ class "py-2 text-center hidden md:table-cell" ]
                                [ text "Avg" ]
                            , th [ class "py-2 text-center hidden md:table-cell" ]
                                [ text "Min" ]
                            , th [ class "py-2 text-center hidden md:table-cell" ]
                                [ text "Max" ]
                            ]
                        ]
                    , tbody []
                        (List.map statValues fields)
                    ]
                ]
            ]
        ]
