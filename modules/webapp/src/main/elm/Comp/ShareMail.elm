{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.ShareMail exposing (Model, Msg, init, setMailInfo, update, view)

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.ShareDetail exposing (ShareDetail)
import Comp.Basic as B
import Comp.ItemMail
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Messages.Comp.ShareMail exposing (Texts)
import Page exposing (Page(..))
import Styles as S


type FormState
    = FormStateNone
    | FormStateSubmit String
    | FormStateHttp Http.Error
    | FormStateSent


type alias Model =
    { mailModel : Comp.ItemMail.Model
    , share : ShareDetail
    , sending : Bool
    , formState : FormState
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( mm, mc ) =
            Comp.ItemMail.init flags
    in
    ( { mailModel = mm
      , share = Api.Model.ShareDetail.empty
      , sending = False
      , formState = FormStateNone
      }
    , Cmd.map MailMsg mc
    )


type Msg
    = MailMsg Comp.ItemMail.Msg
    | SetMailInfo ShareDetail
    | SendMailResp (Result Http.Error BasicResult)



--- Update


setMailInfo : ShareDetail -> Msg
setMailInfo share =
    SetMailInfo share


update : Texts -> Flags -> Msg -> Model -> ( Model, Cmd Msg )
update texts flags msg model =
    case msg of
        MailMsg lm ->
            let
                ( mm, mc, fa ) =
                    Comp.ItemMail.update flags lm model.mailModel

                defaultResult =
                    ( { model | mailModel = mm }, Cmd.map MailMsg mc )
            in
            case fa of
                Comp.ItemMail.FormSend sm ->
                    let
                        mail =
                            { mail =
                                { shareId = model.share.id
                                , recipients = sm.mail.recipients
                                , cc = sm.mail.cc
                                , bcc = sm.mail.bcc
                                , subject = sm.mail.subject
                                , body = sm.mail.body
                                }
                            , conn = sm.conn
                            }
                    in
                    ( { model | sending = True, mailModel = mm }
                    , Cmd.batch
                        [ Cmd.map MailMsg mc
                        , Api.shareSendMail flags mail SendMailResp
                        ]
                    )

                Comp.ItemMail.FormNone ->
                    defaultResult

                Comp.ItemMail.FormCancel ->
                    defaultResult

        SetMailInfo share ->
            let
                url =
                    flags.config.baseUrl ++ Page.pageToString (SharePage share.id)

                name =
                    share.name

                lm =
                    Comp.ItemMail.setMailInfo
                        (texts.subjectTemplate name)
                        (texts.bodyTemplate url)

                nm =
                    { model
                        | share = share
                        , mailModel = Comp.ItemMail.clearRecipients model.mailModel
                        , formState = FormStateNone
                    }
            in
            update texts flags (MailMsg lm) nm

        SendMailResp (Ok res) ->
            if res.success then
                ( { model
                    | formState = FormStateSent
                    , mailModel = Comp.ItemMail.clearRecipients model.mailModel
                    , sending = False
                  }
                , Cmd.none
                )

            else
                ( { model
                    | formState = FormStateSubmit res.message
                    , sending = False
                  }
                , Cmd.none
                )

        SendMailResp (Err err) ->
            ( { model | formState = FormStateHttp err }, Cmd.none )



--- View


view : Texts -> Flags -> UiSettings -> Model -> Html Msg
view texts flags settings model =
    let
        cfg =
            { withAttachments = False
            , textAreaClass = "h-52"
            , showCancel = False
            }
    in
    div [ class "relative" ]
        [ case model.formState of
            FormStateNone ->
                span [ class "hidden" ] []

            FormStateSubmit msg ->
                div [ class S.errorMessage ]
                    [ text msg
                    ]

            FormStateHttp err ->
                div [ class S.errorMessage ]
                    [ text (texts.httpError err)
                    ]

            FormStateSent ->
                div [ class S.successMessage ]
                    [ text texts.mailSent
                    ]
        , Html.map MailMsg
            (Comp.ItemMail.view texts.itemMail settings cfg model.mailModel)
        , B.loadingDimmer
            { active = model.sending
            , label = ""
            }
        ]
