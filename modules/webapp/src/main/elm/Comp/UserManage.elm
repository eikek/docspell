{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Comp.UserManage exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view2
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.User
import Api.Model.UserList exposing (UserList)
import Comp.Basic as B
import Comp.MenuBar as MB
import Comp.UserForm
import Comp.UserTable
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onSubmit)
import Http
import Messages.Comp.UserManage exposing (Texts)
import Styles as S
import Util.Maybe


type alias Model =
    { tableModel : Comp.UserTable.Model
    , formModel : Comp.UserForm.Model
    , viewMode : ViewMode
    , formError : FormError
    , loading : Bool
    , deleteConfirm : Comp.YesNoDimmer.Model
    }


type ViewMode
    = Table
    | Form


type FormError
    = FormErrorNone
    | FormErrorSubmit String
    | FormErrorHttp Http.Error
    | FormErrorInvalid


emptyModel : Model
emptyModel =
    { tableModel = Comp.UserTable.emptyModel
    , formModel = Comp.UserForm.emptyModel
    , viewMode = Table
    , formError = FormErrorNone
    , loading = False
    , deleteConfirm = Comp.YesNoDimmer.emptyModel
    }


type Msg
    = TableMsg Comp.UserTable.Msg
    | FormMsg Comp.UserForm.Msg
    | LoadUsers
    | UserResp (Result Http.Error UserList)
    | SetViewMode ViewMode
    | InitNewUser
    | Submit
    | SubmitResp (Result Http.Error BasicResult)
    | YesNoMsg Comp.YesNoDimmer.Msg
    | RequestDelete


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        TableMsg m ->
            let
                ( tm, tc ) =
                    Comp.UserTable.update flags m model.tableModel

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
                        Just user ->
                            update flags (FormMsg (Comp.UserForm.SetUser user)) m2

                        Nothing ->
                            ( m2, Cmd.none )
            in
            ( m3, Cmd.batch [ c2, c3 ] )

        FormMsg m ->
            let
                ( m2, c2 ) =
                    Comp.UserForm.update flags m model.formModel
            in
            ( { model | formModel = m2 }, Cmd.map FormMsg c2 )

        LoadUsers ->
            ( { model | loading = True }, Api.getUsers flags UserResp )

        UserResp (Ok users) ->
            let
                m2 =
                    { model | viewMode = Table, loading = False }
            in
            update flags (TableMsg (Comp.UserTable.SetUsers users.items)) m2

        UserResp (Err _) ->
            ( { model | loading = False }, Cmd.none )

        SetViewMode m ->
            let
                m2 =
                    { model | viewMode = m }
            in
            case m of
                Table ->
                    update flags (TableMsg Comp.UserTable.Deselect) m2

                Form ->
                    ( m2, Cmd.none )

        InitNewUser ->
            let
                nm =
                    { model | viewMode = Form, formError = FormErrorNone }

                user =
                    Api.Model.User.empty
            in
            update flags (FormMsg (Comp.UserForm.SetUser user)) nm

        Submit ->
            let
                user =
                    Comp.UserForm.getUser model.formModel

                valid =
                    Comp.UserForm.isValid model.formModel

                cmd =
                    if Comp.UserForm.isNewUser model.formModel then
                        Api.postNewUser flags user SubmitResp

                    else
                        Api.putUser flags user SubmitResp
            in
            if valid then
                ( { model | loading = True }, cmd )

            else
                ( { model | formError = FormErrorInvalid }, Cmd.none )

        SubmitResp (Ok res) ->
            if res.success then
                let
                    ( m2, c2 ) =
                        update flags (SetViewMode Table) model

                    ( m3, c3 ) =
                        update flags LoadUsers m2
                in
                ( { m3 | loading = False }, Cmd.batch [ c2, c3 ] )

            else
                ( { model | formError = FormErrorSubmit res.message, loading = False }, Cmd.none )

        SubmitResp (Err err) ->
            ( { model
                | formError = FormErrorHttp err
                , loading = False
              }
            , Cmd.none
            )

        RequestDelete ->
            update flags (YesNoMsg Comp.YesNoDimmer.activate) model

        YesNoMsg m ->
            let
                ( cm, confirmed ) =
                    Comp.YesNoDimmer.update m model.deleteConfirm

                user =
                    Comp.UserForm.getUser model.formModel

                cmd =
                    if confirmed then
                        Api.deleteUser flags user.login SubmitResp

                    else
                        Cmd.none
            in
            ( { model | deleteConfirm = cm }, cmd )



--- View2


view2 : Texts -> UiSettings -> Model -> Html Msg
view2 texts settings model =
    if model.viewMode == Table then
        viewTable2 texts model

    else
        viewForm2 texts settings model


viewTable2 : Texts -> Model -> Html Msg
viewTable2 texts model =
    div [ class "flex flex-col" ]
        [ MB.view
            { start = []
            , end =
                [ MB.PrimaryButton
                    { tagger = InitNewUser
                    , title = texts.addNewUser
                    , icon = Just "fa fa-plus"
                    , label = texts.newUser
                    }
                ]
            , rootClasses = "mb-4"
            }
        , Html.map TableMsg (Comp.UserTable.view2 texts.userTable model.tableModel)
        , B.loadingDimmer
            { active = model.loading
            , label = texts.basics.loading
            }
        ]


viewForm2 : Texts -> UiSettings -> Model -> Html Msg
viewForm2 texts settings model =
    let
        newUser =
            Comp.UserForm.isNewUser model.formModel

        dimmerSettings : Comp.YesNoDimmer.Settings
        dimmerSettings =
            Comp.YesNoDimmer.defaultSettings texts.reallyDeleteUser
                texts.basics.yes
                texts.basics.no
    in
    Html.form
        [ class "flex flex-col md:relative"
        , onSubmit Submit
        ]
        [ Html.map YesNoMsg
            (Comp.YesNoDimmer.viewN True
                dimmerSettings
                model.deleteConfirm
            )
        , if newUser then
            h3 [ class S.header2 ]
                [ text texts.createNewUser
                ]

          else
            h3 [ class S.header2 ]
                [ text model.formModel.user.login
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
                if not newUser then
                    [ MB.DeleteButton
                        { tagger = RequestDelete
                        , title = texts.deleteThisUser
                        , icon = Just "fa fa-trash"
                        , label = texts.basics.delete
                        }
                    ]

                else
                    []
            , rootClasses = "mb-4"
            }
        , Html.map FormMsg (Comp.UserForm.view2 texts.userForm settings model.formModel)
        , div
            [ classList
                [ ( "hidden", model.formError == FormErrorNone )
                ]
            , class S.errorMessage
            ]
            [ case model.formError of
                FormErrorNone ->
                    text ""

                FormErrorSubmit err ->
                    text err

                FormErrorHttp err ->
                    text (texts.httpError err)

                FormErrorInvalid ->
                    text texts.pleaseCorrectErrors
            ]
        , B.loadingDimmer
            { active = model.loading
            , label = texts.basics.loading
            }
        ]
