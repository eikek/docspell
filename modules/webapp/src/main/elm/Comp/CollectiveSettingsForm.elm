{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Comp.CollectiveSettingsForm exposing
    ( Model
    , Msg
    , getSettings
    , init
    , update
    , view2
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.CollectiveSettings exposing (CollectiveSettings)
import Comp.Basic as B
import Comp.ClassifierSettingsForm
import Comp.Dropdown
import Comp.MenuBar as MB
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Data.Language exposing (Language)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
import Http
import Messages.Comp.CollectiveSettingsForm exposing (Texts)
import Styles as S


type alias Model =
    { langModel : Comp.Dropdown.Model Language
    , intEnabled : Bool
    , initSettings : CollectiveSettings
    , fullTextConfirmText : String
    , fullTextReIndexResult : FulltextReindexResult
    , classifierModel : Comp.ClassifierSettingsForm.Model
    , startClassifierResult : ClassifierResult
    }


type ClassifierResult
    = ClassifierResultInitial
    | ClassifierResultHttpError Http.Error
    | ClassifierResultSubmitError String
    | ClassifierResultOk


type FulltextReindexResult
    = FulltextReindexInitial
    | FulltextReindexHttpError Http.Error
    | FulltextReindexSubmitError String
    | FulltextReindexSubmitOk
    | FulltextReindexOKMissing


init : Flags -> CollectiveSettings -> ( Model, Cmd Msg )
init flags settings =
    let
        lang =
            Data.Language.fromString settings.language
                |> Maybe.withDefault Data.Language.German

        ( cm, cc ) =
            Comp.ClassifierSettingsForm.init flags settings.classifier
    in
    ( { langModel =
            Comp.Dropdown.makeSingleList
                { options = Data.Language.all
                , selected = Just lang
                }
      , intEnabled = settings.integrationEnabled
      , initSettings = settings
      , fullTextConfirmText = ""
      , fullTextReIndexResult = FulltextReindexInitial
      , classifierModel = cm
      , startClassifierResult = ClassifierResultInitial
      }
    , Cmd.map ClassifierSettingMsg cc
    )


getSettings : Model -> Maybe CollectiveSettings
getSettings model =
    Maybe.map
        (\cls ->
            { language =
                Comp.Dropdown.getSelected model.langModel
                    |> List.head
                    |> Maybe.map Data.Language.toIso3
                    |> Maybe.withDefault model.initSettings.language
            , integrationEnabled = model.intEnabled
            , classifier = cls
            }
        )
        (Comp.ClassifierSettingsForm.getSettings
            model.classifierModel
        )


type Msg
    = LangDropdownMsg (Comp.Dropdown.Msg Language)
    | ToggleIntegrationEndpoint
    | SetFullTextConfirm String
    | TriggerReIndex
    | TriggerReIndexResult (Result Http.Error BasicResult)
    | ClassifierSettingMsg Comp.ClassifierSettingsForm.Msg
    | SaveSettings
    | StartClassifierTask
    | StartClassifierResp (Result Http.Error BasicResult)


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Maybe CollectiveSettings )
update flags msg model =
    case msg of
        LangDropdownMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.langModel

                nextModel =
                    { model | langModel = m2 }
            in
            ( nextModel, Cmd.map LangDropdownMsg c2, Nothing )

        ToggleIntegrationEndpoint ->
            let
                nextModel =
                    { model | intEnabled = not model.intEnabled }
            in
            ( nextModel, Cmd.none, Nothing )

        SetFullTextConfirm str ->
            ( { model | fullTextConfirmText = str }, Cmd.none, Nothing )

        TriggerReIndex ->
            case String.toLower model.fullTextConfirmText of
                "ok" ->
                    ( { model | fullTextReIndexResult = FulltextReindexInitial }
                    , Api.startReIndex flags TriggerReIndexResult
                    , Nothing
                    )

                _ ->
                    ( { model
                        | fullTextReIndexResult = FulltextReindexOKMissing
                      }
                    , Cmd.none
                    , Nothing
                    )

        TriggerReIndexResult (Ok br) ->
            ( { model
                | fullTextReIndexResult =
                    if br.success then
                        FulltextReindexSubmitOk

                    else
                        FulltextReindexSubmitError br.message
              }
            , Cmd.none
            , Nothing
            )

        TriggerReIndexResult (Err err) ->
            ( { model
                | fullTextReIndexResult =
                    FulltextReindexHttpError err
              }
            , Cmd.none
            , Nothing
            )

        ClassifierSettingMsg lmsg ->
            let
                ( cm, cc ) =
                    Comp.ClassifierSettingsForm.update flags lmsg model.classifierModel
            in
            ( { model
                | classifierModel = cm
              }
            , Cmd.map ClassifierSettingMsg cc
            , Nothing
            )

        SaveSettings ->
            case getSettings model of
                Just s ->
                    ( model, Cmd.none, Just s )

                Nothing ->
                    ( model, Cmd.none, Nothing )

        StartClassifierTask ->
            ( model, Api.startClassifier flags StartClassifierResp, Nothing )

        StartClassifierResp (Ok br) ->
            ( { model
                | startClassifierResult =
                    if br.success then
                        ClassifierResultOk

                    else
                        ClassifierResultSubmitError br.message
              }
            , Cmd.none
            , Nothing
            )

        StartClassifierResp (Err err) ->
            ( { model | startClassifierResult = ClassifierResultHttpError err }
            , Cmd.none
            , Nothing
            )



--- View2


view2 : Flags -> Texts -> UiSettings -> Model -> Html Msg
view2 flags texts settings model =
    let
        languageCfg =
            { makeOption =
                \l ->
                    { text = texts.languageLabel l
                    , additional = ""
                    }
            , placeholder = texts.basics.selectPlaceholder
            , labelColor = \_ -> \_ -> ""
            , style = DS.mainStyle
            }
    in
    div
        [ class "flex flex-col relative"
        ]
        [ MB.view
            { start =
                [ MB.CustomElement <|
                    B.primaryButton
                        { handler = onClick SaveSettings
                        , label = texts.save
                        , icon = "fa fa-save"
                        , attrs =
                            [ title texts.saveSettings
                            , href "#"
                            ]
                        , disabled = getSettings model == Nothing
                        }
                ]
            , end = []
            , rootClasses = "mb-4"
            }
        , h3 [ class S.header3 ]
            [ text texts.documentLanguage
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text texts.documentLanguage
                ]
            , Html.map LangDropdownMsg
                (Comp.Dropdown.view2
                    languageCfg
                    settings
                    model.langModel
                )
            , span [ class "opacity-50 text-sm" ]
                [ text texts.documentLanguageHelp
                ]
            ]
        , div
            [ classList
                [ ( "hidden", not flags.config.integrationEnabled )
                ]
            ]
            [ h3
                [ class S.header3
                ]
                [ text texts.integrationEndpoint
                ]
            , div [ class "mb-4" ]
                [ label
                    [ class "inline-flex items-center"
                    , for "int-endpoint-enabled"
                    ]
                    [ input
                        [ type_ "checkbox"
                        , onCheck (\_ -> ToggleIntegrationEndpoint)
                        , checked model.intEnabled
                        , id "int-endpoint-enabled"
                        , class S.checkboxInput
                        ]
                        []
                    , span [ class "ml-2" ]
                        [ text texts.integrationEndpointLabel
                        ]
                    ]
                , div [ class "opacity-50 text-sm" ]
                    [ text texts.integrationEndpointHelp
                    ]
                ]
            ]
        , div
            [ classList
                [ ( "hidden", not flags.config.fullTextSearchEnabled )
                ]
            ]
            [ h3
                [ class S.header3 ]
                [ text texts.fulltextSearch ]
            , div
                [ class "mb-4" ]
                [ div [ class "flex flex-row" ]
                    [ input
                        [ type_ "text"
                        , value model.fullTextConfirmText
                        , onInput SetFullTextConfirm
                        , class S.textInput
                        , class "rounded-r-none"
                        ]
                        []
                    , a
                        [ class S.primaryButtonPlain
                        , class "rouded-r"
                        , href "#"
                        , onClick TriggerReIndex
                        ]
                        [ i [ class "fa fa-sync-alt" ] []
                        , span [ class "ml-2 hidden sm:inline" ]
                            [ text texts.reindexAllData
                            ]
                        ]
                    ]
                , div [ class "opacity-50 text-sm" ]
                    [ text texts.reindexAllDataHelp
                    ]
                , renderFulltextReindexResultMessage texts model.fullTextReIndexResult
                ]
            ]
        , div
            [ classList
                [ ( " hidden", not flags.config.showClassificationSettings )
                ]
            ]
            [ h3
                [ class S.header3 ]
                [ text texts.autoTagging
                ]
            , div
                [ class "mb-4" ]
                [ Html.map ClassifierSettingMsg
                    (Comp.ClassifierSettingsForm.view2 texts.classifierSettingsForm
                        settings
                        model.classifierModel
                    )
                , div [ class "flex flex-row justify-end" ]
                    [ B.secondaryBasicButton
                        { handler = onClick StartClassifierTask
                        , icon = "fa fa-play"
                        , label = texts.startNow
                        , disabled = model.classifierModel.schedule == Nothing
                        , attrs = [ href "#" ]
                        }
                    , renderClassifierResultMessage texts model.startClassifierResult
                    ]
                ]
            ]
        ]


renderClassifierResultMessage : Texts -> ClassifierResult -> Html msg
renderClassifierResultMessage texts result =
    let
        isSuccess =
            case result of
                ClassifierResultOk ->
                    True

                _ ->
                    False

        isError =
            not isSuccess
    in
    div
        [ classList
            [ ( S.errorMessage, isError )
            , ( S.successMessage, isSuccess )
            , ( "hidden", result == ClassifierResultInitial )
            ]
        ]
        [ case result of
            ClassifierResultInitial ->
                text ""

            ClassifierResultOk ->
                text texts.classifierTaskStarted

            ClassifierResultHttpError err ->
                text (texts.httpError err)

            ClassifierResultSubmitError m ->
                text m
        ]


renderFulltextReindexResultMessage : Texts -> FulltextReindexResult -> Html msg
renderFulltextReindexResultMessage texts result =
    case result of
        FulltextReindexInitial ->
            text ""

        FulltextReindexSubmitOk ->
            text texts.fulltextReindexSubmitted

        FulltextReindexHttpError err ->
            text (texts.httpError err)

        FulltextReindexOKMissing ->
            text texts.fulltextReindexOkMissing

        FulltextReindexSubmitError m ->
            text m
