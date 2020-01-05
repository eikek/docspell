module Comp.EmailSettingsManage exposing
    ( Model
    , Msg
    , emptyModel
    , init
    , update
    , view
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.EmailSettings exposing (EmailSettings)
import Api.Model.EmailSettingsList exposing (EmailSettingsList)
import Comp.EmailSettingsForm
import Comp.EmailSettingsTable
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)


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


init : ( Model, Cmd Msg )
init =
    ( emptyModel, Cmd.none )


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
            in
            ( { model | tableModel = tm }, Cmd.map TableMsg tc )

        FormMsg m ->
            let
                ( fm, fc ) =
                    Comp.EmailSettingsForm.update m model.formModel
            in
            ( { model | formModel = fm }, Cmd.map FormMsg fc )

        SetQuery str ->
            ( { model | query = str }, Cmd.none )

        YesNoMsg m ->
            let
                ( dm, flag ) =
                    Comp.YesNoDimmer.update m model.deleteConfirm
            in
            ( { model | deleteConfirm = dm }, Cmd.none )

        RequestDelete ->
            ( model, Cmd.none )

        SetViewMode m ->
            ( { model | viewMode = m }, Cmd.none )


view : Model -> Html Msg
view model =
    case model.viewMode of
        Table ->
            viewTable model

        Form ->
            viewForm model


viewTable : Model -> Html Msg
viewTable model =
    div []
        [ div [ class "ui secondary menu container" ]
            [ div [ class "ui container" ]
                [ div [ class "fitted-item" ]
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
                    [ div [ class "fitted-item" ]
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
            ]
        , Html.map TableMsg (Comp.EmailSettingsTable.view model.tableModel)
        ]


viewForm : Model -> Html Msg
viewForm model =
    div [ class "ui segment" ]
        [ Html.map YesNoMsg (Comp.YesNoDimmer.view model.deleteConfirm)
        , Html.map FormMsg (Comp.EmailSettingsForm.view model.formModel)
        , div
            [ classList
                [ ( "ui error message", True )
                , ( "invisible", model.formError == Nothing )
                ]
            ]
            [ Maybe.withDefault "" model.formError |> text
            ]
        , div [ class "ui divider" ] []
        , button [ class "ui primary button" ]
            [ text "Submit"
            ]
        , a [ class "ui secondary button", onClick (SetViewMode Table), href "" ]
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
