module Comp.SearchStatsView exposing
    ( nameOrLabel
    , sortFields
    , view
    )

import Api.Model.FieldStats exposing (FieldStats)
import Api.Model.SearchStats exposing (SearchStats)
import Data.Icons as Icons
import Data.Money
import Html exposing (..)
import Html.Attributes exposing (..)


nameOrLabel : FieldStats -> String
nameOrLabel f =
    Maybe.withDefault f.name f.label


view : SearchStats -> List (Html msg)
view stats =
    let
        isNumField f =
            f.sum > 0

        statValues f =
            tr [ class "center aligned" ]
                [ td [ class "left aligned" ]
                    [ div [ class "ui basic label" ]
                        [ Icons.customFieldTypeIconString "" f.ftype
                        , text (nameOrLabel f)
                        ]
                    ]
                , td []
                    [ f.count |> String.fromInt |> text
                    ]
                , td []
                    [ f.sum |> Data.Money.format |> text
                    ]
                , td []
                    [ f.avg |> Data.Money.format |> text
                    ]
                , td []
                    [ f.min |> Data.Money.format |> text
                    ]
                , td []
                    [ f.max |> Data.Money.format |> text
                    ]
                ]

        fields =
            List.filter isNumField stats.fieldStats
                |> sortFields
    in
    [ div [ class "ui container" ]
        [ div [ class "ui middle aligned stackable grid" ]
            [ div [ class "three wide center aligned column" ]
                [ div [ class "ui small statistic" ]
                    [ div [ class "value" ]
                        [ String.fromInt stats.count |> text
                        ]
                    , div [ class "label" ]
                        [ text "Items"
                        ]
                    ]
                ]
            , div [ class "thirteen wide column" ]
                [ table [ class "ui very basic tiny six column table" ]
                    [ thead []
                        [ tr [ class "center aligned" ]
                            [ th [] []
                            , th [] [ text "Count" ]
                            , th [] [ text "Sum" ]
                            , th [] [ text "Avg" ]
                            , th [] [ text "Min" ]
                            , th [] [ text "Max" ]
                            ]
                        ]
                    , tbody []
                        (List.map statValues fields)
                    ]
                ]
            ]
        ]
    ]


sortFields : List FieldStats -> List FieldStats
sortFields fields =
    List.sortBy nameOrLabel fields
