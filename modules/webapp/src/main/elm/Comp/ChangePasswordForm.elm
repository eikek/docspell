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
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Util.Http


type alias Model =
    { current : String
    , newPass1 : String
    , newPass2 : String
    , showCurrent : Bool
    , showPass1 : Bool
    , showPass2 : Bool
    , errors : List String
    , loading : Bool
    , successMsg : String
    }


emptyModel : Model
emptyModel =
    validateModel
        { current = ""
        , newPass1 = ""
        , newPass2 = ""
        , showCurrent = False
        , showPass1 = False
        , showPass2 = False
        , errors = []
        , loading = False
        , successMsg = ""
        }


type Msg
    = SetCurrent String
    | SetNew1 String
    | SetNew2 String
    | ToggleShowPass1
    | ToggleShowPass2
    | ToggleShowCurrent
    | Submit
    | SubmitResp (Result Http.Error BasicResult)


validate : Model -> List String
validate model =
    List.concat
        [ if model.newPass1 /= "" && model.newPass2 /= "" && model.newPass1 /= model.newPass2 then
            [ "New passwords do not match." ]

          else
            []
        , if model.newPass1 == "" || model.newPass2 == "" || model.current == "" then
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
        SetCurrent s ->
            ( validateModel { model | current = s }, Cmd.none )

        SetNew1 s ->
            ( validateModel { model | newPass1 = s }, Cmd.none )

        SetNew2 s ->
            ( validateModel { model | newPass2 = s }, Cmd.none )

        ToggleShowCurrent ->
            ( { model | showCurrent = not model.showCurrent }, Cmd.none )

        ToggleShowPass1 ->
            ( { model | showPass1 = not model.showPass1 }, Cmd.none )

        ToggleShowPass2 ->
            ( { model | showPass2 = not model.showPass2 }, Cmd.none )

        Submit ->
            let
                valid =
                    validate model

                cp =
                    PasswordChange model.current model.newPass1
            in
            if List.isEmpty valid then
                ( { model | loading = True, errors = [], successMsg = "" }, Api.changePassword flags cp SubmitResp )

            else
                ( model, Cmd.none )

        SubmitResp (Ok res) ->
            let
                em =
                    { emptyModel | errors = [], successMsg = "Password has been changed." }
            in
            if res.success then
                ( em, Cmd.none )

            else
                ( { model | errors = [ res.message ], loading = False, successMsg = "" }, Cmd.none )

        SubmitResp (Err err) ->
            let
                str =
                    Util.Http.errorToString err
            in
            ( { model | errors = [ str ], loading = False, successMsg = "" }, Cmd.none )



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
                [ ( "field", True )
                , ( "error", model.current == "" )
                ]
            ]
            [ label [] [ text "Current Password*" ]
            , div [ class "ui action input" ]
                [ input
                    [ type_ <|
                        if model.showCurrent then
                            "text"

                        else
                            "password"
                    , onInput SetCurrent
                    , value model.current
                    ]
                    []
                , button [ class "ui icon button", onClick ToggleShowCurrent ]
                    [ i [ class "eye icon" ] []
                    ]
                ]
            ]
        , div
            [ classList
                [ ( "field", True )
                , ( "error", model.newPass1 == "" )
                ]
            ]
            [ label [] [ text "New Password*" ]
            , div [ class "ui action input" ]
                [ input
                    [ type_ <|
                        if model.showPass1 then
                            "text"

                        else
                            "password"
                    , onInput SetNew1
                    , value model.newPass1
                    ]
                    []
                , button [ class "ui icon button", onClick ToggleShowPass1 ]
                    [ i [ class "eye icon" ] []
                    ]
                ]
            ]
        , div
            [ classList
                [ ( "field", True )
                , ( "error", model.newPass2 == "" )
                ]
            ]
            [ label [] [ text "New Password (repeat)*" ]
            , div [ class "ui action input" ]
                [ input
                    [ type_ <|
                        if model.showPass2 then
                            "text"

                        else
                            "password"
                    , onInput SetNew2
                    , value model.newPass2
                    ]
                    []
                , button [ class "ui icon button", onClick ToggleShowPass2 ]
                    [ i [ class "eye icon" ] []
                    ]
                ]
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
