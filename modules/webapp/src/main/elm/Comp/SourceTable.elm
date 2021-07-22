{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Comp.SourceTable exposing
    ( Msg
    , SelectMode(..)
    , isEdit
    , update
    , view2
    )

import Api.Model.SourceAndTags exposing (SourceAndTags)
import Comp.Basic as B
import Data.Flags exposing (Flags)
import Data.Priority
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Comp.SourceTable exposing (Texts)
import Styles as S
import Util.Html


type SelectMode
    = Edit SourceAndTags
    | Display SourceAndTags
    | None


isEdit : SelectMode -> Bool
isEdit m =
    case m of
        Edit _ ->
            True

        Display _ ->
            False

        None ->
            False


type Msg
    = Select SourceAndTags
    | Show SourceAndTags


update : Flags -> Msg -> ( Cmd Msg, SelectMode )
update _ msg =
    case msg of
        Select source ->
            ( Cmd.none, Edit source )

        Show source ->
            ( Cmd.none, Display source )



--- View2


view2 : Texts -> List SourceAndTags -> Html Msg
view2 texts sources =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "" ] []
                , th [ class "text-left" ] [ text texts.abbrev ]
                , th [ class "px-2 text-center" ] [ text texts.enabled ]
                , th [ class "hidden md:table-cell" ] [ text texts.counter ]
                , th [ class "hidden md:table-cell" ] [ text texts.priority ]
                , th [ class "hidden sm:table-cell" ] [ text texts.id ]
                ]
            ]
        , tbody []
            (List.map (renderSourceLine2 texts) sources)
        ]


renderSourceLine2 : Texts -> SourceAndTags -> Html Msg
renderSourceLine2 texts source =
    tr
        [ class S.tableRow ]
        [ td [ class S.editLinkTableCellStyle ]
            [ div
                [ class "inline-flex space-x-2"
                ]
                [ B.editLinkLabel texts.basics.edit (Select source)
                , B.linkLabel
                    { label = texts.show
                    , icon = "fa fa-eye"
                    , handler = Show source
                    , disabled = not source.source.enabled
                    }
                ]
            ]
        , td [ class "text-left" ]
            [ text source.source.abbrev
            ]
        , td [ class "w-px px-2 text-center" ]
            [ Util.Html.checkbox2 source.source.enabled
            ]
        , td [ class "text-center hidden md:table-cell" ]
            [ source.source.counter |> String.fromInt |> text
            ]
        , td [ class "text-center hidden md:table-cell" ]
            [ Data.Priority.fromString source.source.priority
                |> Maybe.map Data.Priority.toName
                |> Maybe.withDefault source.source.priority
                |> text
            ]
        , td [ class "text-center hidden sm:table-cell" ]
            [ text source.source.id
            ]
        ]
