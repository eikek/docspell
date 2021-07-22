{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Comp.ChangePasswordForm exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view2
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.PasswordChange exposing (PasswordChange)
import Comp.Basic as B
import Comp.PasswordInput
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Messages.Comp.ChangePasswordForm exposing (Texts)
import Styles as S


type alias Model =
    { currentModel : Comp.PasswordInput.Model
    , current : Maybe String
    , pass1Model : Comp.PasswordInput.Model
    , newPass1 : Maybe String
    , pass2Model : Comp.PasswordInput.Model
    , newPass2 : Maybe String
    , formState : FormState
    , loading : Bool
    }


type FormState
    = FormStateNone
    | FormStateHttpError Http.Error
    | FormStateSubmitOk
    | FormStateRequiredMissing
    | FormStatePasswordMismatch
    | FormStateSubmitError String


emptyModel : Model
emptyModel =
    validateModel
        { current = Nothing
        , currentModel = Comp.PasswordInput.init
        , newPass1 = Nothing
        , pass1Model = Comp.PasswordInput.init
        , newPass2 = Nothing
        , pass2Model = Comp.PasswordInput.init
        , loading = False
        , formState = FormStateNone
        }


type Msg
    = SetCurrent Comp.PasswordInput.Msg
    | SetNew1 Comp.PasswordInput.Msg
    | SetNew2 Comp.PasswordInput.Msg
    | Submit
    | SubmitResp (Result Http.Error BasicResult)


validate : Model -> FormState
validate model =
    if model.newPass1 /= Nothing && model.newPass2 /= Nothing && model.newPass1 /= model.newPass2 then
        FormStatePasswordMismatch

    else if model.newPass1 == Nothing || model.newPass2 == Nothing || model.current == Nothing then
        FormStateRequiredMissing

    else
        FormStateNone


validateModel : Model -> Model
validateModel model =
    { model | formState = validate model }



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        SetCurrent m ->
            let
                ( pm, pw ) =
                    Comp.PasswordInput.update m model.currentModel
            in
            ( validateModel { model | currentModel = pm, current = pw }
            , Cmd.none
            )

        SetNew1 m ->
            let
                ( pm, pw ) =
                    Comp.PasswordInput.update m model.pass1Model
            in
            ( validateModel { model | newPass1 = pw, pass1Model = pm }
            , Cmd.none
            )

        SetNew2 m ->
            let
                ( pm, pw ) =
                    Comp.PasswordInput.update m model.pass2Model
            in
            ( validateModel { model | newPass2 = pw, pass2Model = pm }
            , Cmd.none
            )

        Submit ->
            let
                state =
                    validate model

                cp =
                    PasswordChange
                        (Maybe.withDefault "" model.current)
                        (Maybe.withDefault "" model.newPass1)
            in
            if state == FormStateNone then
                ( { model | loading = True, formState = state }
                , Api.changePassword flags cp SubmitResp
                )

            else
                ( { model | formState = state }, Cmd.none )

        SubmitResp (Ok res) ->
            let
                em =
                    { emptyModel | formState = FormStateSubmitOk }
            in
            if res.success then
                ( em, Cmd.none )

            else
                ( { model
                    | formState = FormStateSubmitError res.message
                    , loading = False
                  }
                , Cmd.none
                )

        SubmitResp (Err err) ->
            ( { model
                | formState = FormStateHttpError err
                , loading = False
              }
            , Cmd.none
            )



--- View2


view2 : Texts -> Model -> Html Msg
view2 texts model =
    let
        currentEmpty =
            model.current == Nothing

        pass1Empty =
            model.newPass1 == Nothing

        pass2Empty =
            model.newPass2 == Nothing
    in
    div
        [ class "flex flex-col space-y-4 relative" ]
        [ div []
            [ label [ class S.inputLabel ]
                [ text texts.currentPassword
                , B.inputRequired
                ]
            , Html.map SetCurrent
                (Comp.PasswordInput.view2
                    { placeholder = texts.currentPasswordPlaceholder }
                    model.current
                    currentEmpty
                    model.currentModel
                )
            ]
        , div []
            [ label
                [ class S.inputLabel
                ]
                [ text texts.newPassword
                , B.inputRequired
                ]
            , Html.map SetNew1
                (Comp.PasswordInput.view2
                    { placeholder = texts.newPasswordPlaceholder }
                    model.newPass1
                    pass1Empty
                    model.pass1Model
                )
            ]
        , div []
            [ label [ class S.inputLabel ]
                [ text texts.repeatPassword
                , B.inputRequired
                ]
            , Html.map SetNew2
                (Comp.PasswordInput.view2
                    { placeholder = texts.repeatPasswordPlaceholder }
                    model.newPass2
                    pass2Empty
                    model.pass2Model
                )
            ]
        , renderResultMessage texts model
        , div [ class "flex flex-row" ]
            [ button
                [ class S.primaryButton
                , onClick Submit
                , href "#"
                ]
                [ text "Submit"
                ]
            ]
        , B.loadingDimmer
            { active = model.loading
            , label = texts.basics.loading
            }
        ]


renderResultMessage : Texts -> Model -> Html msg
renderResultMessage texts model =
    div
        [ classList
            [ ( S.errorMessage, model.formState /= FormStateSubmitOk )
            , ( S.successMessage, model.formState == FormStateSubmitOk )
            , ( "hidden", model.formState == FormStateNone )
            ]
        ]
        [ case model.formState of
            FormStateNone ->
                text ""

            FormStateHttpError err ->
                text (texts.httpError err)

            FormStateSubmitError m ->
                text m

            FormStatePasswordMismatch ->
                text texts.passwordMismatch

            FormStateRequiredMissing ->
                text texts.fillRequiredFields

            FormStateSubmitOk ->
                text texts.passwordChangeSuccessful
        ]
