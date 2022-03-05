{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Data.OrgUse exposing
    ( de
    , gb
    , fr
    )

import Data.OrgUse exposing (OrgUse(..))


gb : OrgUse -> String
gb pu =
    case pu of
        Correspondent ->
            "Correspondent"

        Disabled ->
            "Disabled"


de : OrgUse -> String
de pu =
    case pu of
        Correspondent ->
            "Korrespondent"

        Disabled ->
            "Deaktiviert"


fr : OrgUse -> String
fr pu =
    case pu of
        Correspondent ->
            "Correspondant"

        Disabled ->
            "inactif"
