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
import Html exposing (..)
import Html.Attributes exposing (..)
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


type Msg
    = SetTags (List Tag)
    | Select Tag
    | Deselect


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        SetTags list ->
            ( { model | tags = list, selected = Nothing }, Cmd.none )

        Select tag ->
            ( { model | selected = Just tag }, Cmd.none )

        Deselect ->
            ( { model | selected = Nothing }, Cmd.none )



--- View2


view2 : Texts -> Model -> Html Msg
view2 texts model =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "" ] []
                , th [ class "text-left" ] [ text texts.basics.name ]
                , th [ class "text-left" ] [ text texts.category ]
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
