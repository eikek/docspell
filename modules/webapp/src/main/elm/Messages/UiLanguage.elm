module Messages.UiLanguage exposing
    ( UiLanguage(..)
    , all
    )

{-| This module defines the languages supported in the web app.
-}


type UiLanguage
    = English
    | German


all : List UiLanguage
all =
    [ English
    , German
    ]
