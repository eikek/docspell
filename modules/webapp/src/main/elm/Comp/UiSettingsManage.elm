module Comp.UiSettingsManage exposing
    ( Model
    , Msg(..)
    , init
    , update
    , view
    , view2
    )

import Api.Model.BasicResult exposing (BasicResult)
import Comp.MenuBar as MB
import Comp.UiSettingsForm
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Ports
import Styles as S


type alias Model =
    { formModel : Comp.UiSettingsForm.Model
    , settings : Maybe UiSettings
    , message : Maybe BasicResult
    }


type Msg
    = UiSettingsFormMsg Comp.UiSettingsForm.Msg
    | Submit
    | SettingsSaved
    | UpdateSettings


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


update : Flags -> UiSettings -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update flags settings msg model =
    case msg of
        UiSettingsFormMsg lm ->
            let
                inSettings =
                    Maybe.withDefault settings model.settings

                ( m_, sett ) =
                    Comp.UiSettingsForm.update inSettings lm model.formModel
            in
            ( { model
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
            , Cmd.none
            , Sub.none
            )

        Submit ->
            case model.settings of
                Just s ->
                    ( { model | message = Nothing }
                    , Ports.storeUiSettings flags s
                    , Ports.onUiSettingsSaved SettingsSaved
                    )

                Nothing ->
                    ( { model | message = Just (BasicResult False "Settings unchanged or invalid.") }
                    , Cmd.none
                    , Sub.none
                    )

        SettingsSaved ->
            ( { model | message = Just (BasicResult True "Settings saved.") }
            , Cmd.none
            , Sub.none
            )

        UpdateSettings ->
            let
                ( fm, fc ) =
                    Comp.UiSettingsForm.init flags settings
            in
            ( { model | formModel = fm }
            , Cmd.map UiSettingsFormMsg fc
            , Sub.none
            )



--- View


isError : Model -> Bool
isError model =
    Maybe.map .success model.message == Just False


isSuccess : Model -> Bool
isSuccess model =
    Maybe.map .success model.message == Just True


view : Flags -> UiSettings -> String -> Model -> Html Msg
view flags settings classes model =
    div [ class classes ]
        [ Html.map UiSettingsFormMsg (Comp.UiSettingsForm.view flags settings model.formModel)
        , div [ class "ui divider" ] []
        , button
            [ class "ui primary button"
            , onClick Submit
            ]
            [ text "Submit"
            ]
        , div
            [ classList
                [ ( "ui message", True )
                , ( "success", isSuccess model )
                , ( "error", isError model )
                , ( "hidden invisible", model.message == Nothing )
                ]
            ]
            [ Maybe.map .message model.message
                |> Maybe.withDefault ""
                |> text
            ]
        ]



--- View2


view2 : Flags -> UiSettings -> String -> Model -> Html Msg
view2 flags settings classes model =
    div [ class classes ]
        [ MB.view
            { start =
                [ MB.PrimaryButton
                    { tagger = Submit
                    , label = "Submit"
                    , title = "Save settings"
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
                flags
                settings
                model.formModel
            )
        ]
