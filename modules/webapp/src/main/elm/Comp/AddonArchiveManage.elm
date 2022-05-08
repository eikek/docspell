{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.AddonArchiveManage exposing (Model, Msg, addonInstallResult, init, loadAddons, update, view)

import Api
import Api.Model.Addon exposing (Addon)
import Api.Model.AddonList exposing (AddonList)
import Api.Model.AddonRegister exposing (AddonRegister)
import Api.Model.BasicResult exposing (BasicResult)
import Comp.AddonArchiveForm
import Comp.AddonArchiveTable
import Comp.Basic as B
import Comp.ItemDetail.Model exposing (Msg(..))
import Comp.MenuBar as MB
import Data.Flags exposing (Flags)
import Data.ServerEvent exposing (AddonInfo)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Markdown
import Messages.Comp.AddonArchiveManage exposing (Texts)
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
    , addons : List Addon
    , formModel : Comp.AddonArchiveForm.Model
    , loading : Bool
    , formError : FormError
    , deleteConfirm : DeleteConfirm
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( fm, fc ) =
            Comp.AddonArchiveForm.init
    in
    ( { viewMode = Table
      , addons = []
      , formModel = fm
      , loading = False
      , formError = FormErrorNone
      , deleteConfirm = DeleteConfirmOff
      }
    , Cmd.batch
        [ Cmd.map FormMsg fc
        , Api.addonsGetAll flags LoadAddonsResp
        ]
    )


type Msg
    = LoadAddons
    | TableMsg Comp.AddonArchiveTable.Msg
    | FormMsg Comp.AddonArchiveForm.Msg
    | InitNewAddon
    | SetViewMode ViewMode
    | Submit
    | RequestDelete
    | CancelDelete
    | DeleteAddonNow String
    | LoadAddonsResp (Result Http.Error AddonList)
    | AddAddonResp (Result Http.Error BasicResult)
    | UpdateAddonResp (Result Http.Error BasicResult)
    | DeleteAddonResp (Result Http.Error BasicResult)
    | AddonInstallResp AddonInfo


loadAddons : Msg
loadAddons =
    LoadAddons


addonInstallResult : AddonInfo -> Msg
addonInstallResult info =
    AddonInstallResp info



--- update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update flags msg model =
    case msg of
        InitNewAddon ->
            let
                ( bm, bc ) =
                    Comp.AddonArchiveForm.init

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
                Api.addonsGetAll flags LoadAddonsResp

              else
                Cmd.none
            , Sub.none
            )

        FormMsg lm ->
            let
                ( fm, fc ) =
                    Comp.AddonArchiveForm.update flags lm model.formModel
            in
            ( { model | formModel = fm, formError = FormErrorNone }
            , Cmd.map FormMsg fc
            , Sub.none
            )

        TableMsg lm ->
            let
                action =
                    Comp.AddonArchiveTable.update lm
            in
            case action of
                Comp.AddonArchiveTable.Selected addon ->
                    let
                        ( bm, bc ) =
                            Comp.AddonArchiveForm.initWith addon
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

        DeleteAddonNow id ->
            ( { model | deleteConfirm = DeleteConfirmOff, loading = True }
            , Api.addonsDelete flags id DeleteAddonResp
            , Sub.none
            )

        LoadAddons ->
            ( { model | loading = True }
            , Api.addonsGetAll flags LoadAddonsResp
            , Sub.none
            )

        LoadAddonsResp (Ok list) ->
            ( { model | loading = False, addons = list.items, formError = FormErrorNone }
            , Cmd.none
            , Sub.none
            )

        LoadAddonsResp (Err err) ->
            ( { model | loading = False, formError = FormErrorHttp err }, Cmd.none, Sub.none )

        AddonInstallResp info ->
            if info.success then
                ( { model | loading = False, viewMode = Table }, Api.addonsGetAll flags LoadAddonsResp, Sub.none )

            else
                ( { model | loading = False, formError = FormErrorSubmit info.message }, Cmd.none, Sub.none )

        Submit ->
            case Comp.AddonArchiveForm.get model.formModel of
                Just data ->
                    if data.id /= "" then
                        ( { model | loading = True }
                        , Api.addonsUpdate flags data.id UpdateAddonResp
                        , Sub.none
                        )

                    else
                        ( { model | loading = True }
                        , Api.addonsInstall
                            flags
                            (AddonRegister <| Maybe.withDefault "" data.url)
                            AddAddonResp
                        , Sub.none
                        )

                Nothing ->
                    ( { model | formError = FormErrorInvalid }, Cmd.none, Sub.none )

        AddAddonResp (Ok res) ->
            if res.success then
                ( model, Cmd.none, Sub.none )

            else
                ( { model | loading = False, formError = FormErrorSubmit res.message }, Cmd.none, Sub.none )

        AddAddonResp (Err err) ->
            ( { model | loading = False, formError = FormErrorHttp err }, Cmd.none, Sub.none )

        UpdateAddonResp (Ok res) ->
            if res.success then
                ( model, Cmd.none, Sub.none )

            else
                ( { model | loading = False, formError = FormErrorSubmit res.message }, Cmd.none, Sub.none )

        UpdateAddonResp (Err err) ->
            ( { model | loading = False, formError = FormErrorHttp err }, Cmd.none, Sub.none )

        DeleteAddonResp (Ok res) ->
            if res.success then
                update flags (SetViewMode Table) { model | loading = False }

            else
                ( { model | formError = FormErrorSubmit res.message, loading = False }, Cmd.none, Sub.none )

        DeleteAddonResp (Err err) ->
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
                    { tagger = InitNewAddon
                    , title = texts.createNewAddonArchive
                    , icon = Just "fa fa-plus"
                    , label = texts.newAddonArchive
                    }
                ]
            , rootClasses = "mb-4"
            , sticky = True
            }
        , div
            [ class "flex flex-col"
            ]
            [ Html.map TableMsg
                (Comp.AddonArchiveTable.view texts.addonArchiveTable model.addons)
            ]
        , B.loadingDimmer
            { label = ""
            , active = model.loading
            }
        ]


