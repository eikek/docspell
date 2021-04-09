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
import Util.Http


type alias Model =
    { currentModel : Comp.PasswordInput.Model
    , current : Maybe String
    , pass1Model : Comp.PasswordInput.Model
    , newPass1 : Maybe String
    , pass2Model : Comp.PasswordInput.Model
    , newPass2 : Maybe String
    , errors : List String
    , loading : Bool
    , successMsg : String
    }


emptyModel : Model
emptyModel =
    validateModel
        { current = Nothing
        , currentModel = Comp.PasswordInput.init
        , newPass1 = Nothing
        , pass1Model = Comp.PasswordInput.init
        , newPass2 = Nothing
        , pass2Model = Comp.PasswordInput.init
        , errors = []
        , loading = False
        , successMsg = ""
        }


type Msg
    = SetCurrent Comp.PasswordInput.Msg
    | SetNew1 Comp.PasswordInput.Msg
    | SetNew2 Comp.PasswordInput.Msg
    | Submit
    | SubmitResp (Result Http.Error BasicResult)


validate : Model -> List String
validate model =
    List.concat
        [ if model.newPass1 /= Nothing && model.newPass2 /= Nothing && model.newPass1 /= model.newPass2 then
            [ "New passwords do not match." ]

          else
            []
        , if model.newPass1 == Nothing || model.newPass2 == Nothing || model.current == Nothing then
            [ "Please fill in required fields." ]

          else
            []
        ]


validateModel : Model -> Model
validateModel model =
    let
        err =
            validate model
    in
    { model
        | errors = err
        , successMsg =
            if err == [] then
                model.successMsg

            else
                ""
    }



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
                valid =
                    validate model

                cp =
                    PasswordChange
                        (Maybe.withDefault "" model.current)
                        (Maybe.withDefault "" model.newPass1)
            in
            if List.isEmpty valid then
                ( { model | loading = True, errors = [], successMsg = "" }
                , Api.changePassword flags cp SubmitResp
                )

            else
                ( model, Cmd.none )

        SubmitResp (Ok res) ->
            let
                em =
                    { emptyModel
                        | errors = []
                        , successMsg = "Password has been changed."
                    }
            in
            if res.success then
                ( em, Cmd.none )

            else
                ( { model
                    | errors = [ res.message ]
                    , loading = False
                    , successMsg = ""
                  }
                , Cmd.none
                )

        SubmitResp (Err err) ->
            let
                str =
                    Util.Http.errorToString err
            in
            ( { model
                | errors = [ str ]
                , loading = False
                , successMsg = ""
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
        , div
            [ class S.successMessage
            , classList [ ( "hidden", model.successMsg == "" ) ]
            ]
            [ text model.successMsg
            ]
        , div
            [ class S.errorMessage
            , classList
                [ ( "hidden"
                  , List.isEmpty model.errors
                        || (currentEmpty && pass1Empty && pass2Empty)
                  )
                ]
            ]
            [ case model.errors of
                a :: [] ->
                    text a

                _ ->
                    ul [ class "list-disc" ]
                        (List.map (\em -> li [] [ text em ]) model.errors)
            ]
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
