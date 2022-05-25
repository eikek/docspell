{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.AddonRunConfigManage exposing (Model, Msg, init, loadConfigs, update, view)

import Api
import Api.Model.AddonRunConfig exposing (AddonRunConfig)
import Api.Model.AddonRunConfigList exposing (AddonRunConfigList)
import Api.Model.BasicResult exposing (BasicResult)
import Comp.AddonRunConfigForm
import Comp.AddonRunConfigTable
import Comp.Basic as B
import Comp.ItemDetail.Model exposing (Msg(..))
import Comp.MenuBar as MB
import Data.Flags exposing (Flags)
import Data.TimeZone exposing (TimeZone)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Messages.Comp.AddonRunConfigManage exposing (Texts)
import Page exposing (Page(..))
import Styles as S


type FormError
    = FormErrorNone
    | FormErrorHttp Http.Error
    | FormErrorInvalid
    | FormErrorSubmit String


type ViewMode
    = Table
    | Form


type DeleteConfirm
    = DeleteConfirmOff
    | DeleteConfirmOn


type alias Model =
    { viewMode : ViewMode
    , runConfigs : List AddonRunConfig
    , formModel : Comp.AddonRunConfigForm.Model
    , loading : Bool
    , formError : FormError
    , deleteConfirm : DeleteConfirm
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( fm, fc ) =
            Comp.AddonRunConfigForm.init flags
    in
    ( { viewMode = Table
      , runConfigs = []
      , formModel = fm
      , loading = False
      , formError = FormErrorNone
      , deleteConfirm = DeleteConfirmOff
      }
    , Cmd.batch
        [ Cmd.map FormMsg fc
        , Api.addonRunConfigGet flags LoadConfigsResp
        ]
    )


type Msg
    = LoadRunConfigs
    | TableMsg Comp.AddonRunConfigTable.Msg
    | FormMsg Comp.AddonRunConfigForm.Msg
    | InitNewConfig
    | SetViewMode ViewMode
    | Submit
    | RequestDelete
    | CancelDelete
    | DeleteConfigNow String
    | LoadConfigsResp (Result Http.Error AddonRunConfigList)
    | AddConfigResp (Result Http.Error BasicResult)
    | DeleteConfigResp (Result Http.Error BasicResult)


loadConfigs : Msg
loadConfigs =
    LoadRunConfigs



--- update


update : Flags -> TimeZone -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update flags tz msg model =
    case msg of
        InitNewConfig ->
            let
                ( bm, bc ) =
                    Comp.AddonRunConfigForm.init flags

                nm =
                    { model
                        | viewMode = Form
                        , formError = FormErrorNone
                        , formModel = bm
                    }
            in
            ( nm, Cmd.map FormMsg bc, Sub.none )

        SetViewMode vm ->
            ( { model | viewMode = vm, formError = FormErrorNone }
            , if vm == Table then
                Api.addonRunConfigGet flags LoadConfigsResp

              else
                Cmd.none
            , Sub.none
            )

        FormMsg lm ->
            let
                ( fm, fc ) =
                    Comp.AddonRunConfigForm.update flags tz lm model.formModel
            in
            ( { model | formModel = fm, formError = FormErrorNone }
            , Cmd.map FormMsg fc
            , Sub.none
            )

        TableMsg lm ->
            let
                action =
                    Comp.AddonRunConfigTable.update lm
            in
            case action of
                Comp.AddonRunConfigTable.Selected addon ->
                    let
                        ( bm, bc ) =
                            Comp.AddonRunConfigForm.initWith flags addon
                    in
                    ( { model
                        | viewMode = Form
                        , formError = FormErrorNone
                        , formModel = bm
                      }
                    , Cmd.map FormMsg bc
                    , Sub.none
                    )

        RequestDelete ->
            ( { model | deleteConfirm = DeleteConfirmOn }, Cmd.none, Sub.none )

        CancelDelete ->
            ( { model | deleteConfirm = DeleteConfirmOff }, Cmd.none, Sub.none )

        DeleteConfigNow id ->
            ( { model | deleteConfirm = DeleteConfirmOff, loading = True }
            , Api.addonRunConfigDelete flags id DeleteConfigResp
            , Sub.none
            )

        LoadRunConfigs ->
            ( { model | loading = True }
            , Api.addonRunConfigGet flags LoadConfigsResp
            , Sub.none
            )

        LoadConfigsResp (Ok list) ->
            ( { model | loading = False, runConfigs = list.items, formError = FormErrorNone }
            , Cmd.none
            , Sub.none
            )

        LoadConfigsResp (Err err) ->
            ( { model | loading = False, formError = FormErrorHttp err }, Cmd.none, Sub.none )

        Submit ->
            case Comp.AddonRunConfigForm.get model.formModel of
                Just data ->
                    ( { model | loading = True }, Api.addonRunConfigSet flags data AddConfigResp, Sub.none )

                Nothing ->
                    ( { model | formError = FormErrorInvalid }, Cmd.none, Sub.none )

        AddConfigResp (Ok res) ->
            if res.success then
                ( { model | loading = False }, Cmd.none, Sub.none )

            else
                ( { model | loading = False, formError = FormErrorSubmit res.message }, Cmd.none, Sub.none )

        AddConfigResp (Err err) ->
            ( { model | loading = False, formError = FormErrorHttp err }, Cmd.none, Sub.none )

        DeleteConfigResp (Ok res) ->
            if res.success then
                update flags tz (SetViewMode Table) { model | loading = False }

            else
                ( { model | formError = FormErrorSubmit res.message, loading = False }, Cmd.none, Sub.none )

        DeleteConfigResp (Err err) ->
            ( { model | formError = FormErrorHttp err, loading = False }, Cmd.none, Sub.none )



--- view


view : Texts -> UiSettings -> Flags -> Model -> Html Msg
view texts settings flags model =
    if model.viewMode == Table then
        viewTable texts model

    else
        viewForm texts settings flags model


viewTable : Texts -> Model -> Html Msg
viewTable texts model =
    div [ class "flex flex-col" ]
        [ MB.view
            { start =
                []
            , end =
                [ MB.PrimaryButton
                    { tagger = InitNewConfig
                    , title = texts.createNewAddonRunConfig
                    , icon = Just "fa fa-plus"
                    , label = texts.newAddonRunConfig
                    }
                ]
            , rootClasses = "mb-4"
            , sticky = True
            }
        , div
            [ class "flex flex-col"
            ]
            [ Html.map TableMsg
                (Comp.AddonRunConfigTable.view texts.addonArchiveTable model.runConfigs)
            ]
        , B.loadingDimmer
            { label = ""
            , active = model.loading
            }
        ]


viewForm : Texts -> UiSettings -> Flags -> Model -> Html Msg
viewForm texts uiSettings _ model =
    let
        newConfig =
            model.formModel.runConfig.id == ""

        isValid =
            Comp.AddonRunConfigForm.get model.formModel /= Nothing
    in
    div []
        [ Html.form []
            [ if newConfig then
                h1 [ class S.header2 ]
                    [ text texts.createNewAddonRunConfig
                    ]

              else
                h1 [ class S.header2 ]
                    [ text (Comp.AddonRunConfigForm.get model.formModel |> Maybe.map .name |> Maybe.withDefault "Update")
                    ]
            , MB.view
                { start =
                    [ MB.CustomElement <|
                        B.primaryButton
                            { handler = onClick Submit
                            , title = texts.basics.submitThisForm
                            , icon = "fa fa-save"
                            , label = texts.basics.submit
                            , disabled = not isValid
                            , attrs = [ href "#" ]
                            }
                    , MB.SecondaryButton
                        { tagger = SetViewMode Table
                        , title = texts.basics.backToList
                        , icon = Just "fa fa-arrow-left"
                        , label = texts.basics.back
                        }
                    ]
                , end =
                    if not newConfig then
                        [ MB.DeleteButton
                            { tagger = RequestDelete
                            , title = texts.deleteThisAddonRunConfig
                            , icon = Just "fa fa-trash"
                            , label = texts.basics.delete
                            }
                        ]

                    else
                        []
                , rootClasses = "mb-4"
                , sticky = True
                }
            , div
                [ classList
                    [ ( "hidden", model.formError == FormErrorNone )
                    ]
                , class "my-2"
                , class S.errorMessage
                ]
                [ case model.formError of
                    FormErrorNone ->
                        text ""

                    FormErrorHttp err ->
                        text (texts.httpError err)

                    FormErrorInvalid ->
                        text texts.correctFormErrors

                    FormErrorSubmit m ->
                        text m
                ]
            , div []
                [ Html.map FormMsg (Comp.AddonRunConfigForm.view texts.addonArchiveForm uiSettings model.formModel)
                ]
            , B.loadingDimmer
                { active = model.loading
                , label = texts.basics.loading
                }
            , B.contentDimmer
                (model.deleteConfirm == DeleteConfirmOn)
                (div [ class "flex flex-col" ]
                    [ div [ class "text-lg" ]
                        [ i [ class "fa fa-info-circle mr-2" ] []
                        , text texts.reallyDeleteAddonRunConfig
                        ]
                    , div [ class "mt-4 flex flex-row items-center" ]
                        [ B.deleteButton
                            { label = texts.basics.yes
                            , icon = "fa fa-check"
                            , disabled = False
                            , handler = onClick (DeleteConfigNow model.formModel.runConfig.id)
                            , attrs = [ href "#" ]
                            }
                        , B.secondaryButton
                            { label = texts.basics.no
                            , icon = "fa fa-times"
                            , disabled = False
                            , handler = onClick CancelDelete
                            , attrs = [ href "#", class "ml-2" ]
                            }
                        ]
                    ]
                )
            ]
        ]
