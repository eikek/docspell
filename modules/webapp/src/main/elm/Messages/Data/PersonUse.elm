{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Data.PersonUse exposing
    ( de
    , fr
    , gb
    , pt
    )

import Data.PersonUse exposing (PersonUse(..))


gb : PersonUse -> String
gb pu =
    case pu of
        Correspondent ->
            "Correspondent"

        Concerning ->
            "Concerning"

        Both ->
            "Both"

        Disabled ->
            "Disabled"


de : PersonUse -> String
de pu =
    case pu of
        Correspondent ->
            "Korrespondent"

        Concerning ->
            "Betreffend"

        Both ->
            "Beides"

        Disabled ->
            "Deaktiviert"


fr : PersonUse -> String
fr pu =
    case pu of
        Correspondent ->
            "Correspondante"

        Concerning ->
            "Concernée"

        Both ->
            "Les deux"

        Disabled ->
            "inactif"


pt : PersonUse -> String
pt pu =
    case pu of
        Correspondent ->
            "Correspondente"

        Concerning ->
            "Interessada"

        Both ->
            "Ambas"

        Disabled ->
            "Desativada"
