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
import Comp.ShareTable
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Messages.Comp.ShareManage exposing (Texts)
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
    , loading : Bool
    , formError : FormError
    , deleteConfirm : DeleteConfirm
    }


init : ( Model, Cmd Msg )
init =
    let
        ( fm, fc ) =
            Comp.ShareForm.init
    in
    ( { viewMode = Table
      , shares = []
      , formModel = fm
      , loading = False
      , formError = FormErrorNone
      , deleteConfirm = DeleteConfirmOff
      }
    , Cmd.map FormMsg fc
    )


type Msg
    = LoadShares
    | TableMsg Comp.ShareTable.Msg
    | FormMsg Comp.ShareForm.Msg
    | InitNewShare
    | SetViewMode ViewMode
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


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        InitNewShare ->
            let
                nm =
                    { model | viewMode = Form, formError = FormErrorNone }

                share =
                    Api.Model.ShareDetail.empty
            in
            update flags (FormMsg (Comp.ShareForm.setShare share)) nm

        SetViewMode vm ->
            ( { model | viewMode = vm, formError = FormErrorNone }
            , if vm == Table then
                Api.getShares flags LoadSharesResp

              else
                Cmd.none
            )

        FormMsg lm ->
            let
                ( fm, fc ) =
                    Comp.ShareForm.update flags lm model.formModel
            in
            ( { model | formModel = fm }, Cmd.map FormMsg fc )

        TableMsg lm ->
            let
                action =
                    Comp.ShareTable.update lm

                nextModel =
                    { model | viewMode = Form, formError = FormErrorNone }
            in
            case action of
                Comp.ShareTable.Edit share ->
                    update flags (FormMsg <| Comp.ShareForm.setShare share) nextModel

        RequestDelete ->
            ( { model | deleteConfirm = DeleteConfirmOn }, Cmd.none )

        CancelDelete ->
            ( { model | deleteConfirm = DeleteConfirmOff }, Cmd.none )

        DeleteShareNow id ->
            ( { model | deleteConfirm = DeleteConfirmOff, loading = True }
            , Api.deleteShare flags id DeleteShareResp
            )

        LoadShares ->
            ( { model | loading = True }, Api.getShares flags LoadSharesResp )

        LoadSharesResp (Ok list) ->
            ( { model | loading = False, shares = list.items, formError = FormErrorNone }, Cmd.none )

        LoadSharesResp (Err err) ->
            ( { model | loading = False, formError = FormErrorHttp err }, Cmd.none )

        Submit ->
            case Comp.ShareForm.getShare model.formModel of
                Just ( id, data ) ->
                    if id == "" then
                        ( { model | loading = True }, Api.addShare flags data AddShareResp )

                    else
                        ( { model | loading = True }, Api.updateShare flags id data UpdateShareResp )

                Nothing ->
                    ( { model | formError = FormErrorInvalid }, Cmd.none )

        AddShareResp (Ok res) ->
            if res.success then
                ( model, Api.getShare flags res.id GetShareResp )

            else
                ( { model | loading = False, formError = FormErrorSubmit res.message }, Cmd.none )

        AddShareResp (Err err) ->
            ( { model | loading = False, formError = FormErrorHttp err }, Cmd.none )

        UpdateShareResp (Ok res) ->
            if res.success then
                ( model, Api.getShare flags model.formModel.share.id GetShareResp )

            else
                ( { model | loading = False, formError = FormErrorSubmit res.message }, Cmd.none )

        UpdateShareResp (Err err) ->
            ( { model | loading = False, formError = FormErrorHttp err }, Cmd.none )

        GetShareResp (Ok share) ->
            let
                nextModel =
                    { model | formError = FormErrorNone, loading = False }
            in
            update flags (FormMsg <| Comp.ShareForm.setShare share) nextModel

        GetShareResp (Err err) ->
            ( { model | formError = FormErrorHttp err }, Cmd.none )

        DeleteShareResp (Ok res) ->
            if res.success then
                update flags (SetViewMode Table) { model | loading = False }

            else
                ( { model | formError = FormErrorSubmit res.message, loading = False }, Cmd.none )

        DeleteShareResp (Err err) ->
            ( { model | formError = FormErrorHttp err, loading = False }, Cmd.none )



--- view


view : Texts -> Flags -> Model -> Html Msg
view texts _ model =
    if model.viewMode == Table then
        viewTable texts model

    else
        viewForm texts model


viewTable : Texts -> Model -> Html Msg
viewTable texts model =
    div [ class "flex flex-col" ]
        [ MB.view
            { start =
                []
            , end =
                [ MB.PrimaryButton
                    { tagger = InitNewShare
                    , title = texts.createNewShare
                    , icon = Just "fa fa-plus"
                    , label = texts.newShare
                    }
                ]
            , rootClasses = "mb-4"
            }
        , Html.map TableMsg (Comp.ShareTable.view texts.shareTable model.shares)
        , B.loadingDimmer
            { label = ""
            , active = model.loading
            }
        ]


viewForm : Texts -> Model -> Html Msg
viewForm texts model =
    let
        newShare =
            model.formModel.share.id == ""
    in
    Html.form [ class "relative" ]
        [ if newShare then
            h1 [ class S.header2 ]
                [ text texts.createNewShare
                ]

          else
            h1 [ class S.header2 ]
                [ text <| Maybe.withDefault texts.noName model.formModel.share.name
                , div [ class "opacity-50 text-sm" ]
                    [ text "Id: "
                    , text model.formModel.share.id
                    ]
                ]
        , MB.view
            { start =
                [ MB.PrimaryButton
                    { tagger = Submit
                    , title = "Submit this form"
                    , icon = Just "fa fa-save"
                    , label = texts.basics.submit
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
        , Html.map FormMsg (Comp.ShareForm.view texts.shareForm model.formModel)
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
