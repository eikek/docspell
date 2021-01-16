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
    | French
    | Italian


fromString : String -> Maybe Language
fromString str =
    if str == "deu" || str == "de" || str == "german" then
        Just German

    else if str == "eng" || str == "en" || str == "english" then
        Just English

    else if str == "fra" || str == "fr" || str == "french" then
        Just French

    else if str == "ita" || str == "it" || str == "italian" then
        Just Italian
    else
        Nothing


toIso3 : Language -> String
toIso3 lang =
    case lang of
        German ->
            "deu"

        English ->
            "eng"

        French ->
            "fra"

        Italian ->
            "ita"


toName : Language -> String
toName lang =
    case lang of
        German ->
            "German"

        English ->
            "English"

        French ->
            "French"

        Italian ->
            "Italian"


all : List Language
all =
    [ German, English, French, Italian ]
