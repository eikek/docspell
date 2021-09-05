{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Messages.Comp.HttpError exposing
    ( de
    , gb
    )

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
            , accessDenied = "Access denied"
            }
    in
    errorToString texts err


de : Http.Error -> String
de err =
    let
        texts =
            { badUrl = \url -> "Die URL ist falsch: " ++ url
            , timeout = "Es gab einen Netzwerk-Timeout."
            , networkError = "Es gab einen Netzwerk-Fehler."
            , invalidResponseStatus =
                \status ->
                    "Ein ungültiger Antwort-Code: " ++ String.fromInt status ++ "."
            , invalidInput = "Die Daten im Request waren ungültig."
            , notFound = "Die angegebene Ressource wurde nicht gefunden."
            , invalidBody = \str -> "Es gab einen Fehler beim Dekodieren der Antwort: " ++ str
            , accessDenied = "Zugriff verweigert"
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
    , accessDenied : String
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

            else if sc == 403 then
                texts.accessDenied

            else if sc >= 400 && sc < 500 then
                texts.invalidInput

            else
                texts.invalidResponseStatus sc
    in
    errorToStringStatus texts error f
