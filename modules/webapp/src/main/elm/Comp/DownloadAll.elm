{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.DownloadAll exposing (AccessMode(..), Model, Msg, UpdateResult, checkDownload, init, isPreparing, update, view)

import Api
import Api.Model.DownloadAllRequest exposing (DownloadAllRequest)
import Api.Model.DownloadAllSummary exposing (DownloadAllSummary)
import Comp.Basic as B
import Comp.FixedDropdown
import Data.DownloadAllState
import Data.DownloadFileType exposing (DownloadFileType)
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Html exposing (Html, a, div, i, label, text)
import Html.Attributes exposing (class, classList, disabled, href)
import Html.Events exposing (onClick)
import Http
import Messages.Comp.DownloadAll exposing (Texts)
import Styles as S
import Util.Size


type alias Model =
    { summary : DownloadAllSummary
    , query : String
    , dlType : DownloadFileType
    , dlTypeDropdown : Comp.FixedDropdown.Model DownloadFileType
    , loading : Bool
    , formError : FormError
    , accessMode : AccessMode
    }


type AccessMode
    = AccessShare String
    | AccessUser


type FormError
    = FormNone
    | FormHttpError Http.Error


init : AccessMode -> Flags -> String -> ( Model, Cmd Msg )
init am flags query =
    let
        model =
            { summary = Api.Model.DownloadAllSummary.empty
            , query = query
            , dlType = Data.DownloadFileType.Converted
            , dlTypeDropdown = Comp.FixedDropdown.init Data.DownloadFileType.all
            , formError = FormNone
            , accessMode = am
            , loading = False
            }
    in
    ( model
    , prefetch flags model
    )


type Msg
    = DownloadSummaryResp (Result Http.Error DownloadAllSummary)
    | DlTypeMsg (Comp.FixedDropdown.Msg DownloadFileType)
    | CloseAction
    | SubmitAction
    | CheckAction


checkDownload : Msg
checkDownload =
    CheckAction


isPreparing : Model -> Bool
isPreparing model =
    Data.DownloadAllState.fromString model.summary.state == Just Data.DownloadAllState.Preparing


makeRequest : Model -> DownloadAllRequest
makeRequest model =
    { query = model.query
    , fileType = Data.DownloadFileType.asString model.dlType
    }



--- Update


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , closed : Bool
    }


update : Flags -> Msg -> Model -> UpdateResult
update flags msg model =
    case msg of
        DownloadSummaryResp (Ok summary) ->
            unit { model | summary = summary, formError = FormNone, loading = False }

        DownloadSummaryResp (Err err) ->
            unit { model | formError = FormHttpError err, loading = False }

        DlTypeMsg lm ->
            let
                ( dlm, sel ) =
                    Comp.FixedDropdown.update lm model.dlTypeDropdown

                nextDlType =
                    Maybe.withDefault model.dlType sel

                nextModel =
                    { model
                        | dlTypeDropdown = dlm
                        , dlType = nextDlType
                        , formError = FormNone
                    }
            in
            if nextDlType /= model.dlType && sel /= Nothing then
                unitCmd
                    ( { nextModel | loading = True }
                    , prefetch flags nextModel
                    )

            else
                unit { model | dlTypeDropdown = dlm }

        CloseAction ->
            UpdateResult model Cmd.none True

        SubmitAction ->
            unitCmd
                ( model
                , submit flags model
                )

        CheckAction ->
            unitCmd
                ( model
                , prefetch flags model
                )


unit : Model -> UpdateResult
unit model =
    UpdateResult model Cmd.none False


unitCmd : ( Model, Cmd Msg ) -> UpdateResult
unitCmd ( m, c ) =
    UpdateResult m c False


prefetch : Flags -> Model -> Cmd Msg
prefetch flags model =
    case model.accessMode of
        AccessUser ->
            Api.downloadAllPrefetch flags (makeRequest model) DownloadSummaryResp

        AccessShare shareId ->
            Api.shareDownloadAllPrefetch flags shareId (makeRequest model) DownloadSummaryResp


submit : Flags -> Model -> Cmd Msg
submit flags model =
    case model.accessMode of
        AccessUser ->
            Api.downloadAllSubmit flags (makeRequest model) DownloadSummaryResp

        AccessShare shareId ->
            Api.shareDownloadAllSubmit flags shareId (makeRequest model) DownloadSummaryResp


downloadLink : Flags -> Model -> String
downloadLink flags model =
    case model.accessMode of
        AccessUser ->
            Api.downloadAllLink flags model.summary.id

        AccessShare _ ->
            Api.shareDownloadAllLink flags model.summary.id



--- View


