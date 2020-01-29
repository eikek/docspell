module Util.Http exposing
    ( authDelete
    , authGet
    , authPost
    , authPostTrack
    , authPut
    , authTask
    , errorToString
    , executeIn
    , jsonResolver
    )

import Api.Model.AuthResult exposing (AuthResult)
import Http
import Json.Decode as D
import Process
import Task exposing (Task)



-- Authenticated Requests


authReq :
    { url : String
    , account : AuthResult
    , method : String
    , headers : List Http.Header
    , body : Http.Body
    , expect : Http.Expect msg
    , tracker : Maybe String
    }
    -> Cmd msg
authReq req =
    Http.request
        { url = req.url
        , method = req.method
        , headers = Http.header "X-Docspell-Auth" (Maybe.withDefault "" req.account.token) :: req.headers
        , expect = req.expect
        , body = req.body
        , timeout = Nothing
        , tracker = req.tracker
        }


authPost :
    { url : String
    , account : AuthResult
    , body : Http.Body
    , expect : Http.Expect msg
    }
    -> Cmd msg
authPost req =
    authReq
        { url = req.url
        , account = req.account
        , body = req.body
        , expect = req.expect
        , method = "POST"
        , headers = []
        , tracker = Nothing
        }


authPostTrack :
    { url : String
    , account : AuthResult
    , body : Http.Body
    , expect : Http.Expect msg
    , tracker : String
    }
    -> Cmd msg
authPostTrack req =
    authReq
        { url = req.url
        , account = req.account
        , body = req.body
        , expect = req.expect
        , method = "POST"
        , headers = []
        , tracker = Just req.tracker
        }


authPut :
    { url : String
    , account : AuthResult
    , body : Http.Body
    , expect : Http.Expect msg
    }
    -> Cmd msg
authPut req =
    authReq
        { url = req.url
        , account = req.account
        , body = req.body
        , expect = req.expect
        , method = "PUT"
        , headers = []
        , tracker = Nothing
        }


authGet :
    { url : String
    , account : AuthResult
    , expect : Http.Expect msg
    }
    -> Cmd msg
authGet req =
    authReq
        { url = req.url
        , account = req.account
        , body = Http.emptyBody
        , expect = req.expect
        , method = "GET"
        , headers = []
        , tracker = Nothing
        }


authDelete :
    { url : String
    , account : AuthResult
    , expect : Http.Expect msg
    }
    -> Cmd msg
authDelete req =
    authReq
        { url = req.url
        , account = req.account
        , body = Http.emptyBody
        , expect = req.expect
        , method = "DELETE"
        , headers = []
        , tracker = Nothing
        }



-- Error Utilities


errorToStringStatus : Http.Error -> (Int -> String) -> String
errorToStringStatus error statusString =
    case error of
        Http.BadUrl url ->
            "There is something wrong with this url: " ++ url

        Http.Timeout ->
            "There was a network timeout."

        Http.NetworkError ->
            "There was a network error."

        Http.BadStatus status ->
            statusString status

        Http.BadBody str ->
            "There was an error decoding the response: " ++ str


errorToString : Http.Error -> String
errorToString error =
    let
        f sc =
            case sc of
                404 ->
                    "The requested resource doesn't exist."

                _ ->
                    "There was an invalid response status: " ++ String.fromInt sc
    in
    errorToStringStatus error f



-- Http.Task Utilities


jsonResolver : D.Decoder a -> Http.Resolver Http.Error a
jsonResolver decoder =
    Http.stringResolver <|
        \response ->
            case response of
                Http.BadUrl_ url ->
                    Err (Http.BadUrl url)

                Http.Timeout_ ->
                    Err Http.Timeout

                Http.NetworkError_ ->
                    Err Http.NetworkError

                Http.BadStatus_ metadata _ ->
                    Err (Http.BadStatus metadata.statusCode)

                Http.GoodStatus_ _ body ->
                    case D.decodeString decoder body of
                        Ok value ->
                            Ok value

                        Err err ->
                            Err (Http.BadBody (D.errorToString err))


executeIn : Float -> (Result Http.Error a -> msg) -> Task Http.Error a -> Cmd msg
executeIn delay receive task =
    Process.sleep delay
        |> Task.andThen (\_ -> task)
        |> Task.attempt receive


authTask :
    { method : String
    , headers : List Http.Header
    , account : AuthResult
    , url : String
    , body : Http.Body
    , resolver : Http.Resolver x a
    , timeout : Maybe Float
    }
    -> Task x a
authTask req =
    Http.task
        { method = req.method
        , headers = Http.header "X-Docspell-Auth" (Maybe.withDefault "" req.account.token) :: req.headers
        , url = req.url
        , body = req.body
        , resolver = req.resolver
        , timeout = req.timeout
        }
