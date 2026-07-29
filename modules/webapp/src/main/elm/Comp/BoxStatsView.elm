{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.BoxStatsView exposing (Model, Msg, ViewResult(..), init, reloadData, update, view)

import Api
import Api.Model.ItemQuery exposing (ItemQuery)
import Api.Model.SearchStats exposing (SearchStats)
import Comp.Basic
import Comp.SearchStatsView
import Data.BoxContent exposing (SearchQuery(..), StatsData, SummaryShow(..))
import Data.Flags exposing (Flags)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Http
import Messages.Comp.BoxStatsView exposing (Texts)
import Styles
import Util.List


type alias Model =
    { results : ViewResult
    , meta : StatsData
    , parentManaged : Bool
    }


type ViewResult
    = Loading
    | Loaded SearchStats
    | Failed Http.Error


type Msg
    = StatsResp (Result Http.Error SearchStats)
    | ReloadData


init : Flags -> StatsData -> Maybe (Result Http.Error SearchStats) -> Bool -> ( Model, Cmd Msg )
init flags data cached parentManaged =
    case cached of
        Just (Ok stats) ->
            ( { results = Loaded stats, meta = data, parentManaged = parentManaged }, Cmd.none )

        Just (Err err) ->
            ( { results = Failed err, meta = data, parentManaged = parentManaged }, Cmd.none )

        Nothing ->
            if parentManaged then
                ( { results = Loading, meta = data, parentManaged = parentManaged }, Cmd.none )

            else
                ( { results = Loading, meta = data, parentManaged = parentManaged }
                , dataCmd flags data
                )


reloadData : Msg
reloadData =
    ReloadData



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Bool )
update flags msg model =
    case msg of
        StatsResp (Ok stats) ->
            ( { model | results = Loaded stats }, Cmd.none, False )

        StatsResp (Err err) ->
            ( { model | results = Failed err }, Cmd.none, False )

        ReloadData ->
            if model.parentManaged then
                ( model, Cmd.none, True )

            else
                ( model, dataCmd flags model.meta, True )



--- View


view : Texts -> Model -> Html Msg
view texts model =
    case model.results of
        Loading ->
            div [ class "h-24 " ]
                [ Comp.Basic.loadingDimmer
                    { label = ""
                    , active = True
                    }
                ]

        Failed err ->
            div
                [ class "py-4"
                , class Styles.errorMessage
                ]
                [ text texts.errorOccurred
                , text ": "
                , text (texts.httpError err)
                ]

        Loaded stats ->
            viewStats texts model stats


viewStats : Texts -> Model -> SearchStats -> Html Msg
viewStats texts model stats =
    case model.meta.show of
        SummaryShowFields flag ->
            Comp.SearchStatsView.view2
                texts.statsView
                flag
                ""
                stats

        SummaryShowGeneral ->
            viewGeneral texts stats


viewGeneral : Texts -> SearchStats -> Html Msg
viewGeneral texts stats =
    let
        tagCount =
            List.length stats.tagCloud.items

        fieldCount =
            Maybe.withDefault (List.length stats.fieldStats) stats.fieldCount

        orgCount =
            Maybe.withDefault (List.length stats.corrOrgStats) stats.orgCount

        persCount =
            Maybe.withDefault
                ((stats.corrPersStats ++ stats.concPersStats)
                    |> List.map (.ref >> .id)
                    |> Util.List.distinct
                    |> List.length
                )
                stats.personCount

        equipCount =
            Maybe.withDefault (List.length stats.concEquipStats) stats.equipCount

        mklabel name =
            div [ class "py-0.5 text-lg" ] [ text name ]

        value num =
            div [ class "py-0.5 font-mono text-lg" ] [ text <| String.fromInt num ]
    in
    div [ class "opacity-90" ]
        [ div [ class "flex flex-row" ]
            [ div [ class "flex flex-col mr-4" ]
                [ mklabel texts.basics.items
                , mklabel texts.basics.tags
                , mklabel texts.basics.customFields
                , mklabel texts.basics.organization
                , mklabel texts.basics.person
                , mklabel texts.basics.equipment
                ]
            , div [ class "flex flex-col" ]
                [ value stats.count
                , value tagCount
                , value fieldCount
                , value orgCount
                , value persCount
                , value equipCount
                ]
            ]
        ]



--- Helpers


mkQuery : String -> Maybe String -> ItemQuery
mkQuery query profile =
    { query = query
    , limit = Nothing
    , offset = Nothing
    , searchMode = Nothing
    , withDetails = Nothing
    , statsProfile = profile
    }


statsProfileFor : SummaryShow -> Maybe String
statsProfileFor show =
    case show of
        SummaryShowGeneral ->
            Just "general"

        SummaryShowFields _ ->
            Just "fields"


dataCmd : Flags -> StatsData -> Cmd Msg
dataCmd flags data =
    let
        profile =
            statsProfileFor data.show

        query =
            case data.query of
                SearchQueryString q ->
                    mkQuery q profile

                SearchQueryBookmark bmId ->
                    mkQuery bmId profile
    in
    case ( data.query, profile ) of
        ( SearchQueryString _, Just "general" ) ->
            Api.itemSearchStatsGeneral flags query StatsResp

        ( SearchQueryString _, _ ) ->
            Api.itemSearchStatsFields flags query StatsResp

        ( SearchQueryBookmark _, Just "general" ) ->
            Api.itemSearchStatsBookmarkAt "general" flags query StatsResp

        ( SearchQueryBookmark _, _ ) ->
            Api.itemSearchStatsBookmarkAt "fields" flags query StatsResp
