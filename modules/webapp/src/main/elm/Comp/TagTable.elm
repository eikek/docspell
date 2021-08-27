{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Comp.TagTable exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view2
    )

import Api.Model.Tag exposing (Tag)
import Comp.Basic as B
import Data.Flags exposing (Flags)
import Data.TagOrder exposing (TagOrder)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.Comp.TagTable exposing (Texts)
import Styles as S


type alias Model =
    { tags : List Tag
    , selected : Maybe Tag
    }


emptyModel : Model
emptyModel =
    { tags = []
    , selected = Nothing
    }


type Header
    = Name
    | Category


type Msg
    = SetTags (List Tag)
    | Select Tag
    | Deselect
    | SortClick TagOrder


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Maybe TagOrder )
update _ msg model =
    case msg of
        SetTags list ->
            ( { model | tags = list, selected = Nothing }, Cmd.none, Nothing )

        Select tag ->
            ( { model | selected = Just tag }, Cmd.none, Nothing )

        Deselect ->
            ( { model | selected = Nothing }, Cmd.none, Nothing )

        SortClick order ->
            ( model, Cmd.none, Just order )


newOrder : Header -> TagOrder -> TagOrder
newOrder header current =
    case ( header, current ) of
        ( Name, Data.TagOrder.NameAsc ) ->
            Data.TagOrder.NameDesc

        ( Name, Data.TagOrder.NameDesc ) ->
            Data.TagOrder.NameAsc

        ( Name, Data.TagOrder.CategoryAsc ) ->
            Data.TagOrder.NameAsc

        ( Name, Data.TagOrder.CategoryDesc ) ->
            Data.TagOrder.NameAsc

        ( Category, Data.TagOrder.NameAsc ) ->
            Data.TagOrder.CategoryAsc

        ( Category, Data.TagOrder.NameDesc ) ->
            Data.TagOrder.CategoryAsc

        ( Category, Data.TagOrder.CategoryAsc ) ->
            Data.TagOrder.CategoryDesc

        ( Category, Data.TagOrder.CategoryDesc ) ->
            Data.TagOrder.CategoryAsc



--- View2


view2 : Texts -> TagOrder -> Model -> Html Msg
view2 texts order model =
    let
        nameSortIcon =
            case order of
                Data.TagOrder.NameAsc ->
                    "fa fa-sort-alpha-up"

                Data.TagOrder.NameDesc ->
                    "fa fa-sort-alpha-down-alt"

                _ ->
                    "invisible fa fa-sort-alpha-down"

        catSortIcon =
            case order of
                Data.TagOrder.CategoryAsc ->
                    "fa fa-sort-alpha-up"

                Data.TagOrder.CategoryDesc ->
                    "fa fa-sort-alpha-down-alt"

                _ ->
                    "invisible fa fa-sort-alpha-down"
    in
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "" ] []
                , th [ class "text-left" ]
                    [ a [ href "#", onClick (SortClick <| newOrder Name order) ]
                        [ i [ class nameSortIcon, class "mr-1" ] []
                        , text texts.basics.name
                        ]
                    ]
                , th [ class "text-left" ]
                    [ a [ href "#", onClick (SortClick <| newOrder Category order) ]
                        [ i [ class catSortIcon, class "mr-1" ]
                            []
                        , text texts.category
                        ]
                    ]
                ]
            ]
        , tbody []
            (List.map (renderTagLine2 texts model) model.tags)
        ]


renderTagLine2 : Texts -> Model -> Tag -> Html Msg
renderTagLine2 texts model tag =
    tr
        [ classList [ ( "active", model.selected == Just tag ) ]
        , class S.tableRow
        ]
        [ B.editLinkTableCell texts.basics.edit (Select tag)
        , td [ class "text-left py-4 md:py-2" ]
            [ text tag.name
            ]
        , td [ class "text-left py-4 md:py-2" ]
            [ Maybe.withDefault "-" tag.category |> text
            ]
        ]
