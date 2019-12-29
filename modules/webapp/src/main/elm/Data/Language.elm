module Data.Language exposing
    ( Language(..)
    , all
    , fromString
    , toIso3
    , toName
    )


type Language
    = German
    | English


fromString : String -> Maybe Language
fromString str =
    if str == "deu" || str == "de" || str == "german" then
        Just German

    else if str == "eng" || str == "en" || str == "english" then
        Just English

    else
        Nothing


toIso3 : Language -> String
toIso3 lang =
    case lang of
        German ->
            "deu"

        English ->
            "eng"


toName : Language -> String
toName lang =
    case lang of
        German ->
            "German"

        English ->
            "English"


all : List Language
all =
    [ German, English ]
