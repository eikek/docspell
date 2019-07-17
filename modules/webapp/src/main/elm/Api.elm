module Api exposing (..)

import Http
import Task
import Util.Http as Http2
import Data.Flags exposing (Flags)
import Api.Model.UserPass exposing (UserPass)
import Api.Model.AuthResult exposing (AuthResult)
import Api.Model.VersionInfo exposing (VersionInfo)

login: Flags -> UserPass -> ((Result Http.Error AuthResult) -> msg) -> Cmd msg
login flags up receive =
    Http.post
        { url = flags.config.baseUrl ++ "/api/v1/open/auth/login"
        , body = Http.jsonBody (Api.Model.UserPass.encode up)
        , expect = Http.expectJson receive Api.Model.AuthResult.decoder
        }

logout: Flags -> ((Result Http.Error ()) -> msg) -> Cmd msg
logout flags receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/auth/logout"
        , account = getAccount flags
        , body = Http.emptyBody
        , expect = Http.expectWhatever receive
        }

loginSession: Flags -> ((Result Http.Error AuthResult) -> msg) -> Cmd msg
loginSession flags receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/auth/session"
        , account = getAccount flags
        , body = Http.emptyBody
        , expect = Http.expectJson receive Api.Model.AuthResult.decoder
        }

versionInfo: Flags -> ((Result Http.Error VersionInfo) -> msg) -> Cmd msg
versionInfo flags receive =
    Http.get
        { url = flags.config.baseUrl ++ "/api/info/version"
        , expect = Http.expectJson receive Api.Model.VersionInfo.decoder
        }

refreshSession: Flags -> ((Result Http.Error AuthResult) -> msg) -> Cmd msg
refreshSession flags receive =
    case flags.account of
        Just acc ->
            if acc.success && acc.validMs > 30000
            then
                let
                    delay = acc.validMs - 30000 |> toFloat
                in
                    Http2.executeIn delay receive (refreshSessionTask flags)
            else Cmd.none
        Nothing ->
            Cmd.none

refreshSessionTask: Flags -> Task.Task Http.Error AuthResult
refreshSessionTask flags =
    Http2.authTask
        { url = flags.config.baseUrl ++ "/api/v1/sec/auth/session"
        , method = "POST"
        , headers = []
        , account = getAccount flags
        , body = Http.emptyBody
        , resolver = Http2.jsonResolver Api.Model.AuthResult.decoder
        , timeout = Nothing
        }

getAccount: Flags -> AuthResult
getAccount flags =
    Maybe.withDefault Api.Model.AuthResult.empty flags.account
