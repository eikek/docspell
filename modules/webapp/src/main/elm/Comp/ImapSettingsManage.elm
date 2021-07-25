{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Comp.ImapSettingsManage exposing
    ( Model
    , Msg
    , emptyModel
    , init
    , update
    , view2
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.ImapSettings
import Api.Model.ImapSettingsList exposing (ImapSettingsList)
import Comp.Basic as B
import Comp.ImapSettingsForm
import Comp.ImapSettingsTable
import Comp.MenuBar as MB
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Messages.Comp.ImapSettingsManage exposing (Texts)
import Styles as S


type alias Model =
    { tableModel : Comp.ImapSettingsTable.Model
    , formModel : Comp.ImapSettingsForm.Model
    , viewMode : ViewMode
    , formError : FormError
    , loading : Bool
    , query : String
    , deleteConfirm : Comp.YesNoDimmer.Model
    }


type FormError
    = FormErrorNone
    | FormErrorHttp Http.Error
    | FormErrorSubmit String
    | FormErrorFillRequired


emptyModel : Model
emptyModel =
    { tableModel = Comp.ImapSettingsTable.emptyModel
    , formModel = Comp.ImapSettingsForm.emptyModel
    , viewMode = Table
    , formError = FormErrorNone
    , loading = False
    , query = ""
    , deleteConfirm = Comp.YesNoDimmer.emptyModel
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( emptyModel, Api.getImapSettings flags "" MailSettingsResp )


type ViewMode
    = Table
    | Form


type Msg
    = TableMsg Comp.ImapSettingsTable.Msg
    | FormMsg Comp.ImapSettingsForm.Msg
    | SetQuery String
    | InitNew
    | YesNoMsg Comp.YesNoDimmer.Msg
    | RequestDelete
    | SetViewMode ViewMode
    | Submit
    | SubmitResp (Result Http.Error BasicResult)
    | LoadSettings
    | MailSettingsResp (Result Http.Error ImapSettingsList)


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        InitNew ->
            let
                ems =
                    Api.Model.ImapSettings.empty

                nm =
                    { model
                        | viewMode = Form
                        , formError = FormErrorNone
                        , formModel = Comp.ImapSettingsForm.init ems
                    }
            in
            ( nm, Cmd.none )

        TableMsg m ->
            let
                ( tm, tc ) =
                    Comp.ImapSettingsTable.update m model.tableModel

                m2 =
                    { model
                        | tableModel = tm
                        , viewMode = Maybe.map (\_ -> Form) tm.selected |> Maybe.withDefault Table
                        , formError =
                            if tm.selected /= Nothing then
                                FormErrorNone

                            else
                                model.formError
                        , formModel =
                            case tm.selected of
                                Just ems ->
                                    Comp.ImapSettingsForm.init ems

                                Nothing ->
                                    model.formModel
                    }
            in
            ( m2, Cmd.map TableMsg tc )

        FormMsg m ->
            let
                ( fm, fc ) =
                    Comp.ImapSettingsForm.update m model.formModel
            in
            ( { model | formModel = fm }, Cmd.map FormMsg fc )

        SetQuery str ->
            let
                m =
                    { model | query = str }
            in
            ( m, Api.getImapSettings flags str MailSettingsResp )

        YesNoMsg m ->
            let
                ( dm, flag ) =
                    Comp.YesNoDimmer.update m model.deleteConfirm

                ( mid, _ ) =
                    Comp.ImapSettingsForm.getSettings model.formModel

                cmd =
                    case ( flag, mid ) of
                        ( True, Just name ) ->
                            Api.deleteImapSettings flags name SubmitResp

                        _ ->
                            Cmd.none
            in
            ( { model | deleteConfirm = dm }, cmd )

        RequestDelete ->
            update flags (YesNoMsg Comp.YesNoDimmer.activate) model

        SetViewMode m ->
            ( { model | viewMode = m }, Cmd.none )

        Submit ->
            let
                ( mid, ems ) =
                    Comp.ImapSettingsForm.getSettings model.formModel

                valid =
                    Comp.ImapSettingsForm.isValid model.formModel
            in
            if valid then
                ( { model | loading = True }, Api.createImapSettings flags mid ems SubmitResp )

            else
                ( { model | formError = FormErrorFillRequired }, Cmd.none )

        LoadSettings ->
            ( { model | loading = True }, Api.getImapSettings flags model.query MailSettingsResp )

        SubmitResp (Ok res) ->
            if res.success then
                let
                    ( m2, c2 ) =
                        update flags (SetViewMode Table) model

                    ( m3, c3 ) =
                        update flags LoadSettings m2
                in
                ( { m3 | loading = False }, Cmd.batch [ c2, c3 ] )

            else
                ( { model | formError = FormErrorSubmit res.message, loading = False }, Cmd.none )

        SubmitResp (Err err) ->
            ( { model | formError = FormErrorHttp err, loading = False }, Cmd.none )

        MailSettingsResp (Ok ems) ->
            let
                m2 =
                    { model
                        | viewMode = Table
                        , loading = False
                        , tableModel = Comp.ImapSettingsTable.init ems.items
                    }
            in
            ( m2, Cmd.none )

        MailSettingsResp (Err _) ->
            ( { model | loading = False }, Cmd.none )



--- View2


view2 : Texts -> UiSettings -> Model -> Html Msg
view2 texts settings model =
    case model.viewMode of
        Table ->
            viewTable2 texts model

        Form ->
            viewForm2 texts settings model


viewTable2 : Texts -> Model -> Html Msg
viewTable2 texts model =
    div []
        [ MB.view
            { start =
                [ MB.TextInput
                    { tagger = SetQuery
                    , value = model.query
                    , placeholder = texts.basics.searchPlaceholder
                    , icon = Just "fa fa-search"
                    }
                ]
            , end =
                [ MB.PrimaryButton
                    { tagger = InitNew
                    , title = texts.addNewImapSettings
                    , icon = Just "fa fa-plus"
                    , label = texts.newSettings
                    }
                ]
            , rootClasses = "mb-4"
            }
        , Html.map TableMsg
            (Comp.ImapSettingsTable.view2
                texts.imapTable
                model.tableModel
            )
        ]


viewForm2 : Texts -> UiSettings -> Model -> Html Msg
viewForm2 texts settings model =
    let
        dimmerSettings =
            Comp.YesNoDimmer.defaultSettings texts.reallyDeleteSettings
                texts.basics.yes
                texts.basics.no
    in
    div [ class "flex flex-col md:relative" ]
        [ MB.view
            { start =
                [ MB.PrimaryButton
                    { tagger = Submit
                    , title = texts.basics.submitThisForm
                    , icon = Just "fa fa-save"
                    , label = texts.basics.submit
                    }
                , MB.SecondaryButton
                    { tagger = SetViewMode Table
                    , title = texts.basics.backToList
                    , icon = Just "fa fa-arrow-left"
                    , label = texts.basics.cancel
                    }
                ]
            , end =
                if model.formModel.settings.name /= "" then
                    [ MB.DeleteButton
                        { tagger = RequestDelete
                        , title = texts.deleteThisEntry
                        , icon = Just "fa fa-trash"
                        , label = texts.basics.delete
                        }
                    ]

                else
                    []
            , rootClasses = "mb-4"
            }
        , div
            [ classList
                [ ( "hidden", model.formError == FormErrorNone )
                ]
            , class "my-2"
            , class S.errorMessage
            ]
            [ case model.formError of
                FormErrorNone ->
                    text ""

                FormErrorHttp err ->
                    text (texts.httpError err)

                FormErrorFillRequired ->
                    text texts.fillRequiredFields

                FormErrorSubmit m ->
                    text m
            ]
        , Html.map FormMsg
            (Comp.ImapSettingsForm.view2
                texts.imapForm
                settings
                model.formModel
            )
        , Html.map YesNoMsg
            (Comp.YesNoDimmer.viewN
                True
                dimmerSettings
                model.deleteConfirm
            )
        , B.loadingDimmer
            { active = model.loading
            , label = texts.basics.loading
            }
        ]
