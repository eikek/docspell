module Comp.ChangePasswordForm exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.PasswordChange exposing (PasswordChange)
import Comp.PasswordInput
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
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



-- Update


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



-- View


view : Model -> Html Msg
view model =
    div
        [ classList
            [ ( "ui form", True )
            , ( "error", List.isEmpty model.errors |> not )
            , ( "success", model.successMsg /= "" )
            ]
        ]
        [ div
            [ classList
                [ ( "required field", True )
                , ( "error", model.current == Nothing )
                ]
            ]
            [ label [] [ text "Current Password" ]
            , Html.map SetCurrent (Comp.PasswordInput.view model.current model.currentModel)
            ]
        , div
            [ classList
                [ ( "required field", True )
                , ( "error", model.newPass1 == Nothing )
                ]
            ]
            [ label [] [ text "New Password" ]
            , Html.map SetNew1 (Comp.PasswordInput.view model.newPass1 model.pass1Model)
            ]
        , div
            [ classList
                [ ( "required field", True )
                , ( "error", model.newPass2 == Nothing )
                ]
            ]
            [ label [] [ text "New Password (repeat)" ]
            , Html.map SetNew2 (Comp.PasswordInput.view model.newPass2 model.pass2Model)
            ]
        , div [ class "ui horizontal divider" ] []
        , div [ class "ui success message" ]
            [ text model.successMsg
            ]
        , div [ class "ui error message" ]
            [ case model.errors of
                a :: [] ->
                    text a

                _ ->
                    ul [ class "ui list" ]
                        (List.map (\em -> li [] [ text em ]) model.errors)
            ]
        , div [ class "ui horizontal divider" ] []
        , button [ class "ui primary button", onClick Submit ]
            [ text "Submit"
            ]
        , div
            [ classList
                [ ( "ui dimmer", True )
                , ( "active", model.loading )
                ]
            ]
            [ div [ class "ui loader" ] []
            ]
        ]
