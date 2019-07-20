module Page.Login.Update exposing (update)

import Api
import Ports
import Data.Flags exposing (Flags)
import Page exposing (Page(..))
import Page.Login.Data exposing (..)
import Api.Model.UserPass exposing (UserPass)
import Api.Model.AuthResult exposing (AuthResult)
import Util.Http

update: Flags -> Msg -> Model -> (Model, Cmd Msg, Maybe AuthResult)
update flags msg model =
    case msg of
        SetUsername str ->
            ({model | username = str}, Cmd.none, Nothing)
        SetPassword str ->
            ({model | password = str}, Cmd.none, Nothing)

        Authenticate ->
            (model, Api.login flags (UserPass model.username model.password) AuthResp, Nothing)

        AuthResp (Ok lr) ->
            if lr.success
            then ({model|result = Just lr, password = ""}, setAccount lr, Just lr)
            else ({model|result = Just lr, password = ""}, Ports.removeAccount "", Just lr)

        AuthResp (Err err) ->
            let
                empty = Api.Model.AuthResult.empty
                lr = {empty|message = Util.Http.errorToString err}
            in
                ({model|password = "", result = Just lr}, Ports.removeAccount "", Just empty)

setAccount: AuthResult -> Cmd msg
setAccount result =
    if result.success
    then Ports.setAccount result
    else Ports.removeAccount ""
