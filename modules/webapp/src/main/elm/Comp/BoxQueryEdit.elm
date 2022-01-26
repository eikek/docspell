{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.BoxQueryEdit exposing (..)

import Comp.BoxSearchQueryInput
import Comp.IntField
import Comp.ItemColumnDropdown
import Comp.MenuBar as MB
import Data.Bookmarks
import Data.BoxContent exposing (QueryData, SearchQuery(..))
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (Html, div, label, text)
import Html.Attributes exposing (class)
import Messages.Comp.BoxQueryEdit exposing (Texts)
import Styles as S


type alias Model =
    { data : QueryData
    , searchQueryModel : Comp.BoxSearchQueryInput.Model
    , limitModel : Comp.IntField.Model
    , limitValue : Maybe Int
    , columnModel : Comp.ItemColumnDropdown.Model
    }


type Msg
    = SearchQueryMsg Comp.BoxSearchQueryInput.Msg
    | LimitMsg Comp.IntField.Msg
    | ColumnMsg Comp.ItemColumnDropdown.Msg
    | ToggleColumnHeaders


init : Flags -> QueryData -> ( Model, Cmd Msg, Sub Msg )
init flags data =
    let
        ( qm, qc, qs ) =
            Comp.BoxSearchQueryInput.init flags data.query Data.Bookmarks.empty

        emptyModel =
            { data = data
            , searchQueryModel = qm
            , limitModel = Comp.IntField.init (Just 1) Nothing False
            , limitValue = Just data.limit
            , columnModel = Comp.ItemColumnDropdown.init data.columns
            }
    in
    ( emptyModel, Cmd.map SearchQueryMsg qc, Sub.map SearchQueryMsg qs )



--- Update


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    , data : QueryData
    }


update : Flags -> Msg -> Model -> UpdateResult
update flags msg model =
    case msg of
        SearchQueryMsg lm ->
            let
                result =
                    Comp.BoxSearchQueryInput.update flags lm model.searchQueryModel

                setData data =
                    { data | query = Maybe.withDefault data.query result.query }

                nextModel =
                    withData setData { model | searchQueryModel = result.model }
            in
            { model = nextModel
            , cmd = Cmd.map SearchQueryMsg result.cmd
            , sub = Sub.map SearchQueryMsg result.sub
            , data = nextModel.data
            }

        LimitMsg lm ->
            let
                ( im, n ) =
                    Comp.IntField.update lm model.limitModel

                data =
                    model.data

                data_ =
                    case n of
                        Just num ->
                            { data | limit = num }

                        Nothing ->
                            data
            in
            { model = { model | limitModel = im, limitValue = n, data = data_ }
            , cmd = Cmd.none
            , sub = Sub.none
            , data = data_
            }

        ColumnMsg lm ->
            let
                ( cm, cc ) =
                    Comp.ItemColumnDropdown.update lm model.columnModel

                selection =
                    Comp.ItemColumnDropdown.getSelected cm

                data =
                    model.data

                data_ =
                    { data | columns = selection }
            in
            { model = { model | columnModel = cm, data = data_ }
            , cmd = Cmd.map ColumnMsg cc
            , sub = Sub.none
            , data = data_
            }

        ToggleColumnHeaders ->
            let
                data =
                    model.data

                data_ =
                    { data | showHeaders = not data.showHeaders }
            in
            { model = { model | data = data_ }
            , cmd = Cmd.none
            , sub = Sub.none
            , data = data_
            }


unit : Model -> UpdateResult
unit model =
    { model = model
    , cmd = Cmd.none
    , sub = Sub.none
    , data = model.data
    }


withData : (QueryData -> QueryData) -> Model -> Model
withData modify model =
    { model | data = modify model.data }



--- View


view : Texts -> UiSettings -> Model -> Html Msg
view texts settings model =
    let
        limitSettings =
            { label = "Limit"
            , info = "Show this many results."
            , number = model.limitValue
            , classes = ""
            }
    in
    div []
        [ Html.map SearchQueryMsg
            (Comp.BoxSearchQueryInput.view texts.searchQuery settings model.searchQueryModel)
        , div [ class "mt-2" ]
            [ Html.map LimitMsg
                (Comp.IntField.view limitSettings model.limitModel)
            ]
        , div [ class "mt-2" ]
            [ label [ class S.inputLabel ]
                [ text "Columns"
                ]
            , Html.map ColumnMsg
                (Comp.ItemColumnDropdown.view texts.columnDropdown settings model.columnModel)
            ]
        , div [ class "mt-2" ]
            [ MB.viewItem <|
                MB.Checkbox
                    { tagger = \_ -> ToggleColumnHeaders
                    , label = texts.showColumnHeaders
                    , value = model.data.showHeaders
                    , id = ""
                    }
            ]
        ]
