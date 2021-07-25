{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
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
import Comp.MenuBar as MB
import Comp.UiSettingsForm
import Comp.UiSettingsMigrate
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (StoredUiSettings, UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Messages.Comp.UiSettingsManage exposing (Texts)
import Styles as S


type alias Model =
    { formModel : Comp.UiSettingsForm.Model
    , settings : Maybe UiSettings
    , formResult : FormResult
    , settingsMigrate : Comp.UiSettingsMigrate.Model
    }


type FormResult
    = FormInit
    | FormUnchanged
    | FormSaved
    | FormHttpError Http.Error
    | FormUnknownError


type Msg
    = UiSettingsFormMsg Comp.UiSettingsForm.Msg
    | UiSettingsMigrateMsg Comp.UiSettingsMigrate.Msg
    | Submit
    | UpdateSettings
    | SaveSettingsResp UiSettings (Result Http.Error BasicResult)
    | ReceiveBrowserSettings StoredUiSettings


init : Flags -> UiSettings -> ( Model, Cmd Msg )
init flags settings =
    let
        ( fm, fc ) =
            Comp.UiSettingsForm.init flags settings

        ( mm, mc ) =
            Comp.UiSettingsMigrate.init flags
    in
    ( { formModel = fm
      , settings = Nothing
      , formResult = FormInit
      , settingsMigrate = mm
      }
    , Cmd.batch
        [ Cmd.map UiSettingsFormMsg fc
        , Cmd.map UiSettingsMigrateMsg mc
        ]
    )



--- update


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    , newSettings : Maybe UiSettings
    }


update : Flags -> UiSettings -> Msg -> Model -> UpdateResult
update flags settings msg model =
    case msg of
        UiSettingsFormMsg lm ->
            let
                inSettings =
                    Maybe.withDefault settings model.settings

                ( m_, sett ) =
                    Comp.UiSettingsForm.update inSettings lm model.formModel
            in
            { model =
                { model
                    | formModel = m_
                    , settings =
                        if sett == Nothing then
                            model.settings

                        else
                            sett
                    , formResult =
                        if sett /= Nothing then
                            FormInit

                        else
                            model.formResult
                }
            , cmd = Cmd.none
            , sub = Sub.none
            , newSettings = Nothing
            }

        UiSettingsMigrateMsg lm ->
            let
                result =
                    Comp.UiSettingsMigrate.update flags lm model.settingsMigrate
            in
            { model = { model | settingsMigrate = result.model }
            , cmd = Cmd.map UiSettingsMigrateMsg result.cmd
            , sub = Sub.map UiSettingsMigrateMsg result.sub
            , newSettings = result.newSettings
            }

        ReceiveBrowserSettings sett ->
            let
                lm =
                    UiSettingsMigrateMsg (Comp.UiSettingsMigrate.receiveBrowserSettings sett)
            in
            update flags settings lm model

        Submit ->
            case model.settings of
                Just s ->
                    { model = { model | formResult = FormInit }
                    , cmd = Api.saveClientSettings flags s (SaveSettingsResp s)
                    , sub = Sub.none
                    , newSettings = Nothing
                    }

                Nothing ->
                    { model = { model | formResult = FormUnchanged }
                    , cmd = Cmd.none
                    , sub = Sub.none
                    , newSettings = Nothing
                    }

        SaveSettingsResp newSettings (Ok res) ->
            if res.success then
                { model = { model | formResult = FormSaved }
                , cmd = Cmd.none
                , sub = Sub.none
                , newSettings = Just newSettings
                }

            else
                { model = { model | formResult = FormUnknownError }
                , cmd = Cmd.none
                , sub = Sub.none
                , newSettings = Nothing
                }

        SaveSettingsResp _ (Err err) ->
            UpdateResult { model | formResult = FormHttpError err } Cmd.none Sub.none Nothing

        UpdateSettings ->
            let
                ( fm, fc ) =
                    Comp.UiSettingsForm.init flags settings
            in
            { model = { model | formModel = fm }
            , cmd = Cmd.map UiSettingsFormMsg fc
            , sub = Sub.none
            , newSettings = Nothing
            }



--- View2


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
view2 texts flags settings classes model =
    div [ class classes ]
        [ MB.view
            { start =
                [ MB.PrimaryButton
                    { tagger = Submit
                    , label = texts.basics.submit
                    , title = texts.saveSettings
                    , icon = Just "fa fa-save"
                    }
                ]
            , end = []
            , rootClasses = "mb-4"
            }
        , div []
            [ Html.map UiSettingsMigrateMsg
                (Comp.UiSettingsMigrate.view model.settingsMigrate)
            ]
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
        , Html.map UiSettingsFormMsg
            (Comp.UiSettingsForm.view2
                texts.uiSettingsForm
                flags
                settings
                model.formModel
            )
        ]
