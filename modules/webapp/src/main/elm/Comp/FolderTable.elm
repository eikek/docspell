{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
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
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Comp.FolderTable exposing (Texts)
import Styles as S


type alias Model =
    {}


type Msg
    = EditItem FolderItem


type Action
    = NoAction
    | EditAction FolderItem


init : Model
init =
    {}


update : Msg -> Model -> ( Model, Action )
update msg model =
    case msg of
        EditItem item ->
            ( model, EditAction item )



--- View2


view2 : Texts -> Model -> List FolderItem -> Html Msg
view2 texts _ items =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "w-px whitespace-nowrap pr-1 md:pr-3" ] []
                , th [ class "text-left" ]
                    [ text texts.basics.name
                    ]
                , th [ class "text-left hidden sm:table-cell" ] [ text "Owner" ]
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
