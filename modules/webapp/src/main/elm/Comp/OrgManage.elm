{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Comp.OrgManage exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view2
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.Organization
import Api.Model.OrganizationList exposing (OrganizationList)
import Comp.Basic as B
import Comp.MenuBar as MB
import Comp.OrgForm
import Comp.OrgTable
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onSubmit)
import Http
import Messages.Comp.OrgManage exposing (Texts)
import Styles as S
import Util.Maybe


type alias Model =
    { tableModel : Comp.OrgTable.Model
    , formModel : Comp.OrgForm.Model
    , viewMode : ViewMode
    , formError : FormError
    , loading : Bool
    , deleteConfirm : Comp.YesNoDimmer.Model
    , query : String
    }


type FormError
    = FormErrorNone
    | FormErrorHttp Http.Error
    | FormErrorSubmit String
    | FormErrorInvalid


type ViewMode
    = Table
    | Form


emptyModel : Model
emptyModel =
    { tableModel = Comp.OrgTable.emptyModel
    , formModel = Comp.OrgForm.emptyModel
    , viewMode = Table
    , formError = FormErrorNone
    , loading = False
    , deleteConfirm = Comp.YesNoDimmer.emptyModel
    , query = ""
    }


type Msg
    = TableMsg Comp.OrgTable.Msg
    | FormMsg Comp.OrgForm.Msg
    | LoadOrgs
    | OrgResp (Result Http.Error OrganizationList)
    | SetViewMode ViewMode
    | InitNewOrg
    | Submit
    | SubmitResp (Result Http.Error BasicResult)
    | YesNoMsg Comp.YesNoDimmer.Msg
    | RequestDelete
    | SetQuery String


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        TableMsg m ->
            let
                ( tm, tc ) =
                    Comp.OrgTable.update flags m model.tableModel

                ( m2, c2 ) =
                    ( { model
                        | tableModel = tm
                        , viewMode = Maybe.map (\_ -> Form) tm.selected |> Maybe.withDefault Table
                        , formError =
                            if Util.Maybe.nonEmpty tm.selected then
                                FormErrorNone

                            else
                                model.formError
                      }
                    , Cmd.map TableMsg tc
                    )

                ( m3, c3 ) =
                    case tm.selected of
                        Just org ->
                            update flags (FormMsg (Comp.OrgForm.SetOrg org)) m2

                        Nothing ->
                            ( m2, Cmd.none )
            in
            ( m3, Cmd.batch [ c2, c3 ] )

        FormMsg m ->
            let
                ( m2, c2 ) =
                    Comp.OrgForm.update flags m model.formModel
            in
            ( { model | formModel = m2 }, Cmd.map FormMsg c2 )

        LoadOrgs ->
            ( { model | loading = True }, Api.getOrganizations flags model.query OrgResp )

        OrgResp (Ok orgs) ->
            let
                m2 =
                    { model | viewMode = Table, loading = False }
            in
            update flags (TableMsg (Comp.OrgTable.SetOrgs orgs.items)) m2

        OrgResp (Err _) ->
            ( { model | loading = False }, Cmd.none )

        SetViewMode m ->
            let
                m2 =
                    { model | viewMode = m }
            in
            case m of
                Table ->
                    update flags (TableMsg Comp.OrgTable.Deselect) m2

                Form ->
                    ( m2, Cmd.none )

        InitNewOrg ->
            let
                nm =
                    { model | viewMode = Form, formError = FormErrorNone }

                org =
                    Api.Model.Organization.empty
            in
            update flags (FormMsg (Comp.OrgForm.SetOrg org)) nm

        Submit ->
            let
                org =
                    Comp.OrgForm.getOrg model.formModel

                valid =
                    Comp.OrgForm.isValid model.formModel
            in
            if valid then
                ( { model | loading = True }, Api.postOrg flags org SubmitResp )

            else
                ( { model | formError = FormErrorInvalid }, Cmd.none )

        SubmitResp (Ok res) ->
            if res.success then
                let
                    ( m2, c2 ) =
                        update flags (SetViewMode Table) model

                    ( m3, c3 ) =
                        update flags LoadOrgs m2
                in
                ( { m3 | loading = False }, Cmd.batch [ c2, c3 ] )

            else
                ( { model | formError = FormErrorSubmit res.message, loading = False }, Cmd.none )

        SubmitResp (Err err) ->
            ( { model | formError = FormErrorHttp err, loading = False }, Cmd.none )

        RequestDelete ->
            update flags (YesNoMsg Comp.YesNoDimmer.activate) model

        YesNoMsg m ->
            let
                ( cm, confirmed ) =
                    Comp.YesNoDimmer.update m model.deleteConfirm

                org =
                    Comp.OrgForm.getOrg model.formModel

                cmd =
                    if confirmed then
                        Api.deleteOrg flags org.id SubmitResp

                    else
                        Cmd.none
            in
            ( { model | deleteConfirm = cm }, cmd )

        SetQuery str ->
            let
                m =
                    { model | query = str }
            in
            ( m, Api.getOrganizations flags str OrgResp )



--- View2


view2 : Texts -> UiSettings -> Model -> Html Msg
view2 texts settings model =
    if model.viewMode == Table then
        viewTable2 texts model

    else
        viewForm2 texts settings model


viewTable2 : Texts -> Model -> Html Msg
viewTable2 texts model =
    div [ class "flex flex-col relative" ]
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
                    { tagger = InitNewOrg
                    , title = texts.createNewOrganization
                    , icon = Just "fa fa-plus"
                    , label = texts.newOrganization
                    }
                ]
            , rootClasses = "mb-4"
            }
        , Html.map TableMsg (Comp.OrgTable.view2 texts.orgTable model.tableModel)
        , B.loadingDimmer
            { active = model.loading
            , label = texts.basics.loading
            }
        ]


viewForm2 : Texts -> UiSettings -> Model -> Html Msg
viewForm2 texts settings model =
    let
        newOrg =
            model.formModel.org.id == ""

        dimmerSettings2 =
            Comp.YesNoDimmer.defaultSettings texts.reallyDeleteOrg
                texts.basics.yes
                texts.basics.no
    in
    Html.form
        [ class "md:relative flex flex-col"
        , onSubmit Submit
        ]
        [ Html.map YesNoMsg
            (Comp.YesNoDimmer.viewN
                True
                dimmerSettings2
                model.deleteConfirm
            )
        , if newOrg then
            h3 [ class S.header2 ]
                [ text texts.createNewOrganization
                ]

          else
            h3 [ class S.header2 ]
                [ text model.formModel.org.name
                , div [ class "opacity-50 text-sm" ]
                    [ text (texts.basics.id ++ ": ")
                    , text model.formModel.org.id
                    ]
                ]
        , MB.view
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
                if not newOrg then
                    [ MB.DeleteButton
                        { tagger = RequestDelete
                        , title = texts.deleteThisOrg
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
            , class S.errorMessage
            , class "my-2"
            ]
            [ case model.formError of
                FormErrorNone ->
                    text ""

                FormErrorSubmit m ->
                    text m

                FormErrorHttp err ->
                    text (texts.httpError err)

                FormErrorInvalid ->
                    text texts.correctFormErrors
            ]
        , Html.map FormMsg
            (Comp.OrgForm.view2
                texts.orgForm
                False
                settings
                model.formModel
            )
        , B.loadingDimmer
            { active = model.loading
            , label = texts.basics.loading
            }
        ]
