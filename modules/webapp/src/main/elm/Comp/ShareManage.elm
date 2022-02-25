{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.ShareManage exposing (Model, Msg, init, loadShares, update, view)

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.IdResult exposing (IdResult)
import Api.Model.ShareDetail exposing (ShareDetail)
import Api.Model.ShareList exposing (ShareList)
import Comp.Basic as B
import Comp.ItemDetail.Model exposing (Msg(..))
import Comp.MenuBar as MB
import Comp.ShareForm
import Comp.ShareMail
import Comp.ShareTable
import Comp.ShareView
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Messages.Comp.ShareManage exposing (Texts)
import Page exposing (Page(..))
import Ports
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
    , shares : List ShareDetail
    , formModel : Comp.ShareForm.Model
    , mailModel : Comp.ShareMail.Model
    , loading : Bool
    , formError : FormError
    , deleteConfirm : DeleteConfirm
    , query : String
    , owningOnly : Bool
    , sendMailVisible : Bool
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( fm, fc ) =
            Comp.ShareForm.init

        ( mm, mc ) =
            Comp.ShareMail.init flags
    in
    ( { viewMode = Table
      , shares = []
      , formModel = fm
      , mailModel = mm
      , loading = False
      , formError = FormErrorNone
      , deleteConfirm = DeleteConfirmOff
      , query = ""
      , owningOnly = True
      , sendMailVisible = False
      }
    , Cmd.batch
        [ Cmd.map FormMsg fc
        , Cmd.map MailMsg mc
        , Api.getShares flags "" True LoadSharesResp
        ]
    )


type Msg
    = LoadShares
    | TableMsg Comp.ShareTable.Msg
    | FormMsg Comp.ShareForm.Msg
    | MailMsg Comp.ShareMail.Msg
    | InitNewShare
    | SetViewMode ViewMode
    | SetQuery String
    | ToggleOwningOnly
    | ToggleSendMailVisible
    | Submit
    | RequestDelete
    | CancelDelete
    | DeleteShareNow String
    | LoadSharesResp (Result Http.Error ShareList)
    | AddShareResp (Result Http.Error IdResult)
    | UpdateShareResp (Result Http.Error BasicResult)
    | GetShareResp (Result Http.Error ShareDetail)
    | DeleteShareResp (Result Http.Error BasicResult)


loadShares : Msg
loadShares =
    LoadShares



--- update


update : Texts -> Flags -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update texts flags msg model =
    case msg of
        InitNewShare ->
            let
                nm =
                    { model | viewMode = Form, formError = FormErrorNone }

                share =
                    Api.Model.ShareDetail.empty
            in
            update texts flags (FormMsg (Comp.ShareForm.setShare { share | enabled = True })) nm

        SetViewMode vm ->
            ( { model | viewMode = vm, formError = FormErrorNone }
            , if vm == Table then
                Api.getShares flags model.query model.owningOnly LoadSharesResp

              else
                Cmd.none
            , Sub.none
            )

        FormMsg lm ->
            let
                ( fm, fc, fs ) =
                    Comp.ShareForm.update flags lm model.formModel
            in
            ( { model | formModel = fm, formError = FormErrorNone }
            , Cmd.map FormMsg fc
            , Sub.map FormMsg fs
            )

        TableMsg lm ->
            let
                action =
                    Comp.ShareTable.update lm
            in
            case action of
                Comp.ShareTable.Edit share ->
                    setShare texts share flags model

        RequestDelete ->
            ( { model | deleteConfirm = DeleteConfirmOn }, Cmd.none, Sub.none )

        CancelDelete ->
            ( { model | deleteConfirm = DeleteConfirmOff }, Cmd.none, Sub.none )

        DeleteShareNow id ->
            ( { model | deleteConfirm = DeleteConfirmOff, loading = True }
            , Api.deleteShare flags id DeleteShareResp
            , Sub.none
            )

        LoadShares ->
            ( { model | loading = True }
            , Api.getShares flags model.query model.owningOnly LoadSharesResp
            , Sub.none
            )

        LoadSharesResp (Ok list) ->
            ( { model | loading = False, shares = list.items, formError = FormErrorNone }
            , Cmd.none
            , Sub.none
            )

        LoadSharesResp (Err err) ->
            ( { model | loading = False, formError = FormErrorHttp err }, Cmd.none, Sub.none )

        Submit ->
            case Comp.ShareForm.getShare model.formModel of
                Just ( id, data ) ->
                    if id == "" then
                        ( { model | loading = True }, Api.addShare flags data AddShareResp, Sub.none )

                    else
                        ( { model | loading = True }, Api.updateShare flags id data UpdateShareResp, Sub.none )

                Nothing ->
                    ( { model | formError = FormErrorInvalid }, Cmd.none, Sub.none )

        AddShareResp (Ok res) ->
            if res.success then
                ( model, Api.getShare flags res.id GetShareResp, Sub.none )

            else
                ( { model | loading = False, formError = FormErrorSubmit res.message }, Cmd.none, Sub.none )

        AddShareResp (Err err) ->
            ( { model | loading = False, formError = FormErrorHttp err }, Cmd.none, Sub.none )

        UpdateShareResp (Ok res) ->
            if res.success then
                ( model, Api.getShare flags model.formModel.share.id GetShareResp, Sub.none )

            else
                ( { model | loading = False, formError = FormErrorSubmit res.message }, Cmd.none, Sub.none )

        UpdateShareResp (Err err) ->
            ( { model | loading = False, formError = FormErrorHttp err }, Cmd.none, Sub.none )

        GetShareResp (Ok share) ->
            setShare texts share flags model

        GetShareResp (Err err) ->
            ( { model | formError = FormErrorHttp err }, Cmd.none, Sub.none )

        DeleteShareResp (Ok res) ->
            if res.success then
                update texts flags (SetViewMode Table) { model | loading = False }

            else
                ( { model | formError = FormErrorSubmit res.message, loading = False }, Cmd.none, Sub.none )

        DeleteShareResp (Err err) ->
            ( { model | formError = FormErrorHttp err, loading = False }, Cmd.none, Sub.none )

        MailMsg lm ->
            let
                ( mm, mc ) =
                    Comp.ShareMail.update texts.shareMail flags lm model.mailModel
            in
            ( { model | mailModel = mm }, Cmd.map MailMsg mc, Sub.none )

        SetQuery q ->
            let
                nm =
                    { model | query = q }
            in
            ( nm
            , Api.getShares flags nm.query nm.owningOnly LoadSharesResp
            , Sub.none
            )

        ToggleOwningOnly ->
            let
                nm =
                    { model | owningOnly = not model.owningOnly }
            in
            ( nm
            , Api.getShares flags nm.query nm.owningOnly LoadSharesResp
            , Sub.none
            )

        ToggleSendMailVisible ->
            ( { model | sendMailVisible = not model.sendMailVisible }, Cmd.none, Sub.none )


setShare : Texts -> ShareDetail -> Flags -> Model -> ( Model, Cmd Msg, Sub Msg )
setShare texts share flags model =
    let
        shareUrl =
            flags.config.baseUrl ++ Page.pageToString (SharePage share.id)

        nextModel =
            { model | formError = FormErrorNone, viewMode = Form, loading = False, sendMailVisible = False }

        initClipboard =
            Ports.initClipboard (Comp.ShareView.clipboardData share)

        ( nm, nc, ns ) =
            update texts flags (FormMsg <| Comp.ShareForm.setShare share) nextModel

        ( nm2, nc2, ns2 ) =
            update texts flags (MailMsg <| Comp.ShareMail.setMailInfo share) nm
    in
    ( nm2, Cmd.batch [ initClipboard, nc, nc2 ], Sub.batch [ ns, ns2 ] )



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
                [ MB.TextInput
                    { tagger = SetQuery
                    , value = model.query
                    , placeholder = texts.basics.searchPlaceholder
                    , icon = Just "fa fa-search"
                    }
                , MB.Checkbox
                    { tagger = \_ -> ToggleOwningOnly
                    , label = texts.showOwningSharesOnly
                    , value = model.owningOnly
                    , id = "share-toggle-owner"
                    }
                ]
            , end =
                [ MB.PrimaryButton
                    { tagger = InitNewShare
                    , title = texts.createNewShare
                    , icon = Just "fa fa-plus"
                    , label = texts.newShare
                    }
                ]
            , rootClasses = "mb-4"
            , sticky = True
            }
        , Html.map TableMsg (Comp.ShareTable.view texts.shareTable model.shares)
        , B.loadingDimmer
            { label = ""
            , active = model.loading
            }
        ]


