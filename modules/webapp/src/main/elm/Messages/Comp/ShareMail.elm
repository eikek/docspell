{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ShareMail exposing
    ( Texts
    , de
    , fr
    , gb
    , pt
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


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , httpError = Messages.Comp.HttpError.fr
    , itemMail = Messages.Comp.ItemMail.fr
    , subjectTemplate = \mt -> "Documents Partagés" ++ (Maybe.map (\n -> ": " ++ n) mt |> Maybe.withDefault "")
    , bodyTemplate = \url -> """Bonjour,

Ci-joints les documents:

    """ ++ url ++ """

Cordialement
"""
    , mailSent = "Mail envoyé."
    }


pt : Texts
pt =
    { basics = Messages.Basics.pt
    , httpError = Messages.Comp.HttpError.pt
    , itemMail = Messages.Comp.ItemMail.pt
    , subjectTemplate = \mt -> "Documentos compartilhados:" ++ (Maybe.map (\n -> ": " ++ n) mt |> Maybe.withDefault "")
    , bodyTemplate = \url -> """Olá,

 você pode encontrar os documentos aqui:

    """ ++ url ++ """

 Atenciosamente,
"""
    , mailSent = "E-mail enviado."
    }
