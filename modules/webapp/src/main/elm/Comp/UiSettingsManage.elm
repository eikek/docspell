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
    , message : Maybe BasicResult
    }


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
      , message = Nothing
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
                    , message =
                        if sett /= Nothing then
                            Nothing

                        else
                            model.message
                }
            , cmd = Cmd.none
            , newSettings = Nothing
            }

        Submit ->
            case model.settings of
                Just s ->
                    { model = { model | message = Nothing }
                    , cmd = Api.saveClientSettings flags s (SaveSettingsResp s)
                    , newSettings = Nothing
                    }

                Nothing ->
                    { model = { model | message = Just (BasicResult False "Settings unchanged or invalid.") }
                    , cmd = Cmd.none
                    , newSettings = Nothing
                    }

        SaveSettingsResp newSettings (Ok res) ->
            { model = { model | message = Just res }
            , cmd = Cmd.none
            , newSettings = Just newSettings
            }

        SaveSettingsResp _ (Err err) ->
            UpdateResult model Cmd.none Nothing

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
    Maybe.map .success model.message == Just False


isSuccess : Model -> Bool
isSuccess model =
    Maybe.map .success model.message == Just True


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
                , ( "hidden", model.message == Nothing )
                ]
            ]
            [ Maybe.map .message model.message
                |> Maybe.withDefault ""
                |> text
            ]
        , Html.map UiSettingsFormMsg
            (Comp.UiSettingsForm.view2
                texts.uiSettingsForm
                flags
                settings
                model.formModel
            )
        ]
