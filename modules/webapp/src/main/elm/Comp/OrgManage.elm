module Comp.OrgManage exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view
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
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Styles as S
import Util.Http
import Util.Maybe


type alias Model =
    { tableModel : Comp.OrgTable.Model
    , formModel : Comp.OrgForm.Model
    , viewMode : ViewMode
    , formError : Maybe String
    , loading : Bool
    , deleteConfirm : Comp.YesNoDimmer.Model
    , query : String
    }


type ViewMode
    = Table
    | Form


emptyModel : Model
emptyModel =
    { tableModel = Comp.OrgTable.emptyModel
    , formModel = Comp.OrgForm.emptyModel
    , viewMode = Table
    , formError = Nothing
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
                                Nothing

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
                    { model | viewMode = Form, formError = Nothing }

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
                ( { model | formError = Just "Please correct the errors in the form." }, Cmd.none )

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
                ( { model | formError = Just res.message, loading = False }, Cmd.none )

        SubmitResp (Err err) ->
            ( { model | formError = Just (Util.Http.errorToString err), loading = False }, Cmd.none )

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


view : UiSettings -> Model -> Html Msg
view settings model =
    if model.viewMode == Table then
        viewTable model

    else
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
                        , onClick InitNewOrg
                        ]
                        [ i [ class "plus icon" ] []
                        , text "New Organization"
                        ]
                    ]
                ]
            ]
        , Html.map TableMsg (Comp.OrgTable.view model.tableModel)
        , div
            [ classList
                [ ( "ui dimmer", True )
                , ( "active", model.loading )
                ]
            ]
            [ div [ class "ui loader" ] []
            ]
        ]


viewForm : UiSettings -> Model -> Html Msg
viewForm settings model =
    let
        newOrg =
            model.formModel.org.id == ""
    in
    Html.form [ class "ui segment", onSubmit Submit ]
        [ Html.map YesNoMsg (Comp.YesNoDimmer.view model.deleteConfirm)
        , if newOrg then
            h3 [ class "ui dividing header" ]
                [ text "Create new organization"
                ]

          else
            h3 [ class "ui dividing header" ]
                [ text ("Edit org: " ++ model.formModel.org.name)
                , div [ class "sub header" ]
                    [ text "Id: "
                    , text model.formModel.org.id
                    ]
                ]
        , Html.map FormMsg (Comp.OrgForm.view settings model.formModel)
        , div
            [ classList
                [ ( "ui error message", True )
                , ( "invisible", Util.Maybe.isEmpty model.formError )
                ]
            ]
            [ Maybe.withDefault "" model.formError |> text
            ]
        , div [ class "ui horizontal divider" ] []
        , button [ class "ui primary button", type_ "submit" ]
            [ text "Submit"
            ]
        , a [ class "ui secondary button", onClick (SetViewMode Table), href "#" ]
            [ text "Cancel"
            ]
        , if not newOrg then
            a [ class "ui right floated red button", href "#", onClick RequestDelete ]
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



--- View2


view2 : UiSettings -> Model -> Html Msg
view2 settings model =
    if model.viewMode == Table then
        viewTable2 model

    else
        viewForm2 settings model


viewTable2 : Model -> Html Msg
viewTable2 model =
    div [ class "flex flex-col relative" ]
        [ MB.view
            { start =
                [ MB.TextInput
                    { tagger = SetQuery
                    , value = model.query
                    , placeholder = "Search…"
                    , icon = Just "fa fa-search"
                    }
                ]
            , end =
                [ MB.PrimaryButton
                    { tagger = InitNewOrg
                    , title = "Create a new organization"
                    , icon = Just "fa fa-plus"
                    , label = "New Organization"
                    }
                ]
            , rootClasses = "mb-4"
            }
        , Html.map TableMsg (Comp.OrgTable.view2 model.tableModel)
        , B.loadingDimmer model.loading
        ]


viewForm2 : UiSettings -> Model -> Html Msg
viewForm2 settings model =
    let
        newOrg =
            model.formModel.org.id == ""

        dimmerSettings2 =
            Comp.YesNoDimmer.defaultSettings2 "Really delete this organization?"
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
                [ text "Create new organization"
                ]

          else
            h3 [ class S.header2 ]
                [ text model.formModel.org.name
                , div [ class "opacity-50 text-sm" ]
                    [ text "Id: "
                    , text model.formModel.org.id
                    ]
                ]
        , MB.view
            { start =
                [ MB.PrimaryButton
                    { tagger = Submit
                    , title = "Submit this form"
                    , icon = Just "fa fa-save"
                    , label = "Submit"
                    }
                , MB.SecondaryButton
                    { tagger = SetViewMode Table
                    , title = "Back to list"
                    , icon = Just "fa fa-arrow-left"
                    , label = "Cancel"
                    }
                ]
            , end =
                if not newOrg then
                    [ MB.DeleteButton
                        { tagger = RequestDelete
                        , title = "Delete this organization"
                        , icon = Just "fa fa-trash"
                        , label = "Delete"
                        }
                    ]

                else
                    []
            , rootClasses = "mb-4"
            }
        , Html.map FormMsg (Comp.OrgForm.view2 False settings model.formModel)
        , div
            [ classList
                [ ( "hidden", Util.Maybe.isEmpty model.formError )
                ]
            , class S.errorMessage
            ]
            [ Maybe.withDefault "" model.formError |> text
            ]
        , B.loadingDimmer model.loading
        ]
