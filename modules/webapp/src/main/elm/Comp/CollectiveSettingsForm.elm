{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
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
import Comp.EmptyTrashForm
import Comp.MenuBar as MB
import Comp.StringListInput
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Data.Language exposing (Language)
import Data.TimeZone exposing (TimeZone)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
import Http
import Markdown
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
    , emptyTrashModel : Comp.EmptyTrashForm.Model
    , startEmptyTrashResult : EmptyTrashResult
    , passwordModel : Comp.StringListInput.Model
    , passwords : List String
    }


type ClassifierResult
    = ClassifierResultInitial
    | ClassifierResultHttpError Http.Error
    | ClassifierResultSubmitError String
    | ClassifierResultOk


type EmptyTrashResult
    = EmptyTrashResultInitial
    | EmptyTrashResultHttpError Http.Error
    | EmptyTrashResultSubmitError String
    | EmptyTrashResultOk
    | EmptyTrashResultInvalidForm


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

        ( em, ec ) =
            Comp.EmptyTrashForm.init flags settings.emptyTrash
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
      , emptyTrashModel = em
      , startEmptyTrashResult = EmptyTrashResultInitial
      , passwordModel = Comp.StringListInput.init
      , passwords = settings.passwords
      }
    , Cmd.batch [ Cmd.map ClassifierSettingMsg cc, Cmd.map EmptyTrashMsg ec ]
    )


getSettings : Model -> Maybe CollectiveSettings
getSettings model =
    Maybe.map2
        (\cls ->
            \trash ->
                { language =
                    Comp.Dropdown.getSelected model.langModel
                        |> List.head
                        |> Maybe.map Data.Language.toIso3
                        |> Maybe.withDefault model.initSettings.language
                , integrationEnabled = model.intEnabled
                , classifier = cls
                , emptyTrash = trash
                , passwords = model.passwords
                }
        )
        (Comp.ClassifierSettingsForm.getSettings model.classifierModel)
        (Comp.EmptyTrashForm.getSettings model.emptyTrashModel)


type Msg
    = LangDropdownMsg (Comp.Dropdown.Msg Language)
    | ToggleIntegrationEndpoint
    | SetFullTextConfirm String
    | TriggerReIndex
    | TriggerReIndexResult (Result Http.Error BasicResult)
    | ClassifierSettingMsg Comp.ClassifierSettingsForm.Msg
    | EmptyTrashMsg Comp.EmptyTrashForm.Msg
    | SaveSettings
    | StartClassifierTask
    | StartEmptyTrashTask
    | StartClassifierResp (Result Http.Error BasicResult)
    | StartEmptyTrashResp (Result Http.Error BasicResult)
    | PasswordMsg Comp.StringListInput.Msg


update : Flags -> TimeZone -> Msg -> Model -> ( Model, Cmd Msg, Maybe CollectiveSettings )
update flags tz msg model =
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
                    Comp.ClassifierSettingsForm.update flags tz lmsg model.classifierModel
            in
            ( { model
                | classifierModel = cm
              }
            , Cmd.map ClassifierSettingMsg cc
            , Nothing
            )

        EmptyTrashMsg lmsg ->
            let
                ( cm, cc ) =
                    Comp.EmptyTrashForm.update flags tz lmsg model.emptyTrashModel
            in
            ( { model
                | emptyTrashModel = cm
              }
            , Cmd.map EmptyTrashMsg cc
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

        StartEmptyTrashTask ->
            case getSettings model of
                Just settings ->
                    ( model
                    , Api.startEmptyTrash flags
                        settings.emptyTrash
                        StartEmptyTrashResp
                    , Nothing
                    )

                Nothing ->
                    ( { model | startEmptyTrashResult = EmptyTrashResultInvalidForm }
                    , Cmd.none
                    , Nothing
                    )

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

        StartEmptyTrashResp (Ok br) ->
            ( { model
                | startEmptyTrashResult =
                    if br.success then
                        EmptyTrashResultOk

                    else
                        EmptyTrashResultSubmitError br.message
              }
            , Cmd.none
            , Nothing
            )

        StartEmptyTrashResp (Err err) ->
            ( { model | startEmptyTrashResult = EmptyTrashResultHttpError err }
            , Cmd.none
            , Nothing
            )

        PasswordMsg lm ->
            let
                ( pm, action ) =
                    Comp.StringListInput.update lm model.passwordModel

                pws =
                    case action of
                        Comp.StringListInput.AddAction pw ->
                            pw :: model.passwords

                        Comp.StringListInput.RemoveAction pw ->
                            List.filter (\e -> e /= pw) model.passwords

                        Comp.StringListInput.NoAction ->
                            model.passwords
            in
            ( { model | passwordModel = pm, passwords = pws }
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
            , sticky = True
            }
        , h2 [ class S.header2 ]
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
            [ h2
                [ class S.header2
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
            [ h2
                [ class S.header2 ]
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
            [ h2
                [ class S.header2 ]
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
        , div []
            [ h2 [ class S.header2 ]
                [ text texts.emptyTrash
                ]
            , div [ class "mb-4" ]
                [ Html.map EmptyTrashMsg
                    (Comp.EmptyTrashForm.view texts.emptyTrashForm
                        settings
                        model.emptyTrashModel
                    )
                , div [ class "flex flex-row justify-end" ]
                    [ B.secondaryBasicButton
                        { handler = onClick StartEmptyTrashTask
                        , icon = "fa fa-play"
                        , label = texts.startNow
                        , disabled = model.emptyTrashModel.schedule == Nothing
                        , attrs = [ href "#" ]
                        }
                    , renderEmptyTrashResultMessage texts model.startEmptyTrashResult
                    ]
                ]
            ]
        , div []
            [ h2 [ class S.header2 ]
                [ text texts.passwords
                ]
            , div [ class "mb-4" ]
                [ div [ class "opacity-50 text-sm" ]
                    [ Markdown.toHtml [] texts.passwordsInfo
                    ]
                , Html.map PasswordMsg
                    (Comp.StringListInput.view2 model.passwords model.passwordModel)
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
        , class "ml-2"
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


renderEmptyTrashResultMessage : Texts -> EmptyTrashResult -> Html msg
renderEmptyTrashResultMessage texts result =
    let
        isSuccess =
            case result of
                EmptyTrashResultOk ->
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
            , ( "hidden", result == EmptyTrashResultInitial )
            ]
        , class "ml-2"
        ]
        [ case result of
            EmptyTrashResultInitial ->
                text ""

            EmptyTrashResultOk ->
                text texts.emptyTrashTaskStarted

            EmptyTrashResultHttpError err ->
                text (texts.httpError err)

            EmptyTrashResultSubmitError m ->
                text m

            EmptyTrashResultInvalidForm ->
                text texts.emptyTrashStartInvalidForm
        ]
