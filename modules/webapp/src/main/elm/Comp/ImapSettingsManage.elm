module Comp.ImapSettingsManage exposing
    ( Model
    , Msg
    , emptyModel
    , init
    , update
    , view
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.ImapSettings
import Api.Model.ImapSettingsList exposing (ImapSettingsList)
import Comp.ImapSettingsForm
import Comp.ImapSettingsTable
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Util.Http


type alias Model =
    { tableModel : Comp.ImapSettingsTable.Model
    , formModel : Comp.ImapSettingsForm.Model
    , viewMode : ViewMode
    , formError : Maybe String
    , loading : Bool
    , query : String
    , deleteConfirm : Comp.YesNoDimmer.Model
    }


emptyModel : Model
emptyModel =
    { tableModel = Comp.ImapSettingsTable.emptyModel
    , formModel = Comp.ImapSettingsForm.emptyModel
    , viewMode = Table
    , formError = Nothing
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
                        , formError = Nothing
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
                                Nothing

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
                ( { model | formError = Just "Please fill required fields." }, Cmd.none )

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
                ( { model | formError = Just res.message, loading = False }, Cmd.none )

        SubmitResp (Err err) ->
            ( { model | formError = Just (Util.Http.errorToString err), loading = False }, Cmd.none )

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


view : UiSettings -> Model -> Html Msg
view settings model =
    case model.viewMode of
        Table ->
            viewTable model

        Form ->
            viewForm settings model


viewTable : Model -> Html Msg
viewTable model =
    div []
        [ div [ class "ui secondary menu" ]
            [ div [ class "horizontally fitted item" ]
                [ div [ class "ui icon input" ]
                    [ input
                        [ type_ "text"
                        , onInput SetQuery
                        , value model.query
                        , placeholder "Search…"
                        ]
                        []
                    , i [ class "ui search icon" ]
                        []
                    ]
                ]
            , div [ class "right menu" ]
                [ div [ class "item" ]
                    [ a
                        [ class "ui primary button"
                        , href "#"
                        , onClick InitNew
                        ]
                        [ i [ class "plus icon" ] []
                        , text "New Settings"
                        ]
                    ]
                ]
            ]
        , Html.map TableMsg (Comp.ImapSettingsTable.view model.tableModel)
        ]


viewForm : UiSettings -> Model -> Html Msg
viewForm settings model =
    div [ class "ui segment" ]
        [ Html.map YesNoMsg (Comp.YesNoDimmer.view model.deleteConfirm)
        , Html.map FormMsg (Comp.ImapSettingsForm.view settings model.formModel)
        , div
            [ classList
                [ ( "ui error message", True )
                , ( "invisible", model.formError == Nothing )
                ]
            ]
            [ Maybe.withDefault "" model.formError |> text
            ]
        , div [ class "ui divider" ] []
        , button
            [ class "ui primary button"
            , onClick Submit
            , href "#"
            ]
            [ text "Submit"
            ]
        , a
            [ class "ui secondary button"
            , onClick (SetViewMode Table)
            , href ""
            ]
            [ text "Cancel"
            ]
        , if model.formModel.settings.name /= "" then
            a [ class "ui right floated red button", href "", onClick RequestDelete ]
                [ text "Delete" ]

          else
            span [] []
        , div
            [ classList
                [ ( "ui dimmer", True )
                , ( "active", model.loading )
                ]
            ]
            [ div [ class "ui loader" ] []
            ]
        ]
