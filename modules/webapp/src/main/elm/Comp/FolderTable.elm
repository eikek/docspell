{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.FolderTable exposing
    ( Action(..)
    , Model
    , Msg
    , init
    , update
    , view2
    )

import Api.Model.FolderItem exposing (FolderItem)
import Comp.Basic as B
import Data.FolderOrder exposing (FolderOrder)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.Comp.FolderTable exposing (Texts)
import Styles as S


type alias Model =
    {}


type Msg
    = EditItem FolderItem
    | ToggleOrder FolderOrder


type Action
    = NoAction
    | EditAction FolderItem


type Header
    = Name
    | Owner


init : Model
init =
    {}


update : Msg -> Model -> ( Model, Action, Maybe FolderOrder )
update msg model =
    case msg of
        EditItem item ->
            ( model, EditAction item, Nothing )

        ToggleOrder order ->
            ( model, NoAction, Just order )


newOrder : Header -> FolderOrder -> FolderOrder
newOrder header current =
    case ( header, current ) of
        ( Name, Data.FolderOrder.NameAsc ) ->
            Data.FolderOrder.NameDesc

        ( Name, _ ) ->
            Data.FolderOrder.NameAsc

        ( Owner, Data.FolderOrder.OwnerAsc ) ->
            Data.FolderOrder.OwnerDesc

        ( Owner, _ ) ->
            Data.FolderOrder.OwnerAsc



--- View2


view2 : Texts -> FolderOrder -> Model -> List FolderItem -> Html Msg
view2 texts order _ items =
    let
        nameSortIcon =
            case order of
                Data.FolderOrder.NameAsc ->
                    "fa fa-sort-alpha-up"

                Data.FolderOrder.NameDesc ->
                    "fa fa-sort-alpha-down-alt"

                _ ->
                    "invisible fa fa-sort-alpha-up"

        ownerSortIcon =
            case order of
                Data.FolderOrder.OwnerAsc ->
                    "fa fa-sort-alpha-up"

                Data.FolderOrder.OwnerDesc ->
                    "fa fa-sort-alpha-down-alt"

                _ ->
                    "invisible fa fa-sort-alpha-up"
    in
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "w-px whitespace-nowrap pr-1 md:pr-3" ] []
                , th [ class "text-left" ]
                    [ a [ href "#", onClick (ToggleOrder <| newOrder Name order) ]
                        [ i [ class nameSortIcon, class "mr-1" ] []
                        , text texts.basics.name
                        ]
                    ]
                , th [ class "text-left hidden sm:table-cell" ]
                    [ a [ href "#", onClick (ToggleOrder <| newOrder Owner order) ]
                        [ i [ class ownerSortIcon, class "mr-1" ] []
                        , text texts.owner
                        ]
                    ]
                , th [ class "text-center" ]
                    [ span [ class "hidden sm:inline" ]
                        [ text texts.memberCount
                        ]
                    , span [ class "sm:hidden" ]
                        [ text "#"
                        ]
                    ]
                , th [ class "text-center" ]
                    [ text texts.basics.created
                    ]
                ]
            ]
        , tbody []
            (List.map (viewItem2 texts) items)
        ]


viewItem2 : Texts -> FolderItem -> Html Msg
viewItem2 texts item =
    tr
        [ class S.tableRow
        ]
        [ B.editLinkTableCell texts.basics.edit (EditItem item)
        , td [ class " py-4 md:py-2" ]
            [ text item.name
            , span
                [ classList [ ( "hidden", item.isMember ) ]
                ]
                [ span [ class "ml-1 text-red-700" ]
                    [ text "*"
                    ]
                ]
            ]
        , td [ class " py-4 md:py-2 hidden sm:table-cell" ]
            [ text item.owner.name
            ]
        , td [ class "text-center  py-4 md:py-2" ]
            [ String.fromInt item.memberCount
                |> text
            ]
        , td [ class "text-center  py-4 md:py-2" ]
            [ texts.formatDateShort item.created
                |> text
            ]
        ]
