{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.BoxView exposing (..)

import Comp.BoxQueryView
import Comp.BoxStatsView
import Comp.BoxUploadView
import Data.Box exposing (Box)
import Data.BoxContent exposing (BoxContent(..), MessageData)
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (Html, div, i, text)
import Html.Attributes exposing (class, classList)
import Markdown
import Messages.Comp.BoxView exposing (Texts)
import Styles as S


type alias Model =
    { box : Box
    , content : ContentModel
    , reloading : Bool
    }


type ContentModel
    = ContentMessage Data.BoxContent.MessageData
    | ContentUpload Comp.BoxUploadView.Model
    | ContentQuery Comp.BoxQueryView.Model
    | ContentStats Comp.BoxStatsView.Model


type Msg
    = QueryMsg Comp.BoxQueryView.Msg
    | StatsMsg Comp.BoxStatsView.Msg
    | UploadMsg Comp.BoxUploadView.Msg
    | ReloadData


init : Flags -> Box -> ( Model, Cmd Msg )
init flags box =
    let
        ( cm, cc ) =
            contentInit flags box.content
    in
    ( { box = box
      , content = cm
      , reloading = False
      }
    , cc
    )


reloadData : Msg
reloadData =
    ReloadData


contentInit : Flags -> BoxContent -> ( ContentModel, Cmd Msg )
contentInit flags content =
    case content of
        BoxMessage data ->
            ( ContentMessage data, Cmd.none )

        BoxUpload data ->
            let
                qm =
                    Comp.BoxUploadView.init data
            in
            ( ContentUpload qm, Cmd.none )

        BoxQuery data ->
            let
                ( qm, qc ) =
                    Comp.BoxQueryView.init flags data
            in
            ( ContentQuery qm, Cmd.map QueryMsg qc )

        BoxStats data ->
            let
                ( sm, sc ) =
                    Comp.BoxStatsView.init flags data
            in
            ( ContentStats sm, Cmd.map StatsMsg sc )



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update flags msg model =
    case msg of
        QueryMsg lm ->
            case model.content of
                ContentQuery qm ->
                    let
                        ( cm, cc, reloading ) =
                            Comp.BoxQueryView.update flags lm qm
                    in
                    ( { model | content = ContentQuery cm, reloading = reloading }
                    , Cmd.map QueryMsg cc
                    , Sub.none
                    )

                _ ->
                    unit model

        StatsMsg lm ->
            case model.content of
                ContentStats qm ->
                    let
                        ( cm, cc, reloading ) =
                            Comp.BoxStatsView.update flags lm qm
                    in
                    ( { model | content = ContentStats cm, reloading = reloading }
                    , Cmd.map StatsMsg cc
                    , Sub.none
                    )

                _ ->
                    unit model

        UploadMsg lm ->
            case model.content of
                ContentUpload qm ->
                    let
                        ( cm, cc, cs ) =
                            Comp.BoxUploadView.update flags lm qm
                    in
                    ( { model | content = ContentUpload cm }
                    , Cmd.map UploadMsg cc
                    , Sub.map UploadMsg cs
                    )

                _ ->
                    unit model

        ReloadData ->
            case model.content of
                ContentQuery _ ->
                    update flags (QueryMsg Comp.BoxQueryView.reloadData) model

                ContentStats _ ->
                    update flags (StatsMsg Comp.BoxStatsView.reloadData) model

                _ ->
                    unit model


unit : Model -> ( Model, Cmd Msg, Sub Msg )
unit model =
    ( model, Cmd.none, Sub.none )



--- View


view : Texts -> Flags -> UiSettings -> Model -> Html Msg
view texts flags settings model =
    div
        [ classList [ ( S.box ++ "rounded", model.box.decoration ) ]
        , class (spanStyle model.box)
        , class "relative h-full"
        , classList [ ( "hidden", not model.box.visible ) ]
        ]
        [ boxLoading model
        , boxHeader model
        , div [ class "px-2 py-1 h-5/6" ]
            [ boxContent texts flags settings model
            ]
        ]


boxLoading : Model -> Html Msg
boxLoading model =
    if not model.reloading then
        div [ class "hidden" ] []

    else
        div [ class "absolute right-0 top-1 h-6 w-6" ]
            [ i [ class "fa fa-spinner animate-spin" ] []
            ]


boxHeader : Model -> Html Msg
boxHeader model =
    div
        [ class "flex flex-row py-1 bg-blue-50 dark:bg-slate-700 rounded-t"
        , classList [ ( "hidden", not model.box.decoration || model.box.name == "" ) ]
        ]
        [ div [ class "flex text-lg tracking-medium italic px-2" ]
            [ text model.box.name
            ]
        ]


boxContent : Texts -> Flags -> UiSettings -> Model -> Html Msg
boxContent texts flags settings model =
    case model.content of
        ContentMessage m ->
            messageContent m

        ContentUpload qm ->
            Html.map UploadMsg
                (Comp.BoxUploadView.view texts.uploadView flags settings qm)

        ContentQuery qm ->
            Html.map QueryMsg
                (Comp.BoxQueryView.view texts.queryView settings qm)

        ContentStats qm ->
            Html.map StatsMsg
                (Comp.BoxStatsView.view texts.statsView qm)


spanStyle : Box -> String
spanStyle box =
    case box.colspan of
        1 ->
            ""

        2 ->
            "col-span-1 md:col-span-2"

        3 ->
            "col-span-1 md:col-span-3"

        4 ->
            "col-span-1 md:col-span-4"

        _ ->
            "col-span-1 md:col-span-5"


messageContent : MessageData -> Html msg
messageContent data =
    div [ class "markdown-preview" ]
        [ Markdown.toHtml [] data.title
        , Markdown.toHtml [] data.body
        ]
