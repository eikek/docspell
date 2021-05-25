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
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Messages.Comp.UiSettingsManage exposing (Texts)
import Styles as S


type alias Model =
    { formModel : Comp.UiSettingsForm.Model
    , settings : Maybe UiSettings
    , formResult : FormResult
    }


type FormResult
    = FormInit
    | FormUnchanged
    | FormSaved
    | FormHttpError Http.Error
    | FormUnknownError


type Msg
    = UiSettingsFormMsg Comp.UiSettingsForm.Msg
    | Submit
    | UpdateSettings
    | SaveSettingsResp UiSettings (Result Http.Error BasicResult)


init : Flags -> UiSettings -> ( Model, Cmd Msg )
init flags settings =
    let
        ( fm, fc ) =
            Comp.UiSettingsForm.init flags settings
    in
    ( { formModel = fm
      , settings = Nothing
      , formResult = FormInit
      }
    , Cmd.map UiSettingsFormMsg fc
    )



--- update


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
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
            , newSettings = Nothing
            }

        Submit ->
            case model.settings of
                Just s ->
                    { model = { model | formResult = FormInit }
                    , cmd = Api.saveClientSettings flags s (SaveSettingsResp s)
                    , newSettings = Nothing
                    }

                Nothing ->
                    { model = { model | formResult = FormUnchanged }
                    , cmd = Cmd.none
                    , newSettings = Nothing
                    }

        SaveSettingsResp newSettings (Ok res) ->
            if res.success then
                { model = { model | formResult = FormSaved }
                , cmd = Cmd.none
                , newSettings = Just newSettings
                }

            else
                { model = { model | formResult = FormUnknownError }
                , cmd = Cmd.none
                , newSettings = Nothing
                }

        SaveSettingsResp _ (Err err) ->
            UpdateResult { model | formResult = FormHttpError err } Cmd.none Nothing

        UpdateSettings ->
            let
                ( fm, fc ) =
                    Comp.UiSettingsForm.init flags settings
            in
            { model = { model | formModel = fm }
            , cmd = Cmd.map UiSettingsFormMsg fc
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