viewForm : Texts -> UiSettings -> Flags -> Model -> Html Msg
viewForm texts settings flags model =
    let
        newShare =
            model.formModel.share.id == ""

        isOwner =
            Maybe.map .user flags.account
                |> Maybe.map ((==) model.formModel.share.owner.name)
                |> Maybe.withDefault False
    in
    div []
        [ Html.form []
            [ if newShare then
                h1 [ class S.header2 ]
                    [ text texts.createNewShare
                    ]

              else
                h1 [ class S.header2 ]
                    [ div [ class "flex flex-row items-center" ]
                        [ div
                            [ class "flex text-sm opacity-75 label mr-3"
                            , classList [ ( "hidden", isOwner ) ]
                            ]
                            [ i [ class "fa fa-user mr-2" ] []
                            , text model.formModel.share.owner.name
                            ]
                        , text <| Maybe.withDefault texts.noName model.formModel.share.name
                        ]
                    , div [ class "flex flex-row items-center" ]
                        [ div [ class "opacity-50 text-sm flex-grow" ]
                            [ text "Id: "
                            , text model.formModel.share.id
                            ]
                        ]
                    ]
            , MB.view
                { start =
                    [ MB.CustomElement <|
                        B.primaryButton
                            { handler = onClick Submit
                            , title = "Submit this form"
                            , icon = "fa fa-save"
                            , label = texts.basics.submit
                            , disabled = not isOwner && not newShare
                            , attrs = [ href "#" ]
                            }
                    , MB.SecondaryButton
                        { tagger = SetViewMode Table
                        , title = texts.basics.backToList
                        , icon = Just "fa fa-arrow-left"
                        , label = texts.basics.cancel
                        }
                    ]
                , end =
                    if not newShare then
                        [ MB.DeleteButton
                            { tagger = RequestDelete
                            , title = texts.deleteThisShare
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
            , div
                [ classList [ ( "hidden", isOwner || newShare ) ]
                , class S.infoMessage
                ]
                [ text texts.notOwnerInfo
                ]
            , div [ classList [ ( "hidden", not isOwner && not newShare ) ] ]
                [ Html.map FormMsg (Comp.ShareForm.view texts.shareForm model.formModel)
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
                        , text texts.reallyDeleteShare
                        ]
                    , div [ class "mt-4 flex flex-row items-center" ]
                        [ B.deleteButton
                            { label = texts.basics.yes
                            , icon = "fa fa-check"
                            , disabled = False
                            , handler = onClick (DeleteShareNow model.formModel.share.id)
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
        , shareInfo texts flags model.formModel.share
        , shareSendMail texts flags settings model
        ]


shareInfo : Texts -> Flags -> ShareDetail -> Html Msg
shareInfo texts flags share =
    div
        [ class "mt-6"
        , classList [ ( "hidden", share.id == "" ) ]
        ]
        [ h2
            [ class S.header2
            , class "border-b-2 dark:border-slate-600"
            ]
            [ text texts.shareInformation
            ]
        , Comp.ShareView.viewDefault texts.shareView flags share
        ]


shareSendMail : Texts -> Flags -> UiSettings -> Model -> Html Msg
shareSendMail texts flags settings model =
    let
        share =
            model.formModel.share
    in
    div
        [ class "mt-8 mb-2"
        , classList [ ( "hidden", share.id == "" || not share.enabled || share.expired ) ]
        ]
        [ a
            [ class S.header2
            , class "border-b-2 dark:border-slate-600 w-full inline-block"
            , href "#"
            , onClick ToggleSendMailVisible
            ]
            [ if model.sendMailVisible then
                i [ class "fa fa-caret-down mr-2" ] []

              else
                i [ class "fa fa-caret-right mr-2" ] []
            , text texts.sendViaMail
            ]
        , div
            [ class "px-2 py-2 dark:border-slate-600"
            , classList [ ( "hidden", not model.sendMailVisible ) ]
            ]
            [ Html.map MailMsg
                (Comp.ShareMail.view texts.shareMail flags settings model.mailModel)
            ]
        ]
