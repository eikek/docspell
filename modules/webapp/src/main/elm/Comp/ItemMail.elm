{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.ItemMail exposing
    ( FormAction(..)
    , Model
    , Msg
    , clear
    , clearRecipients
    , emptyModel
    , init
    , setMailInfo
    , update
    , view
    , view2
    )

import Api
import Api.Model.EmailSettingsList exposing (EmailSettingsList)
import Api.Model.SimpleMail exposing (SimpleMail)
import Comp.Basic as B
import Comp.Dropdown
import Comp.EmailInput
import Comp.MenuBar as MB
import Data.DropdownStyle
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onFocus, onInput)
import Http
import Messages.Comp.ItemMail exposing (Texts)
import Styles as S


type alias Model =
    { connectionModel : Comp.Dropdown.Model String
    , subject : String
    , recipients : List String
    , recipientsModel : Comp.EmailInput.Model
    , ccRecipients : List String
    , ccRecipientsModel : Comp.EmailInput.Model
    , bccRecipients : List String
    , bccRecipientsModel : Comp.EmailInput.Model
    , body : String
    , attachAll : Bool
    , formError : FormError
    }


type FormError
    = FormErrorNone
    | FormErrorNoConnection
    | FormErrorHttp Http.Error


type Msg
    = SetSubject String
    | RecipientMsg Comp.EmailInput.Msg
    | CCRecipientMsg Comp.EmailInput.Msg
    | BCCRecipientMsg Comp.EmailInput.Msg
    | SetBody String
    | SetSubjectBody String String
    | ConnMsg (Comp.Dropdown.Msg String)
    | ConnResp (Result Http.Error EmailSettingsList)
    | ToggleAttachAll
    | Cancel
    | Send


type alias MailInfo =
    { conn : String
    , mail : SimpleMail
    }


type FormAction
    = FormSend MailInfo
    | FormCancel
    | FormNone


emptyModel : Model
emptyModel =
    { connectionModel = Comp.Dropdown.makeSingle
    , subject = ""
    , recipients = []
    , recipientsModel = Comp.EmailInput.init
    , ccRecipients = []
    , ccRecipientsModel = Comp.EmailInput.init
    , bccRecipients = []
    , bccRecipientsModel = Comp.EmailInput.init
    , body = ""
    , attachAll = True
    , formError = FormErrorNone
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( emptyModel, Api.getMailSettings flags "" ConnResp )


clear : Model -> Model
clear model =
    { model
        | subject = ""
        , recipients = []
        , ccRecipients = []
        , bccRecipients = []
        , body = ""
    }


clearRecipients : Model -> Model
clearRecipients model =
    { model
        | recipients = []
        , ccRecipients = []
        , bccRecipients = []
    }


setMailInfo : String -> String -> Msg
setMailInfo subject body =
    SetSubjectBody subject body


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, FormAction )
update flags msg model =
    case msg of
        SetSubject str ->
            ( { model | subject = str }, Cmd.none, FormNone )

        SetSubjectBody subj body ->
            ( { model | subject = subj, body = body }, Cmd.none, FormNone )

        RecipientMsg m ->
            let
                ( em, ec, rec ) =
                    Comp.EmailInput.update flags model.recipients m model.recipientsModel
            in
            ( { model
                | recipients = rec
                , recipientsModel = em
              }
            , Cmd.map RecipientMsg ec
            , FormNone
            )

        CCRecipientMsg m ->
            let
                ( em, ec, rec ) =
                    Comp.EmailInput.update flags model.ccRecipients m model.ccRecipientsModel
            in
            ( { model
                | ccRecipients = rec
                , ccRecipientsModel = em
              }
            , Cmd.map CCRecipientMsg ec
            , FormNone
            )

        BCCRecipientMsg m ->
            let
                ( em, ec, rec ) =
                    Comp.EmailInput.update flags model.bccRecipients m model.bccRecipientsModel
            in
            ( { model | bccRecipients = rec, bccRecipientsModel = em }
            , Cmd.map BCCRecipientMsg ec
            , FormNone
            )

        SetBody str ->
            ( { model | body = str }, Cmd.none, FormNone )

        ConnMsg m ->
            let
                ( cm, _ ) =
                    -- dropdown doesn't use cmd!!
                    Comp.Dropdown.update m model.connectionModel
            in
            ( { model | connectionModel = cm }, Cmd.none, FormNone )

        ToggleAttachAll ->
            ( { model | attachAll = not model.attachAll }, Cmd.none, FormNone )

        ConnResp (Ok list) ->
            let
                names =
                    List.map .name list.items

                cm =
                    Comp.Dropdown.makeSingleList
                        { options = names
                        , selected = List.head names
                        }
            in
            ( { model
                | connectionModel = cm
                , formError =
                    if names == [] then
                        FormErrorNoConnection

                    else
                        FormErrorNone
              }
            , Cmd.none
            , FormNone
            )

        ConnResp (Err err) ->
            ( { model | formError = FormErrorHttp err }, Cmd.none, FormNone )

        Cancel ->
            ( model, Cmd.none, FormCancel )

        Send ->
            case ( model.formError, Comp.Dropdown.getSelected model.connectionModel ) of
                ( FormErrorNone, conn :: [] ) ->
                    let
                        emptyMail =
                            Api.Model.SimpleMail.empty

                        sm =
                            { emptyMail
                                | recipients = model.recipients
                                , cc = model.ccRecipients
                                , bcc = model.bccRecipients
                                , subject = model.subject
                                , body = model.body
                                , addAllAttachments = model.attachAll
                            }
                    in
                    ( model, Cmd.none, FormSend { conn = conn, mail = sm } )

                _ ->
                    ( model, Cmd.none, FormNone )


