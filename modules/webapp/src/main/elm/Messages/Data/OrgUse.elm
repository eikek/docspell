{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Messages.Data.OrgUse exposing
    ( de
    , gb
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
