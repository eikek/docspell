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
import Comp.ShareView
import Data.Flags exposing (Flags)
import Data.Icons as Icons
import Data.ItemQuery exposing (ItemQuery)
import Data.SearchMode exposing (SearchMode)
import Html exposing (..)
import Html.Attributes exposing (..)
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
    , viewMode : ViewMode
    , formError : FormError
    , loading : Bool
    }


init : ( Model, Cmd Msg )
init =
    let
        ( fm, fc ) =
            Comp.ShareForm.init
    in
    ( { formModel = fm
      , viewMode = ViewModeEdit
      , formError = FormErrorNone
      , loading = False
      }
    , Cmd.map FormMsg fc
    )


initQuery : ItemQuery -> ( Model, Cmd Msg )
initQuery query =
    let
        ( fm, fc ) =
            Comp.ShareForm.initQuery (Data.ItemQuery.render query)
    in
    ( { formModel = fm
      , viewMode = ViewModeEdit
      , formError = FormErrorNone
      , loading = False
      }
    , Cmd.map FormMsg fc
    )



--- Update


type Msg
    = FormMsg Comp.ShareForm.Msg
    | CancelPublish
    | SubmitPublish
    | PublishResp (Result Http.Error IdResult)
    | GetShareResp (Result Http.Error ShareDetail)


type Outcome
    = OutcomeDone
    | OutcomeInProgress


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , outcome : Outcome
    }


update : Flags -> Msg -> Model -> UpdateResult
update flags msg model =
    case msg of
        CancelPublish ->
            { model = model
            , cmd = Cmd.none
            , outcome = OutcomeDone
            }

        FormMsg lm ->
            let
                ( fm, fc ) =
                    Comp.ShareForm.update flags lm model.formModel
            in
            { model = { model | formModel = fm }
            , cmd = Cmd.map FormMsg fc
            , outcome = OutcomeInProgress
            }

        SubmitPublish ->
            case Comp.ShareForm.getShare model.formModel of
                Just ( _, data ) ->
                    { model = { model | loading = True }
                    , cmd = Api.addShare flags data PublishResp
                    , outcome = OutcomeInProgress
                    }

                Nothing ->
                    { model = { model | formError = FormErrorInvalid }
                    , cmd = Cmd.none
                    , outcome = OutcomeInProgress
                    }

        PublishResp (Ok res) ->
            if res.success then
                { model = model
                , cmd = Api.getShare flags res.id GetShareResp
                , outcome = OutcomeInProgress
                }

            else
                { model = { model | formError = FormErrorSubmit res.message, loading = False }
                , cmd = Cmd.none
                , outcome = OutcomeInProgress
                }

        PublishResp (Err err) ->
            { model = { model | formError = FormErrorHttp err, loading = False }
            , cmd = Cmd.none
            , outcome = OutcomeInProgress
            }

        GetShareResp (Ok share) ->
            { model =
                { model
                    | formError = FormErrorNone
                    , loading = False
                    , viewMode = ViewModeInfo share
                }
            , cmd = Ports.initClipboard (Comp.ShareView.clipboardData share)
            , outcome = OutcomeInProgress
            }

        GetShareResp (Err err) ->
            { model = { model | formError = FormErrorHttp err, loading = False }
            , cmd = Cmd.none
            , outcome = OutcomeInProgress
            }



--- View


view : Texts -> Flags -> Model -> Html Msg
view texts flags model =
    div []
        [ B.loadingDimmer
            { active = model.loading
            , label = ""
            }
        , case model.viewMode of
            ViewModeEdit ->
                viewForm texts model

            ViewModeInfo share ->
                viewInfo texts flags model share
        ]


viewInfo : Texts -> Flags -> Model -> ShareDetail -> Html Msg
viewInfo texts flags model share =
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