isValid : Model -> Bool
isValid model =
    model.recipients
        /= []
        && model.subject
        /= ""
        && model.body
        /= ""
        && model.formError
        == FormErrorNone
        && Comp.Dropdown.getSelected model.connectionModel
        /= []



--- View2


type alias ViewConfig =
    { withAttachments : Bool
    , textAreaClass : String
    , showCancel : Bool
    }


view2 : Texts -> UiSettings -> Model -> Html Msg
view2 texts settings model =
    let
        cfg =
            { withAttachments = True
            , textAreaClass = ""
            , showCancel = True
            }
    in
    view texts settings cfg model


view : Texts -> UiSettings -> ViewConfig -> Model -> Html Msg
view texts settings cfg model =
    let
        dds =
            Data.DropdownStyle.mainStyle

        connectionCfg =
            { makeOption = \a -> { text = a, additional = "" }
            , placeholder = texts.selectConnection
            , labelColor = \_ -> \_ -> ""
            , style = dds
            }
    in
    div
        [ class "flex flex-col"
        ]
        [ div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text texts.sendVia
                , B.inputRequired
                ]
            , Html.map ConnMsg
                (Comp.Dropdown.view2
                    connectionCfg
                    settings
                    model.connectionModel
                )
            ]
        , div
            [ class S.errorMessage
            , classList [ ( "hidden", model.formError == FormErrorNone ) ]
            ]
            [ case model.formError of
                FormErrorNone ->
                    text ""

                FormErrorHttp err ->
                    text (texts.httpError err)

                FormErrorNoConnection ->
                    text texts.connectionMissing
            ]
        , div [ class "mb-4" ]
            [ label
                [ class S.inputLabel
                ]
                [ text texts.recipients
                , B.inputRequired
                ]
            , Html.map RecipientMsg
                (Comp.EmailInput.view2 { style = dds, placeholder = appendDots texts.recipients }
                    model.recipients
                    model.recipientsModel
                )
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text texts.ccRecipients
                ]
            , Html.map CCRecipientMsg
                (Comp.EmailInput.view2 { style = dds, placeholder = appendDots texts.ccRecipients }
                    model.ccRecipients
                    model.ccRecipientsModel
                )
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text texts.bccRecipients
                ]
            , Html.map BCCRecipientMsg
                (Comp.EmailInput.view2 { style = dds, placeholder = appendDots texts.bccRecipients }
                    model.bccRecipients
                    model.bccRecipientsModel
                )
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text texts.subject
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , class S.textInput
                , onInput SetSubject
                , value model.subject
                ]
                []
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text texts.body
                , B.inputRequired
                ]
            , textarea
                [ onInput SetBody
                , value model.body
                , class S.textAreaInput
                , class cfg.textAreaClass
                ]
                []
            ]
        , if cfg.withAttachments then
            MB.viewItem <|
                MB.Checkbox
                    { tagger = \_ -> ToggleAttachAll
                    , label = texts.includeAllAttachments
                    , value = model.attachAll
                    , id = "item-send-mail-attach-all"
                    }

          else
            span [ class "hidden" ] []
        , div [ class "flex flex-row space-x-2" ]
            [ B.primaryButton
                { label = texts.sendLabel
                , icon = "fa fa-paper-plane font-thin"
                , handler = onClick Send
                , attrs = [ href "#" ]
                , disabled = not (isValid model)
                }
            , B.secondaryButton
                { label = texts.basics.cancel
                , icon = "fa fa-times"
                , handler = onClick Cancel
                , attrs =
                    [ href "#"
                    , classList [ ( "hidden", not cfg.showCancel ) ]
                    ]
                , disabled = False
                }
            ]
        ]


appendDots : String -> String
appendDots name =
    name ++ "…"
