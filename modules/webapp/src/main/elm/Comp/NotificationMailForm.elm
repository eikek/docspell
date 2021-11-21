{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.NotificationMailForm exposing (Model, Msg, init, initWith, update, view)

import Api
import Api.Model.EmailSettingsList exposing (EmailSettingsList)
import Api.Model.NotificationMail exposing (NotificationMail)
import Comp.Basic as B
import Comp.Dropdown
import Comp.EmailInput
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Data.NotificationChannel
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Http
import Messages.Comp.NotificationMailForm exposing (Texts)
import Styles as S


type alias Model =
    { hook : NotificationMail
    , connectionModel : Comp.Dropdown.Model String
    , recipients : List String
    , recipientsModel : Comp.EmailInput.Model
    , formState : FormState
    }


type FormState
    = FormStateInitial
    | FormStateHttpError Http.Error
    | FormStateInvalid ValidateError


type ValidateError
    = ValidateConnectionMissing


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { hook = Data.NotificationChannel.setTypeMail Api.Model.NotificationMail.empty
      , connectionModel = Comp.Dropdown.makeSingle
      , recipients = []
      , recipientsModel = Comp.EmailInput.init
      , formState = FormStateInitial
      }
    , Cmd.batch
        [ Api.getMailSettings flags "" ConnResp
        ]
    )


initWith : Flags -> NotificationMail -> ( Model, Cmd Msg )
initWith flags hook =
    let
        ( mm, mc ) =
            init flags

        ( cm, _ ) =
            Comp.Dropdown.update (Comp.Dropdown.SetSelection [ hook.connection ]) mm.connectionModel
    in
    ( { mm
        | hook = Data.NotificationChannel.setTypeMail hook
        , recipients = hook.recipients
        , connectionModel = cm
      }
    , mc
    )


type Msg
    = ConnResp (Result Http.Error EmailSettingsList)
    | ConnMsg (Comp.Dropdown.Msg String)
    | RecipientMsg Comp.EmailInput.Msg



--- Update


check : Model -> Maybe NotificationMail
check model =
    let
        formState =
            if model.formState == FormStateInitial then
                Just ()

            else
                Nothing

        recipients =
            if List.isEmpty model.recipients then
                Nothing

            else
                Just model.recipients

        connection =
            Comp.Dropdown.getSelected model.connectionModel
                |> List.head

        h =
            model.hook

        makeHook _ rec conn =
            { h | connection = conn, recipients = rec }
    in
    Maybe.map3 makeHook formState recipients connection


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Maybe NotificationMail )
update flags msg model =
    case msg of
        ConnResp (Ok list) ->
            let
                names =
                    List.map .name list.items

                cm =
                    Comp.Dropdown.makeSingleList
                        { options = names
                        , selected = List.head names
                        }

                model_ =
                    { model
                        | connectionModel = cm
                        , formState =
                            if names == [] then
                                FormStateInvalid ValidateConnectionMissing

                            else
                                FormStateInitial
                    }
            in
            ( model_
            , Cmd.none
            , check model_
            )

        ConnResp (Err err) ->
            ( { model | formState = FormStateHttpError err }
            , Cmd.none
            , Nothing
            )

        ConnMsg lm ->
            let
                ( cm, cc ) =
                    Comp.Dropdown.update lm model.connectionModel

                model_ =
                    { model
                        | connectionModel = cm
                        , formState = FormStateInitial
                    }
            in
            ( model_
            , Cmd.map ConnMsg cc
            , check model_
            )

        RecipientMsg lm ->
            let
                ( em, ec, rec ) =
                    Comp.EmailInput.update flags model.recipients lm model.recipientsModel

                model_ =
                    { model
                        | recipients = rec
                        , recipientsModel = em
                        , formState = FormStateInitial
                    }
            in
            ( model_
            , Cmd.map RecipientMsg ec
            , check model_
            )



--- View


view : Texts -> UiSettings -> Model -> Html Msg
view texts settings model =
    let
        connectionCfg =
            { makeOption = \a -> { text = a, additional = "" }
            , placeholder = texts.selectConnection
            , labelColor = \_ -> \_ -> ""
            , style = DS.mainStyle
            }
    in
    div []
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
            , span [ class "opacity-50 text-sm" ]
                [ text texts.sendViaInfo
                ]
            ]
        , div [ class "" ]
            [ label
                [ class S.inputLabel
                ]
                [ text texts.recipients
                , B.inputRequired
                ]
            , Html.map RecipientMsg
                (Comp.EmailInput.view2
                    { style = DS.mainStyle, placeholder = texts.recipients }
                    model.recipients
                    model.recipientsModel
                )
            , span [ class "opacity-50 text-sm" ]
                [ text texts.recipientsInfo
                ]
            ]
        ]
