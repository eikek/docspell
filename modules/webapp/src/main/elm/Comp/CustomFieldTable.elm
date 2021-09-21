{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.CustomFieldTable exposing
    ( Action(..)
    , Model
    , Msg
    , init
    , update
    , view2
    )

import Api.Model.CustomField exposing (CustomField)
import Comp.Basic as B
import Data.CustomFieldOrder exposing (CustomFieldOrder)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.Comp.CustomFieldTable exposing (Texts)
import Styles as S


type alias Model =
    {}


type Msg
    = EditItem CustomField
    | ToggleOrder CustomFieldOrder


type Action
    = NoAction
    | EditAction CustomField


type Header
    = Label
    | Format


init : Model
init =
    {}


update : Msg -> Model -> ( Model, Action, Maybe CustomFieldOrder )
update msg model =
    case msg of
        EditItem item ->
            ( model, EditAction item, Nothing )

        ToggleOrder order ->
            ( model, NoAction, Just order )


newOrder : Header -> CustomFieldOrder -> CustomFieldOrder
newOrder header current =
    case ( header, current ) of
        ( Label, Data.CustomFieldOrder.LabelAsc ) ->
            Data.CustomFieldOrder.LabelDesc

        ( Label, _ ) ->
            Data.CustomFieldOrder.LabelAsc

        ( Format, Data.CustomFieldOrder.FormatAsc ) ->
            Data.CustomFieldOrder.FormatDesc

        ( Format, _ ) ->
            Data.CustomFieldOrder.FormatAsc



--- View2


view2 : Texts -> CustomFieldOrder -> Model -> List CustomField -> Html Msg
view2 texts order _ items =
    let
        labelSortIcon =
            case order of
                Data.CustomFieldOrder.LabelAsc ->
                    "fa fa-sort-alpha-up"

                Data.CustomFieldOrder.LabelDesc ->
                    "fa fa-sort-alpha-down-alt"

                _ ->
                    "invisible fa fa-sort-alpha-up"

        formatSortIcon =
            case order of
                Data.CustomFieldOrder.FormatAsc ->
                    "fa fa-sort-alpha-up"

                Data.CustomFieldOrder.FormatDesc ->
                    "fa fa-sort-alpha-down-alt"

                _ ->
                    "invisible fa fa-sort-alpha-up"
    in
    div []
        [ table [ class S.tableMain ]
            [ thead []
                [ tr []
                    [ th [] []
                    , th [ class "text-left" ]
                        [ a [ href "#", onClick (ToggleOrder <| newOrder Label order) ]
                            [ i [ class labelSortIcon, class "mr-1" ] []
                            , text texts.nameLabel
                            ]
                        ]
                    , th [ class "text-left" ]
                        [ a [ href "#", onClick (ToggleOrder <| newOrder Format order) ]
                            [ i [ class formatSortIcon, class "mr-1" ] []
                            , text texts.format
                            ]
                        ]
                    , th [ class "text-center hidden sm:table-cell" ] [ text texts.usageCount ]
                    , th [ class "text-center hidden sm:table-cell" ] [ text texts.basics.created ]
                    ]
                ]
            , tbody []
                (List.map (viewItem2 texts) items)
            ]
        ]


viewItem2 : Texts -> CustomField -> Html Msg
viewItem2 texts item =
    tr [ class S.tableRow ]
        [ B.editLinkTableCell texts.basics.edit (EditItem item)
        , td [ class "text-left py-4 md:py-2 pr-2" ]
            [ text <| Maybe.withDefault item.name item.label
            ]
        , td [ class "text-left py-4 md:py-2 pr-2" ]
            [ text item.ftype
            ]
        , td [ class "text-center py-4 md:py-2 sm:pr-2 hidden sm:table-cell" ]
            [ String.fromInt item.usages
                |> text
            ]
        , td [ class "text-center py-4 md:py-2 hidden sm:table-cell" ]
            [ texts.formatDateShort item.created
                |> text
            ]
        ]
