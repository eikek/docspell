{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


-- Dashboard coordinates search statistics HTTP requests and caches results in
-- StatsCache. Boxes with parentManaged = True do not fetch stats themselves;
-- this module issues one request per distinct (query, profile) pair via
-- deduplicated fetchStatsCmds.


module Comp.DashboardView exposing (Model, Msg, emptyModel, init, reload, reloadData, update, view, viewBox)

import Api
import Api.Model.ItemQuery exposing (ItemQuery)
import Api.Model.SearchStats exposing (SearchStats)
import Comp.BoxView
import Data.Box exposing (Box)
import Data.BoxContent exposing (BoxContent(..), SearchQuery(..), StatsData, SummaryShow(..), searchQueryAsString, searchQueryFromString)
import Data.Dashboard exposing (Dashboard)
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Dict exposing (Dict)
import Html exposing (Html, div)
import Html.Attributes exposing (class)
import Http
import Messages.Comp.DashboardView exposing (Texts)
import Util.List
import Util.Update


type alias StatsKey =
    String


type alias StatsCache =
    { general : Dict StatsKey (Result Http.Error SearchStats)
    , fields : Dict StatsKey (Result Http.Error SearchStats)
    }


emptyStatsCache : StatsCache
emptyStatsCache =
    { general = Dict.empty
    , fields = Dict.empty
    }


type alias Model =
    { dashboard : Dashboard
    , boxModels : Dict Int Comp.BoxView.Model
    , statsCache : StatsCache
    }


type Msg
    = BoxMsg Int Comp.BoxView.Msg
    | ReloadData
    | StatsGeneralResp StatsKey (Result Http.Error SearchStats)
    | StatsFieldsResp StatsKey (Result Http.Error SearchStats)


emptyModel : Dashboard -> Model
emptyModel db =
    { dashboard = db
    , boxModels = Dict.empty
    , statsCache = emptyStatsCache
    }


init : Flags -> Dashboard -> ( Model, Cmd Msg )
init flags db =
    initWithCache flags db emptyStatsCache


initWithCache : Flags -> Dashboard -> StatsCache -> ( Model, Cmd Msg )
initWithCache flags db cache =
    let
        indexedBoxes =
            List.indexedMap (initBox flags cache) db.boxes

        boxModels =
            List.map (\( index, bm, _ ) -> ( index, bm )) indexedBoxes

        boxCmds =
            List.map (\( _, _, cmd ) -> cmd) indexedBoxes

        statsCmds =
            fetchStatsCmds flags db cache

    in
    ( { dashboard = db
      , boxModels = Dict.fromList boxModels
      , statsCache = cache
      }
    , Cmd.batch (statsCmds ++ boxCmds)
    )


reload : Flags -> Model -> ( Model, Cmd Msg )
reload flags model =
    initWithCache flags model.dashboard model.statsCache


initBox : Flags -> StatsCache -> Int -> Box -> ( Int, Comp.BoxView.Model, Cmd Msg )
initBox flags cache index box =
    let
        ( statsCached, parentManaged ) =
            case box.content of
                BoxStats data ->
                    ( lookupStats cache data, True )

                _ ->
                    ( Nothing, False )

        ( bm, bc ) =
            Comp.BoxView.init flags box statsCached parentManaged
    in
    ( index, bm, Cmd.map (BoxMsg index) bc )


reloadData : Msg
reloadData =
    ReloadData



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update flags msg model =
    case msg of
        BoxMsg index lm ->
            case Dict.get index model.boxModels of
                Just bm ->
                    let
                        ( cm, cc, cs ) =
                            Comp.BoxView.update flags lm bm
                    in
                    ( { model | boxModels = Dict.insert index cm model.boxModels }
                    , Cmd.map (BoxMsg index) cc
                    , Sub.map (BoxMsg index) cs
                    )

                Nothing ->
                    unit model

        ReloadData ->
            let
                ( dm, cmds ) =
                    reload flags model
            in
            ( dm, cmds, Sub.none )

        StatsGeneralResp key result ->
            let
                sc =
                    model.statsCache

                cache =
                    { sc | general = Dict.insert key result sc.general }

                boxes =
                    updateStatsBoxes cache model.boxModels
            in
            ( { model | statsCache = cache, boxModels = boxes }
            , Cmd.none
            , Sub.none
            )

        StatsFieldsResp key result ->
            let
                sc =
                    model.statsCache

                cache =
                    { sc | fields = Dict.insert key result sc.fields }

                boxes =
                    updateStatsBoxes cache model.boxModels
            in
            ( { model | statsCache = cache, boxModels = boxes }
            , Cmd.none
            , Sub.none
            )

unit : Model -> ( Model, Cmd Msg, Sub Msg )
unit model =
    ( model, Cmd.none, Sub.none )



--- View


view : Texts -> Flags -> UiSettings -> Model -> Html Msg
view texts flags settings model =
    div
        [ class (gridStyle model.dashboard)
        ]
        (Dict.toList model.boxModels
            |> List.map (\( index, box ) -> viewBox texts flags settings index box)
        )


viewBox : Texts -> Flags -> UiSettings -> Int -> Comp.BoxView.Model -> Html Msg
viewBox texts flags settings index box =
    Html.map (BoxMsg index)
        (Comp.BoxView.view texts.boxView flags settings box)



--- Helpers


lookupStats : StatsCache -> StatsData -> Maybe (Result Http.Error SearchStats)
lookupStats cache data =
    let
        key =
            searchQueryAsString data.query
    in
    case data.show of
        SummaryShowGeneral ->
            Dict.get key cache.general

        SummaryShowFields _ ->
            Dict.get key cache.fields


updateStatsBoxes : StatsCache -> Dict Int Comp.BoxView.Model -> Dict Int Comp.BoxView.Model
updateStatsBoxes cache =
    Dict.map
        (\_ bm ->
            case bm.content of
                Comp.BoxView.ContentStats sm ->
                    case lookupStats cache sm.meta of
                        Just result ->
                            Comp.BoxView.applyStatsResult result bm

                        Nothing ->
                            bm

                _ ->
                    bm
        )


isCached : StatsCache -> StatsKey -> String -> Bool
isCached cache key profile =
    let
        cached =
            case profile of
                "general" ->
                    Dict.get key cache.general

                _ ->
                    Dict.get key cache.fields
    in
    case cached of
        Just (Ok _) ->
            True

        _ ->
            False


fetchStatsCmds : Flags -> Dashboard -> StatsCache -> List (Cmd Msg)
fetchStatsCmds flags db cache =
    db.boxes
        |> List.concatMap statsRequestsForBox
        |> Util.List.distinct
        |> List.filter (\( k, p ) -> not (isCached cache k p))
        |> List.filterMap (fetchStatsPair flags)


statsRequestsForBox : Box -> List ( StatsKey, String )
statsRequestsForBox box =
    case box.content of
        BoxStats data ->
            let
                key =
                    searchQueryAsString data.query
            in
            case data.show of
                SummaryShowGeneral ->
                    [ ( key, "general" ) ]

                SummaryShowFields _ ->
                    [ ( key, "fields" ) ]

        _ ->
            []


fetchStatsPair : Flags -> ( StatsKey, String ) -> Maybe (Cmd Msg)
fetchStatsPair flags ( key, profile ) =
    searchQueryFromString key
        |> Maybe.map
            (\sq ->
                let
                    query =
                        mkStatsQuery sq profile

                    resp =
                        case profile of
                            "general" ->
                                StatsGeneralResp key

                            _ ->
                                StatsFieldsResp key
                in
                case ( sq, profile ) of
                    ( SearchQueryString _, "general" ) ->
                        Api.itemSearchStatsGeneral flags query resp

                    ( SearchQueryString _, _ ) ->
                        Api.itemSearchStatsFields flags query resp

                    ( SearchQueryBookmark _, "general" ) ->
                        Api.itemSearchStatsBookmarkAt "general" flags query resp

                    ( SearchQueryBookmark _, _ ) ->
                        Api.itemSearchStatsBookmarkAt "fields" flags query resp
            )


mkStatsQuery : SearchQuery -> String -> ItemQuery
mkStatsQuery sq profile =
    let
        qstr =
            case sq of
                SearchQueryString s ->
                    s

                SearchQueryBookmark id ->
                    id
    in
    { query = qstr
    , limit = Nothing
    , offset = Nothing
    , searchMode = Nothing
    , withDetails = Nothing
    , statsProfile = Just profile
    }


gridStyle : Dashboard -> String
gridStyle db =
    let
        cappedGap =
            min db.gap 12

        cappedCol =
            min db.columns 12

        gapStyle =
            " gap-" ++ String.fromInt cappedGap ++ " "

        colStyle =
            case db.columns of
                1 ->
                    ""

                _ ->
                    " md:grid-cols-" ++ String.fromInt cappedCol ++ " "
    in
    "grid grid-cols-1 " ++ gapStyle ++ colStyle
