{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Comp.OtpSetup exposing (Model, Msg, init, update, view)

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.OtpConfirm exposing (OtpConfirm)
import Api.Model.OtpResult exposing (OtpResult)
import Api.Model.OtpState exposing (OtpState)
import Comp.Basic as B
import Comp.PasswordInput
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Markdown
import Messages.Comp.OtpSetup exposing (Texts)
import QRCode
import Styles as S


type Model
    = InitialModel
    | StateError Http.Error
    | InitError Http.Error
    | DisableError Http.Error
    | ConfirmError Http.Error
    | StateEnabled EnabledModel
    | StateDisabled DisabledModel
    | SetupSuccessful


type alias DisabledModel =
    { loading : Bool
    , result : Maybe OtpResult
    , secretModel : Comp.PasswordInput.Model
    , confirmCode : String
    , confirmError : Bool
    }


initDisabledModel : DisabledModel
initDisabledModel =
    { loading = False
    , result = Nothing
    , secretModel = Comp.PasswordInput.init
    , confirmCode = ""
    , confirmError = False
    }


type alias EnabledModel =
    { created : Int
    , loading : Bool
    , confirmText : String
    , confirmTextWrong : Bool
    }


initEnabledModel : Int -> EnabledModel
initEnabledModel created =
    { created = created
    , loading = False
    , confirmText = ""
    , confirmTextWrong = False
    }


emptyModel : Model
emptyModel =
    InitialModel


type Msg
    = GetStateResp (Result Http.Error OtpState)
    | Initialize
    | InitResp (Result Http.Error OtpResult)
    | SetConfirmCode String
    | SecretMsg Comp.PasswordInput.Msg
    | Confirm
    | ConfirmResp (Result Http.Error BasicResult)
    | SetDisableConfirmText String
    | Disable
    | DisableResp (Result Http.Error BasicResult)


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( emptyModel, Api.getOtpState flags GetStateResp )



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        GetStateResp (Ok state) ->
            if state.enabled then
                ( StateEnabled <| initEnabledModel (Maybe.withDefault 0 state.created), Cmd.none )

            else
                ( StateDisabled initDisabledModel, Cmd.none )

        GetStateResp (Err err) ->
            ( StateError err, Cmd.none )

        Initialize ->
            case model of
                StateDisabled _ ->
                    ( StateDisabled { initDisabledModel | loading = True }
                    , Api.initOtp flags InitResp
                    )

                _ ->
                    ( model, Cmd.none )

        InitResp (Ok r) ->
            case model of
                StateDisabled m ->
                    ( StateDisabled { m | result = Just r, loading = False }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        InitResp (Err err) ->
            ( InitError err, Cmd.none )

        SetConfirmCode str ->
            case model of
                StateDisabled m ->
                    ( StateDisabled { m | confirmCode = str }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        SecretMsg lm ->
            case model of
                StateDisabled m ->
                    let
                        ( pm, _ ) =
                            Comp.PasswordInput.update lm m.secretModel
                    in
                    ( StateDisabled { m | secretModel = pm }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Confirm ->
            case model of
                StateDisabled m ->
                    ( StateDisabled { m | loading = True }
                    , Api.confirmOtp flags (OtpConfirm m.confirmCode) ConfirmResp
                    )

                _ ->
                    ( model, Cmd.none )

        ConfirmResp (Ok result) ->
            case model of
                StateDisabled m ->
                    if result.success then
                        ( SetupSuccessful, Cmd.none )

                    else
                        ( StateDisabled { m | confirmError = True, loading = False }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ConfirmResp (Err err) ->
            ( ConfirmError err, Cmd.none )

        SetDisableConfirmText str ->
            case model of
                StateEnabled m ->
                    ( StateEnabled { m | confirmText = str }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Disable ->
            case model of
                StateEnabled m ->
                    if String.toLower m.confirmText == "ok" then
                        ( StateEnabled { m | confirmTextWrong = False, loading = True }
                        , Api.disableOtp flags DisableResp
                        )

                    else
                        ( StateEnabled { m | confirmTextWrong = True }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        DisableResp (Ok result) ->
            if result.success then
                init flags

            else
                ( model, Cmd.none )

        DisableResp (Err err) ->
            ( DisableError err, Cmd.none )



--- View


view : Texts -> Model -> Html Msg
view texts model =
    case model of
        InitialModel ->
            div [] []

        StateError err ->
            viewHttpError texts texts.stateErrorInfoText err

        InitError err ->
            viewHttpError texts texts.initErrorInfo err

        ConfirmError err ->
            viewHttpError texts texts.confirmErrorInfo err

        DisableError err ->
            viewHttpError texts texts.disableErrorInfo err

        SetupSuccessful ->
            viewSetupSuccessful texts

        StateEnabled m ->
            viewEnabled texts m

        StateDisabled m ->
            viewDisabled texts m


viewEnabled : Texts -> EnabledModel -> Html Msg
viewEnabled texts model =
    div []
        [ h2 [ class S.header2 ]
            [ text texts.twoFaActiveSince
            , text <| texts.formatDateShort model.created
            ]
        , p []
            [ text texts.revert2FAText
            ]
        , div [ class "flex flex-col items-center mt-6" ]
            [ div [ class "flex flex-row max-w-md" ]
                [ input
                    [ type_ "text"
                    , value model.confirmText
                    , onInput SetDisableConfirmText
                    , class S.textInput
                    , class "rounded-r-none"
                    ]
                    []
                , B.genericButton
                    { label = texts.disableButton
                    , icon =
                        if model.loading then
                            "fa fa-circle-notch animate-spin"

                        else
                            "fa fa-exclamation-circle"
                    , handler = onClick Disable
                    , disabled = model.loading
                    , attrs = [ href "#" ]
                    , baseStyle = S.primaryButtonPlain ++ " rounded-r"
                    , activeStyle = S.primaryButtonHover
                    }
                ]
            , div
                [ class S.errorMessage
                , class "my-2"
                , classList [ ( "hidden", not model.confirmTextWrong ) ]
                ]
                [ text texts.disableConfirmErrorMsg
                ]
            , Markdown.toHtml [ class "mt-2" ] texts.disableConfirmBoxInfo
            ]
        ]


viewDisabled : Texts -> DisabledModel -> Html Msg
viewDisabled texts model =
    div []
        [ h2 [ class S.header2 ]
            [ text texts.setupTwoFactorAuth
            ]
        , p []
            [ text texts.setupTwoFactorAuthInfo
            ]
        , case model.result of
            Nothing ->
                div [ class "flex flex-row items-center justify-center my-6 px-2" ]
                    [ B.primaryButton
                        { label = texts.activateButton
                        , icon =
                            if model.loading then
                                "fa fa-circle-notch animate-spin"

                            else
                                "fa fa-key"
                        , disabled = model.loading
                        , handler = onClick Initialize
                        , attrs = [ href "#" ]
                        }
                    ]

            Just data ->
                div [ class "flex flex-col mt-6" ]
                    [ div [ class "flex flex-col items-center justify-center" ]
                        [ div
                            [ class S.border
                            , class S.qrCode
                            ]
                            [ qrCodeView texts data.authenticatorUrl
                            ]
                        , div [ class "mt-4" ]
                            [ p []
                                [ text texts.scanQRCode
                                ]
                            ]
                        ]
                    , div [ class "flex flex-col items-center justify-center mt-4" ]
                        [ Html.form [ class "flex flex-row relative", onSubmit Confirm ]
                            [ input
                                [ type_ "text"
                                , name "confirm-setup"
                                , autocomplete False
                                , onInput SetConfirmCode
                                , value model.confirmCode
                                , autofocus True
                                , class "pl-2 pr-10 py-2 rounded-lg max-w-xs text-center font-mono "
                                , class S.textInput
                                , if model.confirmError then
                                    class S.inputErrorBorder

                                  else
                                    class ""
                                , placeholder "123456"
                                ]
                                []
                            , a
                                [ class S.inputLeftIconLink
                                , href "#"
                                , onClick Confirm
                                ]
                                [ if model.loading then
                                    i [ class "fa fa-circle-notch animate-spin" ] []

                                  else
                                    i [ class "fa fa-check" ] []
                                ]
                            ]
                        , div
                            [ classList [ ( "hidden", not model.confirmError ) ]
                            , class S.errorMessage
                            , class "mt-2"
                            ]
                            [ text texts.setupCodeInvalid ]
                        , div [ class "mt-6" ]
                            [ p [] [ text texts.ifNotQRCode ]
                            , div [ class "max-w-md mx-auto mt-4" ]
                                [ Html.map SecretMsg
                                    (Comp.PasswordInput.view2
                                        { placeholder = "" }
                                        (Just data.secret)
                                        False
                                        model.secretModel
                                    )
                                ]
                            ]
                        ]
                    ]
        ]


qrCodeView : Texts -> String -> Html msg
qrCodeView texts message =
    QRCode.encode message
        |> Result.map QRCode.toSvg
        |> Result.withDefault
            (Html.text texts.errorGeneratingQR)


viewHttpError : Texts -> String -> Http.Error -> Html Msg
viewHttpError texts descr err =
    div [ class S.errorMessage ]
        [ h2 [ class S.header2 ]
            [ text texts.errorTitle
            ]
        , p []
            [ text descr
            , text " "
            , text <| texts.httpError err
            ]
        , p []
            [ text texts.reloadToTryAgain
            ]
        ]


viewSetupSuccessful : Texts -> Html msg
viewSetupSuccessful texts =
    div [ class "flex flex-col" ]
        [ div
            [ class S.successMessage
            , class "text-lg"
            ]
            [ h2
                [ class "text-2xl font-medium tracking-wide"
                ]
                [ i [ class "fa fa-check mr-2" ] []
                , text texts.twoFactorNowActive
                ]
            ]
        , div [ class "mt-4" ]
            [ text texts.revertInfo
            ]
        ]