view : Flags -> Texts -> Model -> Html Msg
view flags texts model =
    let
        dlTypeSettings =
            { display = texts.downloadFileType
            , icon = \_ -> Nothing
            , selectPlaceholder = ""
            , style = DS.mainStyle
            }

        byteStr n =
            Util.Size.bytesReadable Util.Size.B (toFloat n)
    in
    case Data.DownloadAllState.fromString model.summary.state of
        Nothing ->
            div [ class "flex flex-col animate-pulse space-y-4 px-2 my-2" ]
                [ div [ class "h-2 border dark:border-slate-600 bg-gray-100 dark:bg-slate-600" ]
                    []
                , div [ class "h-2 border dark:border-slate-600 bg-gray-100 dark:bg-slate-600" ]
                    []
                , div [ class "h-8 border dark:border-slate-600 bg-gray-100 dark:bg-slate-600" ]
                    []
                , div [ class "flex flex-row space-x-4 " ]
                    [ div [ class "h-10 w-32 dark:border-slate-600 bg-gray-100 dark:bg-slate-600" ]
                        []
                    , div [ class "h-10 w-32 dark:border-slate-600 bg-gray-100 dark:bg-slate-600" ]
                        []
                    ]
                ]

        Just Data.DownloadAllState.Empty ->
            div
                [ class "flex flex-col relative px-2"
                ]
                [ div
                    [ class S.infoMessage
                    ]
                    [ text texts.noResults
                    ]
                , div [ class "flex flex-row py-2" ]
                    [ a
                        [ class S.secondaryButton
                        , href "#"
                        , onClick CloseAction
                        ]
                        [ i [ class "fa fa-times mr-2" ] []
                        , text texts.close
                        ]
                    ]
                ]

        Just state ->
            div [ class "flex flex-col relative px-2" ]
                [ B.loadingDimmer
                    { active = state == Data.DownloadAllState.Preparing
                    , label = texts.downloadPreparing
                    }
                , div
                    [ classList [ ( "hidden", state == Data.DownloadAllState.Forbidden ) ]
                    ]
                    [ text
                        (texts.summary
                            model.summary.fileCount
                            (byteStr model.summary.uncompressedSize)
                        )
                    ]
                , div
                    [ classList [ ( "hidden", state /= Data.DownloadAllState.Forbidden ) ]
                    , class S.errorMessage
                    ]
                    [ text texts.downloadTooLarge
                    , text " "
                    , text <|
                        texts.downloadConfigText
                            flags.config.downloadAllMaxFiles
                            flags.config.downloadAllMaxSize
                            model.summary.uncompressedSize
                    ]
                , div
                    [ class "mt-3"
                    , classList [ ( "hidden", model.accessMode /= AccessUser ) ]
                    ]
                    [ label [ class S.inputLabel ]
                        [ text texts.downloadFileTypeLabel
                        ]
                    , Html.map DlTypeMsg
                        (Comp.FixedDropdown.viewStyled2
                            dlTypeSettings
                            False
                            (Just model.dlType)
                            model.dlTypeDropdown
                        )
                    ]
                , div
                    [ class "my-2"
                    , classList [ ( "hidden", state /= Data.DownloadAllState.Present ) ]
                    ]
                    [ text texts.downloadReady
                    ]
                , div
                    [ class "my-2 "
                    , classList [ ( "hidden", state /= Data.DownloadAllState.NotPresent ) ]
                    ]
                    [ text texts.downloadCreateText
                    ]
                , div [ class "flex flex-row py-2 items-center" ]
                    [ a
                        [ class S.primaryButton
                        , disabled (state /= Data.DownloadAllState.NotPresent && state /= Data.DownloadAllState.Present)
                        , classList [ ( "disabled", state /= Data.DownloadAllState.NotPresent && state /= Data.DownloadAllState.Present ) ]
                        , if state == Data.DownloadAllState.Present then
                            href (downloadLink flags model)

                          else
                            href "#"
                        , if state == Data.DownloadAllState.NotPresent then
                            onClick SubmitAction

                          else
                            class ""
                        ]
                        [ case state of
                            Data.DownloadAllState.Present ->
                                text texts.downloadNow

                            Data.DownloadAllState.NotPresent ->
                                text texts.downloadCreate

                            Data.DownloadAllState.Preparing ->
                                text texts.downloadPreparing

                            Data.DownloadAllState.Forbidden ->
                                text "N./A."

                            Data.DownloadAllState.Empty ->
                                text "N./A."
                        ]
                    , a
                        [ class S.secondaryButton
                        , class "ml-2"
                        , href "#"
                        , onClick CloseAction
                        ]
                        [ i [ class "fa fa-times mr-2" ] []
                        , text texts.close
                        ]
                    , div
                        [ class "h-full ml-3"
                        , classList [ ( "hidden", not model.loading ) ]
                        ]
                        [ i [ class "fa fa-circle-notch animate-spin" ] []
                        ]
                    ]
                ]
