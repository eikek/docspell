{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.PublishItems exposing
    ( Model
    , Msg
    , Outcome(..)
    , init
    , initQuery
    , update
    , view
    )

import Api
import Api.Model.IdResult exposing (IdResult)
import Api.Model.ShareDetail exposing (ShareDetail)
import Comp.Basic as B
import Comp.MenuBar as MB
import Comp.ShareForm
import Comp.ShareMail
import Comp.ShareView
import Data.Flags exposing (Flags)
import Data.Icons as Icons
import Data.ItemQuery exposing (ItemQuery)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Messages.Comp.PublishItems exposing (Texts)
import Ports
import Styles as S



--- Model


type ViewMode
    = ViewModeEdit
    | ViewModeInfo ShareDetail


type FormError
    = FormErrorNone
    | FormErrorHttp Http.Error
    | FormErrorInvalid
    | FormErrorSubmit String


type alias Model =
    { formModel : Comp.ShareForm.Model
    , mailModel : Comp.ShareMail.Model
    , viewMode : ViewMode
    , formError : FormError
    , loading : Bool
    , mailVisible : Bool
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( fm, fc ) =
            Comp.ShareForm.init

        ( mm, mc ) =
            Comp.ShareMail.init flags
    in
    ( { formModel = fm
      , mailModel = mm
      , viewMode = ViewModeEdit
      , formError = FormErrorNone
      , loading = False
      , mailVisible = False
      }
    , Cmd.batch
        [ Cmd.map FormMsg fc
        , Cmd.map MailMsg mc
        ]
    )


initQuery : Flags -> ItemQuery -> ( Model, Cmd Msg )
initQuery flags query =
    let
        ( fm, fc ) =
            Comp.ShareForm.initQuery (Data.ItemQuery.render query)

        ( mm, mc ) =
            Comp.ShareMail.init flags
    in
    ( { formModel = fm
      , mailModel = mm
      , viewMode = ViewModeEdit
      , formError = FormErrorNone
      , loading = False
      , mailVisible = False
      }
    , Cmd.batch
        [ Cmd.map FormMsg fc
        , Cmd.map MailMsg mc
        ]
    )



--- Update


type Msg
    = FormMsg Comp.ShareForm.Msg
    | MailMsg Comp.ShareMail.Msg
    | CancelPublish
    | SubmitPublish
    | PublishResp (Result Http.Error IdResult)
    | GetShareResp (Result Http.Error ShareDetail)
    | ToggleMailVisible


type Outcome
    = OutcomeDone
    | OutcomeInProgress


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    , outcome : Outcome
    }


update : Texts -> Flags -> Msg -> Model -> UpdateResult
update texts flags msg model =
    case msg of
        CancelPublish ->
            { model = model
            , cmd = Cmd.none
            , sub = Sub.none
            , outcome = OutcomeDone
            }

        FormMsg lm ->
            let
                ( fm, fc, fs ) =
                    Comp.ShareForm.update flags lm model.formModel
            in
            { model = { model | formModel = fm }
            , cmd = Cmd.map FormMsg fc
            , sub = Sub.map FormMsg fs
            , outcome = OutcomeInProgress
            }

        MailMsg lm ->
            let
                ( mm, mc ) =
                    Comp.ShareMail.update texts.shareMail flags lm model.mailModel
            in
            { model = { model | mailModel = mm }
            , cmd = Cmd.map MailMsg mc
            , sub = Sub.none
            , outcome = OutcomeInProgress
            }

        SubmitPublish ->
            case Comp.ShareForm.getShare model.formModel of
                Just ( _, data ) ->
                    { model = { model | loading = True }
                    , cmd = Api.addShare flags data PublishResp
                    , sub = Sub.none
                    , outcome = OutcomeInProgress
                    }

                Nothing ->
                    { model = { model | formError = FormErrorInvalid }
                    , cmd = Cmd.none
                    , sub = Sub.none
                    , outcome = OutcomeInProgress
                    }

        PublishResp (Ok res) ->
            if res.success then
                { model = model
                , cmd = Api.getShare flags res.id GetShareResp
                , sub = Sub.none
                , outcome = OutcomeInProgress
                }

            else
                { model = { model | formError = FormErrorSubmit res.message, loading = False }
                , cmd = Cmd.none
                , sub = Sub.none
                , outcome = OutcomeInProgress
                }

        PublishResp (Err err) ->
            { model = { model | formError = FormErrorHttp err, loading = False }
            , cmd = Cmd.none
            , sub = Sub.none
            , outcome = OutcomeInProgress
            }

        GetShareResp (Ok share) ->
            let
                ( mm, mc ) =
                    Comp.ShareMail.update texts.shareMail flags (Comp.ShareMail.setMailInfo share) model.mailModel
            in
            { model =
                { model
                    | formError = FormErrorNone
                    , loading = False
                    , viewMode = ViewModeInfo share
                    , mailVisible = False
                    , mailModel = mm
                }
            , cmd =
                Cmd.batch
                    [ Ports.initClipboard (Comp.ShareView.clipboardData share)
                    , Cmd.map MailMsg mc
                    ]
            , sub = Sub.none
            , outcome = OutcomeInProgress
            }

        GetShareResp (Err err) ->
            { model = { model | formError = FormErrorHttp err, loading = False }
            , cmd = Cmd.none
            , sub = Sub.none
            , outcome = OutcomeInProgress
            }

        ToggleMailVisible ->
            { model = { model | mailVisible = not model.mailVisible }
            , cmd = Cmd.none
            , sub = Sub.none
            , outcome = OutcomeInProgress
            }



--- View


view : Texts -> UiSettings -> Flags -> Model -> Html Msg
view texts settings flags model =
    div []
        [ B.loadingDimmer
            { active = model.loading
            , label = ""
            }
        , case model.viewMode of
            ViewModeEdit ->
                viewForm texts model

            ViewModeInfo share ->
                viewInfo texts settings flags model share
        ]


viewInfo : Texts -> UiSettings -> Flags -> Model -> ShareDetail -> Html Msg
viewInfo texts settings flags model share =
    let
        cfg =
            { mainClasses = ""
            , showAccessData = False
            }
    in
    div [ class "px-2 mb-4" ]
        [ h1 [ class S.header1 ]
            [ text texts.title
            ]
        , div
            [ class S.infoMessage
            ]
            [ text texts.infoText
            ]
        , MB.view <|
            { start =
                [ MB.SecondaryButton
                    { tagger = CancelPublish
                    , title = texts.cancelPublishTitle
                    , icon = Just "fa fa-arrow-left"
                    , label = texts.doneLabel
                    }
                ]
            , end = []
            , rootClasses = "my-4"
            }
        , div []
            [ Comp.ShareView.view cfg texts.shareView flags share
            ]
        , div
            [ class "flex flex-col mt-6"
            ]
            [ a
                [ class S.header2
                , class "inline-block w-full"
                , href "#"
                , onClick ToggleMailVisible
                ]
                [ if model.mailVisible then
                    i [ class "fa fa-caret-down mr-2" ] []

                  else
                    i [ class "fa fa-caret-right mr-2" ] []
                , text texts.sendViaMail
                ]
            , div [ classList [ ( "hidden", not model.mailVisible ) ] ]
                [ Html.map MailMsg
                    (Comp.ShareMail.view texts.shareMail flags settings model.mailModel)
                ]
            ]
        ]


viewForm : Texts -> Model -> Html Msg
viewForm texts model =
    div [ class "px-2 mb-4" ]
        [ h1 [ class S.header1 ]
            [ text texts.title
            ]
        , div
            [ class S.infoMessage
            ]
            [ text texts.infoText
            ]
        , MB.view <|
            { start =
                [ MB.PrimaryButton
                    { tagger = SubmitPublish
                    , title = texts.submitPublishTitle
                    , icon = Just Icons.share
                    , label = texts.submitPublish
                    }
                , MB.SecondaryButton
                    { tagger = CancelPublish
                    , title = texts.cancelPublishTitle
                    , icon = Just "fa fa-times"
                    , label = texts.cancelPublish
                    }
                ]
            , end = []
            , rootClasses = "my-4"
            }
        , div []
            [ Html.map FormMsg (Comp.ShareForm.view texts.shareForm model.formModel)
            ]
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
        ]
