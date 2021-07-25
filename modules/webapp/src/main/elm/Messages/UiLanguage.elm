{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


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
