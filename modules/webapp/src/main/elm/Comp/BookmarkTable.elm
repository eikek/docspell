{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.BookmarkTable exposing
    ( Msg(..)
    , SelectAction(..)
    , update
    , view
    )

import Api.Model.BookmarkedQuery exposing (BookmarkedQuery)
import Comp.Basic as B
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Comp.BookmarkTable exposing (Texts)
import Styles as S


type Msg
    = Select BookmarkedQuery


type SelectAction
    = Edit BookmarkedQuery


update : Msg -> SelectAction
update msg =
    case msg of
        Select share ->
            Edit share



--- View


view : Texts -> List BookmarkedQuery -> Html Msg
view texts bms =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "" ] []
                , th [ class "text-left" ]
                    [ text texts.basics.name
                    ]
                ]
            ]
        , tbody []
            (List.map (renderBookmarkLine texts) bms)
        ]


renderBookmarkLine : Texts -> BookmarkedQuery -> Html Msg
renderBookmarkLine texts bm =
    tr
        [ class S.tableRow
        ]
        [ B.editLinkTableCell texts.basics.edit (Select bm)
        , td [ class "text-left py-4 md:py-2" ]
            [ text bm.name
            ]
        ]