viewForm : Texts -> UiSettings -> Flags -> Model -> Html Msg
viewForm texts _ _ model =
    let
        newAddon =
            model.formModel.addon.id == ""

        isValid =
            Comp.AddonArchiveForm.get model.formModel /= Nothing
    in
    div [ class "relative" ]
        [ Html.form []
            [ if newAddon then
                h1 [ class S.header2 ]
                    [ text texts.createNewAddonArchive
                    ]

              else
                h1 [ class S.header2 ]
                    [ text (Comp.AddonArchiveForm.get model.formModel |> Maybe.map .name |> Maybe.withDefault "Update")
                    ]
            , MB.view
                { start =
                    [ MB.SecondaryButton
                        { tagger = SetViewMode Table
                        , title = texts.basics.backToList
                        , icon = Just "fa fa-arrow-left"
                        , label = texts.basics.back
                        }
                    ]
                , end =
                    if not newAddon then
                        [ MB.DeleteButton
                            { tagger = RequestDelete
                            , title = texts.deleteThisAddonArchive
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
                [ Html.map FormMsg (Comp.AddonArchiveForm.view texts.addonArchiveForm model.formModel)
                ]
            , MB.view
                { start =
                    [ MB.PrimaryButton
                        { tagger = Submit
                        , title = texts.installNow
                        , icon =
                            if newAddon then
                                Just "fa fa-save"

                            else
                                Just "fa fa-arrows-rotate"
                        , label =
                            if newAddon then
                                texts.installNow

                            else
                                texts.updateNow
                        }
                    ]
                , end = []
                , rootClasses = "mb-4"
                , sticky = False
                }
            , div
                [ class "mb-4"
                , classList [ ( "hidden", newAddon ) ]
                ]
                [ label [ class S.inputLabel ] [ text texts.description ]
                , case model.formModel.addon.description of
                    Just desc ->
                        Markdown.toHtml [ class "markdown-preview" ] desc

                    Nothing ->
                        div [ class "italic" ] [ text "-" ]
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
                        , text texts.reallyDeleteAddonArchive
                        ]
                    , div [ class "mt-4 flex flex-row items-center" ]
                        [ B.deleteButton
                            { label = texts.basics.yes
                            , icon = "fa fa-check"
                            , disabled = False
                            , handler = onClick (DeleteAddonNow model.formModel.addon.id)
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
