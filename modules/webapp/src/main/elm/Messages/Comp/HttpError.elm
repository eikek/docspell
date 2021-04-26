module Messages.Comp.HttpError exposing (gb)

import Http


gb : Http.Error -> String
gb err =
    let
        texts =
            { badUrl = \url -> "There is something wrong with this url: " ++ url
            , timeout = "There was a network timeout."
            , networkError = "There was a network error."
            , invalidResponseStatus =
                \status ->
                    "There was an invalid response status: " ++ String.fromInt status ++ "."
            , invalidInput = "Invalid input when processing the request."
            , notFound = "The requested resource doesn't exist."
            , invalidBody = \str -> "There was an error decoding the response: " ++ str
            }
    in
    errorToString texts err



-- Error Utilities


type alias Texts =
    { badUrl : String -> String
    , timeout : String
    , networkError : String
    , invalidResponseStatus : Int -> String
    , invalidInput : String
    , notFound : String
    , invalidBody : String -> String
    }


errorToStringStatus : Texts -> Http.Error -> (Int -> String) -> String
errorToStringStatus texts error statusString =
    case error of
        Http.BadUrl url ->
            texts.badUrl url

        Http.Timeout ->
            texts.timeout

        Http.NetworkError ->
            texts.networkError

        Http.BadStatus status ->
            statusString status

        Http.BadBody str ->
            texts.invalidBody str


errorToString : Texts -> Http.Error -> String
errorToString texts error =
    let
        f sc =
            if sc == 404 then
                texts.notFound

            else if sc >= 400 && sc < 500 then
                texts.invalidInput

            else
                texts.invalidResponseStatus sc
    in
    errorToStringStatus texts error f
