module Data.SSLType exposing
    ( SSLType(..)
    , all
    , fromString
    , label
    , toString
    )


type SSLType
    = None
    | SSL
    | StartTLS


all : List SSLType
all =
    [ None, SSL, StartTLS ]


toString : SSLType -> String
toString st =
    case st of
        None ->
            "none"

        SSL ->
            "ssl"

        StartTLS ->
            "starttls"


fromString : String -> Maybe SSLType
fromString str =
    case String.toLower str of
        "none" ->
            Just None

        "ssl" ->
            Just SSL

        "starttls" ->
            Just StartTLS

        _ ->
            Nothing


label : SSLType -> String
label st =
    case st of
        None ->
            "None"

        SSL ->
            "SSL/TLS"

        StartTLS ->
            "StartTLS"
