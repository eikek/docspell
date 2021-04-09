module Comp.EmailSettingsManage exposing
    ( Model
    , Msg
    , emptyModel
    , init
    , update
    , view2
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.EmailSettings
import Api.Model.EmailSettingsList exposing (EmailSettingsList)
import Comp.Basic as B
import Comp.EmailSettingsForm
import Comp.EmailSettingsTable
import Comp.MenuBar as MB
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Messages.EmailSettingsManageComp exposing (Texts)
import Styles as S
import Util.Http


type alias Model =
    { tableModel : Comp.EmailSettingsTable.Model
    , formModel : Comp.EmailSettingsForm.Model
    , viewMode : ViewMode
    , formError : Maybe String
    , loading : Bool
    , query : String
    , deleteConfirm : Comp.YesNoDimmer.Model
    }


emptyModel : Model
emptyModel =
    { tableModel = Comp.EmailSettingsTable.emptyModel
    , formModel = Comp.EmailSettingsForm.emptyModel
    , viewMode = Table
    , formError = Nothing
    , loading = False
    , query = ""
    , deleteConfirm = Comp.YesNoDimmer.emptyModel
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( emptyModel, Api.getMailSettings flags "" MailSettingsResp )


type ViewMode
    = Table
    | Form


type Msg
    = TableMsg Comp.EmailSettingsTable.Msg
    | FormMsg Comp.EmailSettingsForm.Msg
    | SetQuery String
    | InitNew
    | YesNoMsg Comp.YesNoDimmer.Msg
    | RequestDelete
    | SetViewMode ViewMode
    | Submit
    | SubmitResp (Result Http.Error BasicResult)
    | LoadSettings
    | MailSettingsResp (Result Http.Error EmailSettingsList)


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        InitNew ->
            let
                ems =
                    Api.Model.EmailSettings.empty

                nm =
                    { model
                        | viewMode = Form
                        , formError = Nothing
                        , formModel = Comp.EmailSettingsForm.init ems
                    }
            in
            ( nm, Cmd.none )

        TableMsg m ->
            let
                ( tm, tc ) =
                    Comp.EmailSettingsTable.update m model.tableModel

                m2 =
                    { model
                        | tableModel = tm
                        , viewMode = Maybe.map (\_ -> Form) tm.selected |> Maybe.withDefault Table
                        , formError =
                            if tm.selected /= Nothing then
                                Nothing

                            else
                                model.formError
                        , formModel =
                            case tm.selected of
                                Just ems ->
                                    Comp.EmailSettingsForm.init ems

                                Nothing ->
                                    model.formModel
                    }
            in
            ( m2, Cmd.map TableMsg tc )

        FormMsg m ->
            let
                ( fm, fc ) =
                    Comp.EmailSettingsForm.update m model.formModel
            in
            ( { model | formModel = fm }, Cmd.map FormMsg fc )

        SetQuery str ->
            let
                m =
                    { model | query = str }
            in
            ( m, Api.getMailSettings flags str MailSettingsResp )

        YesNoMsg m ->
            let
                ( dm, flag ) =
                    Comp.YesNoDimmer.update m model.deleteConfirm

                ( mid, _ ) =
                    Comp.EmailSettingsForm.getSettings model.formModel

                cmd =
                    case ( flag, mid ) of
                        ( True, Just name ) ->
                            Api.deleteMailSettings flags name SubmitResp

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
                    Comp.EmailSettingsForm.getSettings model.formModel

                valid =
                    Comp.EmailSettingsForm.isValid model.formModel
            in
            if valid then
                ( { model | loading = True }, Api.createMailSettings flags mid ems SubmitResp )

            else
                ( { model | formError = Just "Please fill required fields." }, Cmd.none )

        LoadSettings ->
            ( { model | loading = True }, Api.getMailSettings flags model.query MailSettingsResp )

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
                ( { model | formError = Just res.message, loading = False }, Cmd.none )

        SubmitResp (Err err) ->
            ( { model | formError = Just (Util.Http.errorToString err), loading = False }, Cmd.none )

        MailSettingsResp (Ok ems) ->
            let
                m2 =
                    { model
                        | viewMode = Table
                        , loading = False
                        , tableModel = Comp.EmailSettingsTable.init ems.items
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
                    , title = texts.addNewSmtpSettings
                    , icon = Just "fa fa-plus"
                    , label = texts.newSettings
                    }
                ]
            , rootClasses = "mb-4"
            }
        , Html.map TableMsg
            (Comp.EmailSettingsTable.view2 texts.settingsTable
                model.tableModel
            )
        ]


viewForm2 : Texts -> UiSettings -> Model -> Html Msg
viewForm2 texts settings model =
    let
        dimmerSettings =
            Comp.YesNoDimmer.defaultSettings texts.reallyDeleteConnection
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
                [ ( "hidden", model.formError == Nothing )
                ]
            , class "my-2"
            , class S.errorMessage
            ]
            [ Maybe.withDefault "" model.formError |> text
            ]
        , Html.map FormMsg
            (Comp.EmailSettingsForm.view2 texts.settingsForm
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
