{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.UiSettingsManage exposing
    ( Model
    , Msg(..)
    , UpdateResult
    , init
    , update
    , view2
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Comp.Basic
import Comp.MenuBar as MB
import Comp.UiSettingsForm
import Data.AccountScope exposing (AccountScope)
import Data.AppEvent exposing (AppEvent(..))
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (StoredUiSettings, UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Messages.Comp.UiSettingsManage exposing (Texts)
import Page.Search.Data exposing (Msg(..))
import Process
import Styles as S
import Task


type alias Model =
    { formModel : FormView
    , formResult : FormResult
    , formData : Maybe FormData
    }


type alias FormData =
    { userSettings : StoredUiSettings
    , userModel : Comp.UiSettingsForm.Model
    , collSettings : StoredUiSettings
    , collModel : Comp.UiSettingsForm.Model
    }


type FormView
    = ViewLoading
    | ViewUser
    | ViewCollective


type FormResult
    = FormInit
    | FormUnchanged
    | FormSaved
    | FormHttpError Http.Error
    | FormUnknownError


type Msg
    = UiFormMsg AccountScope Comp.UiSettingsForm.Msg
    | Submit
    | SaveSettingsResp (Result Http.Error BasicResult)
    | ReceiveServerSettings (Result Http.Error ( StoredUiSettings, StoredUiSettings ))
    | ToggleExpandCollapse
    | SwitchForm AccountScope
    | ResetFormState


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { formModel = ViewLoading
      , formData = Nothing
      , formResult = FormInit
      }
    , Cmd.batch
        [ Api.getClientSettingsRaw flags ReceiveServerSettings
        ]
    )


getViewScope : Model -> AccountScope
getViewScope model =
    case model.formModel of
        ViewCollective ->
            Data.AccountScope.Collective

        ViewUser ->
            Data.AccountScope.User

        _ ->
            Data.AccountScope.User



--- update


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    , appEvent : AppEvent
    }


unit : Model -> UpdateResult
unit model =
    UpdateResult model Cmd.none Sub.none AppNothing


update : Flags -> UiSettings -> Msg -> Model -> UpdateResult
update flags settings msg model =
    case msg of
        UiFormMsg scope lm ->
            case model.formData of
                Nothing ->
                    unit model

                Just data ->
                    case scope of
                        Data.AccountScope.Collective ->
                            let
                                ( m_, sett ) =
                                    Comp.UiSettingsForm.update flags data.collSettings lm data.collModel
                            in
                            unit
                                { model
                                    | formData =
                                        Just
                                            { data
                                                | collSettings = Maybe.withDefault data.collSettings sett
                                                , collModel = m_
                                            }
                                }

                        Data.AccountScope.User ->
                            let
                                ( m_, sett ) =
                                    Comp.UiSettingsForm.update flags data.userSettings lm data.userModel
                            in
                            unit
                                { model
                                    | formData =
                                        Just
                                            { data
                                                | userSettings = Maybe.withDefault data.userSettings sett
                                                , userModel = m_
                                            }
                                }

        Submit ->
            case ( model.formModel, model.formData ) of
                ( ViewCollective, Just data ) ->
                    { model = { model | formResult = FormInit }
                    , cmd =
                        Api.saveClientSettings flags
                            data.collSettings
                            Data.AccountScope.Collective
                            SaveSettingsResp
                    , sub = Sub.none
                    , appEvent = AppNothing
                    }

                ( ViewUser, Just data ) ->
                    { model = { model | formResult = FormInit }
                    , cmd =
                        Api.saveClientSettings flags
                            data.userSettings
                            Data.AccountScope.User
                            SaveSettingsResp
                    , sub = Sub.none
                    , appEvent = AppNothing
                    }

                _ ->
                    unit model

        SaveSettingsResp (Ok res) ->
            case ( res.success, model.formData ) of
                ( True, Just data ) ->
                    let
                        result =
                            update flags
                                settings
                                (ReceiveServerSettings (Ok ( data.collSettings, data.userSettings )))
                                { model | formResult = FormSaved }

                        cmd =
                            Process.sleep 2000
                                |> Task.perform (\_ -> ResetFormState)
                    in
                    { result | appEvent = AppReloadUiSettings, cmd = Cmd.batch [ cmd, result.cmd ] }

                _ ->
                    unit { model | formResult = FormUnknownError }

        SaveSettingsResp (Err err) ->
            UpdateResult { model | formResult = FormHttpError err } Cmd.none Sub.none AppNothing

        ReceiveServerSettings (Ok ( coll, user )) ->
            let
                collDefaults =
                    Data.UiSettings.defaults

                userDefaults =
                    Data.UiSettings.merge coll collDefaults

                ( ( um, uc ), ( cm, cc ) ) =
                    case model.formData of
                        Just data ->
                            ( Comp.UiSettingsForm.initData flags user userDefaults data.userModel
                            , Comp.UiSettingsForm.initData flags coll collDefaults data.collModel
                            )

                        Nothing ->
                            ( Comp.UiSettingsForm.init flags user userDefaults
                            , Comp.UiSettingsForm.init flags coll collDefaults
                            )

                model_ =
                    { model
                        | formData =
                            Just
                                { userSettings = user
                                , userModel = um
                                , collSettings = coll
                                , collModel = cm
                                }
                        , formModel =
                            case model.formModel of
                                ViewLoading ->
                                    ViewUser

                                _ ->
                                    model.formModel
                    }

                cmds =
                    Cmd.batch
                        [ Cmd.map (UiFormMsg Data.AccountScope.User) uc
                        , Cmd.map (UiFormMsg Data.AccountScope.Collective) cc
                        ]
            in
            UpdateResult model_ cmds Sub.none AppNothing

        ReceiveServerSettings (Err err) ->
            unit { model | formResult = FormHttpError err }

        ToggleExpandCollapse ->
            let
                lm =
                    UiFormMsg (getViewScope model) Comp.UiSettingsForm.toggleAllTabs
            in
            update flags settings lm model

        SwitchForm scope ->
            let
                forUser =
                    unit { model | formModel = ViewUser }

                forColl =
                    unit { model | formModel = ViewCollective }
            in
            Data.AccountScope.fold forUser forColl scope

        ResetFormState ->
            case model.formResult of
                FormSaved ->
                    unit { model | formResult = FormInit }

                _ ->
                    unit model


isError : Model -> Bool
isError model =
    case model.formResult of
        FormSaved ->
            False

        FormInit ->
            False

        FormUnchanged ->
            True

        FormHttpError _ ->
            True

        FormUnknownError ->
            True


isSuccess : Model -> Bool
isSuccess model =
    not (isError model)


view2 : Texts -> Flags -> UiSettings -> String -> Model -> Html Msg
view2 texts flags _ classes model =
    let
        scope =
            getViewScope model
    in
    div [ class classes ]
        [ MB.view
            { start =
                [ MB.PrimaryButton
                    { tagger = Submit
                    , label = texts.basics.submit
                    , title = texts.saveSettings
                    , icon = Just "fa fa-save"
                    }
                , MB.SecondaryButton
                    { tagger = ToggleExpandCollapse
                    , label = ""
                    , title = texts.expandCollapse
                    , icon = Just "fa fa-compress"
                    }
                ]
            , end =
                [ MB.RadioButton
                    { tagger = \_ -> SwitchForm Data.AccountScope.User
                    , label = texts.accountScope Data.AccountScope.User
                    , value = Data.AccountScope.fold True False scope
                    , id = "ui-settings-chooser-user"
                    }
                , MB.RadioButton
                    { tagger = \_ -> SwitchForm Data.AccountScope.Collective
                    , label = texts.accountScope Data.AccountScope.Collective
                    , value = Data.AccountScope.fold False True scope
                    , id = "ui-settings-chooser-collective"
                    }
                ]
            , rootClasses = "mb-4"
            }
        , div
            [ classList
                [ ( S.successMessage, isSuccess model )
                , ( S.errorMessage, isError model )
                , ( "hidden", model.formResult == FormInit )
                ]
            ]
            [ case model.formResult of
                FormInit ->
                    text ""

                FormUnchanged ->
                    text texts.settingsUnchanged

                FormHttpError err ->
                    text (texts.httpError err)

                FormSaved ->
                    text texts.settingsSaved

                FormUnknownError ->
                    text texts.unknownSaveError
            ]
        , case model.formModel of
            ViewLoading ->
                div [ class "h-24 md:relative" ]
                    [ Comp.Basic.loadingDimmer
                        { label = ""
                        , active = True
                        }
                    ]

            ViewCollective ->
                case model.formData of
                    Just data ->
                        div []
                            [ h2 [ class S.header2 ]
                                [ text texts.collectiveHeader
                                ]
                            , div [ class "py-1 opacity-80" ]
                                [ text texts.collectiveInfo
                                ]
                            , Html.map (UiFormMsg scope)
                                (Comp.UiSettingsForm.view2
                                    texts.uiSettingsForm
                                    flags
                                    data.collSettings
                                    data.collModel
                                )
                            ]

                    Nothing ->
                        span [ class "hidden" ] []

            ViewUser ->
                case model.formData of
                    Just data ->
                        div []
                            [ h2 [ class S.header2 ]
                                [ text texts.userHeader
                                ]
                            , div [ class "py-1 opacity-80" ]
                                [ text texts.userInfo
                                ]
                            , Html.map (UiFormMsg scope)
                                (Comp.UiSettingsForm.view2 texts.uiSettingsForm
                                    flags
                                    data.userSettings
                                    data.userModel
                                )
                            ]

                    Nothing ->
                        span [ class "hidden" ] []
        ]
