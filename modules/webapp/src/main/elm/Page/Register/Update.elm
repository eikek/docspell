module Page.Register.Update exposing (update)

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Data.Flags exposing (Flags)
import Page exposing (Page(..))
import Page.Register.Data exposing (..)
import Util.Http


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        RegisterSubmit ->
            case model.errorMsg of
                [] ->
                    let
                        reg =
                            { collectiveName = model.collId
                            , login = model.login
                            , password = model.pass1
                            , invite = model.invite
                            }
                    in
                    ( model, Api.register flags reg SubmitResp )

                _ ->
                    ( model, Cmd.none )

        SetCollId str ->
            let
                m =
                    { model | collId = str }

                err =
                    validateForm m
            in
            ( { m | errorMsg = err }, Cmd.none )

        SetLogin str ->
            let
                m =
                    { model | login = str }

                err =
                    validateForm m
            in
            ( { m | errorMsg = err }, Cmd.none )

        SetPass1 str ->
            let
                m =
                    { model | pass1 = str }

                err =
                    validateForm m
            in
            ( { m | errorMsg = err }, Cmd.none )

        SetPass2 str ->
            let
                m =
                    { model | pass2 = str }

                err =
                    validateForm m
            in
            ( { m | errorMsg = err }, Cmd.none )

        SetInvite str ->
            ( { model
                | invite =
                    if str == "" then
                        Nothing

                    else
                        Just str
              }
            , Cmd.none
            )

        ToggleShowPass1 ->
            ( { model | showPass1 = not model.showPass1 }, Cmd.none )

        ToggleShowPass2 ->
            ( { model | showPass2 = not model.showPass2 }, Cmd.none )

        SubmitResp (Ok r) ->
            let
                m =
                    emptyModel

                cmd =
                    if r.success then
                        Page.goto (LoginPage Nothing)

                    else
                        Cmd.none
            in
            ( { m
                | result =
                    if r.success then
                        Nothing

                    else
                        Just r
              }
            , cmd
            )

        SubmitResp (Err err) ->
            let
                errMsg =
                    Util.Http.errorToString err

                res =
                    BasicResult False
                        (errMsg ++ " Please check the form and try again.")
            in
            ( { model | result = Just res }, Cmd.none )


validateForm : Model -> List String
validateForm model =
    if
        model.collId
            == ""
            || model.login
            == ""
            || model.pass1
            == ""
            || model.pass2
            == ""
    then
        [ "All fields are required!" ]

    else if model.pass1 /= model.pass2 then
        [ "The passwords do not match." ]

    else
        []
