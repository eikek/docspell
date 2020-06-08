module Comp.CollectiveSettingsForm exposing
    ( Model
    , Msg
    , getSettings
    , init
    , update
    , view
    )

import Api.Model.CollectiveSettings exposing (CollectiveSettings)
import Comp.Dropdown
import Data.Flags exposing (Flags)
import Data.Language exposing (Language)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck)


type alias Model =
    { langModel : Comp.Dropdown.Model Language
    , intEnabled : Bool
    , initSettings : CollectiveSettings
    }


init : CollectiveSettings -> Model
init settings =
    let
        lang =
            Data.Language.fromString settings.language
                |> Maybe.withDefault Data.Language.German
    in
    { langModel =
        Comp.Dropdown.makeSingleList
            { makeOption =
                \l ->
                    { value = Data.Language.toIso3 l
                    , text = Data.Language.toName l
                    }
            , placeholder = ""
            , options = Data.Language.all
            , selected = Just lang
            }
    , intEnabled = settings.integrationEnabled
    , initSettings = settings
    }


getSettings : Model -> CollectiveSettings
getSettings model =
    CollectiveSettings
        (Comp.Dropdown.getSelected model.langModel
            |> List.head
            |> Maybe.map Data.Language.toIso3
            |> Maybe.withDefault model.initSettings.language
        )
        model.intEnabled


type Msg
    = LangDropdownMsg (Comp.Dropdown.Msg Language)
    | ToggleIntegrationEndpoint


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Maybe CollectiveSettings )
update _ msg model =
    case msg of
        LangDropdownMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.langModel

                nextModel =
                    { model | langModel = m2 }

                nextSettings =
                    if Comp.Dropdown.isDropdownChangeMsg m then
                        Just (getSettings nextModel)

                    else
                        Nothing
            in
            ( nextModel, Cmd.map LangDropdownMsg c2, nextSettings )

        ToggleIntegrationEndpoint ->
            let
                nextModel =
                    { model | intEnabled = not model.intEnabled }
            in
            ( nextModel, Cmd.none, Just (getSettings nextModel) )


view : Flags -> UiSettings -> Model -> Html Msg
view flags settings model =
    div [ class "ui form" ]
        [ div [ class "field" ]
            [ label [] [ text "Document Language" ]
            , Html.map LangDropdownMsg (Comp.Dropdown.view settings model.langModel)
            , span [ class "small-info" ]
                [ text "The language of your documents. This helps text recognition (OCR) and text analysis."
                ]
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
        ]
