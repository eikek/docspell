module Page.NewInvite.Update exposing (update)

import Api
import Api.Model.GenInvite exposing (GenInvite)
import Data.Flags exposing (Flags)
import Page.NewInvite.Data exposing (..)
import Util.Http


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        SetPassword str ->
            ( { model | password = str }, Cmd.none )

        Reset ->
            ( emptyModel, Cmd.none )

        GenerateInvite ->
            ( model, Api.newInvite flags (GenInvite model.password) InviteResp )

        InviteResp (Ok res) ->
            if res.success then
                ( { model | result = Success res }, Cmd.none )

            else
                ( { model | result = Failed res.message }, Cmd.none )

        InviteResp (Err err) ->
            ( { model | result = Failed (Util.Http.errorToString err) }, Cmd.none )
