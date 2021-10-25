{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ShareMail exposing
    ( Texts
    , de
    , gb
    )

import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.Comp.ItemMail


type alias Texts =
    { basics : Messages.Basics.Texts
    , itemMail : Messages.Comp.ItemMail.Texts
    , httpError : Http.Error -> String
    , subjectTemplate : Maybe String -> String
    , bodyTemplate : String -> String
    , mailSent : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , httpError = Messages.Comp.HttpError.gb
    , itemMail = Messages.Comp.ItemMail.gb
    , subjectTemplate = \mt -> "Shared Documents" ++ (Maybe.map (\n -> ": " ++ n) mt |> Maybe.withDefault "")
    , bodyTemplate = \url -> """Hi,

you can find the documents here:

    """ ++ url ++ """

Kind regards
"""
    , mailSent = "Mail sent."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , httpError = Messages.Comp.HttpError.de
    , itemMail = Messages.Comp.ItemMail.de
    , subjectTemplate = \mt -> "Freigegebene Dokumente" ++ (Maybe.map (\n -> ": " ++ n) mt |> Maybe.withDefault "")
    , bodyTemplate = \url -> """Hallo,

die freigegebenen Dokumente befinden sich hier:

    """ ++ url ++ """

Freundliche Grüße
"""
    , mailSent = "E-Mail gesendet."
    }
