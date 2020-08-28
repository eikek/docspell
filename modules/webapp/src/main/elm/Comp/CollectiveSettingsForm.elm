module Comp.CollectiveSettingsForm exposing
    ( Model
    , Msg
    , getSettings
    , init
    , update
    , view
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.CollectiveSettings exposing (CollectiveSettings)
import Comp.ClassifierSettingsForm
import Comp.Dropdown
import Data.Flags exposing (Flags)
import Data.Language exposing (Language)
import Data.UiSettings exposing (UiSettings)
import Data.Validated exposing (Validated)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
import Http
import Util.Http


type alias Model =
    { langModel : Comp.Dropdown.Model Language
    , intEnabled : Bool
    , initSettings : CollectiveSettings
    , fullTextConfirmText : String
    , fullTextReIndexResult : Maybe BasicResult
    , classifierModel : Comp.ClassifierSettingsForm.Model
    }


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
                { makeOption =
                    \l ->
                        { value = Data.Language.toIso3 l
                        , text = Data.Language.toName l
                        , additional = ""
                        }
                , placeholder = ""
                , options = Data.Language.all
                , selected = Just lang
                }
      , intEnabled = settings.integrationEnabled
      , initSettings = settings
      , fullTextConfirmText = ""
      , fullTextReIndexResult = Nothing
      , classifierModel = cm
      }
    , Cmd.map ClassifierSettingMsg cc
    )


getSettings : Model -> Validated CollectiveSettings
getSettings model =
    Data.Validated.map
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
                    ( { model | fullTextReIndexResult = Nothing }
                    , Api.startReIndex flags TriggerReIndexResult
                    , Nothing
                    )

                _ ->
                    ( { model
                        | fullTextReIndexResult =
                            Just
                                (BasicResult False <|
                                    "Please type OK in the field if you really "
                                        ++ "want to start re-indexing your data."
                                )
                      }
                    , Cmd.none
                    , Nothing
                    )

        TriggerReIndexResult (Ok br) ->
            ( { model | fullTextReIndexResult = Just br }, Cmd.none, Nothing )

        TriggerReIndexResult (Err err) ->
            ( { model
                | fullTextReIndexResult =
                    Just (BasicResult False (Util.Http.errorToString err))
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
                Data.Validated.Valid s ->
                    ( model, Cmd.none, Just s )

                _ ->
                    ( model, Cmd.none, Nothing )


view : Flags -> UiSettings -> Model -> Html Msg
view flags settings model =
    div
        [ classList
            [ ( "ui form", True )
            , ( "error", Maybe.map .success model.fullTextReIndexResult == Just False )
            , ( "success", Maybe.map .success model.fullTextReIndexResult == Just True )
            ]
        ]
        [ h3 [ class "ui dividing header" ]
            [ text "Document Language"
            ]
        , div [ class "field" ]
            [ label [] [ text "Document Language" ]
            , Html.map LangDropdownMsg (Comp.Dropdown.view settings model.langModel)
            , span [ class "small-info" ]
                [ text "The language of your documents. This helps text recognition (OCR) and text analysis."
                ]
            ]
        , h3
            [ classList
                [ ( "ui dividing header", True )
                , ( "invisible hidden", not flags.config.integrationEnabled )
                ]
            ]
            [ text "Integration Endpoint"
            ]
        , div
            [ classList
                [ ( "field", True )
                , ( "invisible hidden", not flags.config.integrationEnabled )
                ]
            ]
            [ div [ class "ui checkbox" ]
                [ input
                    [ type_ "checkbox"
                    , onCheck (\_ -> ToggleIntegrationEndpoint)
                    , checked model.intEnabled
                    ]
                    []
                , label [] [ text "Enable integration endpoint" ]
                , span [ class "small-info" ]
                    [ text "The integration endpoint allows (local) applications to submit files. "
                    , text "You can choose to disable it for your collective."
                    ]
                ]
            ]
        , h3
            [ classList
                [ ( "ui dividing header", True )
                , ( "invisible hidden", not flags.config.fullTextSearchEnabled )
                ]
            ]
            [ text "Full-Text Search"
            ]
        , div
            [ classList
                [ ( "inline field", True )
                , ( "invisible hidden", not flags.config.fullTextSearchEnabled )
                ]
            ]
            [ div [ class "ui action input" ]
                [ input
                    [ type_ "text"
                    , value model.fullTextConfirmText
                    , onInput SetFullTextConfirm
                    ]
                    []
                , button
                    [ class "ui primary right labeled icon button"
                    , onClick TriggerReIndex
                    ]
                    [ i [ class "refresh icon" ] []
                    , text "Re-Index All Data"
                    ]
                ]
            , div [ class "small-info" ]
                [ text "This starts a task that clears the full-text index and re-indexes all your data again."
                , text "You must type OK before clicking the button to avoid accidental re-indexing."
                ]
            , div
                [ classList
                    [ ( "ui message", True )
                    , ( "error", Maybe.map .success model.fullTextReIndexResult == Just False )
                    , ( "success", Maybe.map .success model.fullTextReIndexResult == Just True )
                    , ( "hidden invisible", model.fullTextReIndexResult == Nothing )
                    ]
                ]
                [ Maybe.map .message model.fullTextReIndexResult
                    |> Maybe.withDefault ""
                    |> text
                ]
            ]
        , h3
            [ classList
                [ ( "ui dividing header", True )
                , ( "invisible hidden", False )
                ]
            ]
            [ text "Document Classifier"
            ]
        , div
            [ classList
                [ ( "field", True )
                , ( "invisible hidden", False )
                ]
            ]
            [ Html.map ClassifierSettingMsg
                (Comp.ClassifierSettingsForm.view model.classifierModel)
            ]
        , div [ class "ui divider" ] []
        , button
            [ classList
                [ ( "ui primary button", True )
                , ( "disabled", getSettings model |> Data.Validated.isInvalid )
                ]
            , onClick SaveSettings
            ]
            [ text "Save"
            ]
        ]
