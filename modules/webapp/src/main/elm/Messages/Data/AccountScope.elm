{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Data.AccountScope exposing (Texts, de, gb, fr)

import Data.AccountScope exposing (AccountScope)


type alias Texts =
    AccountScope -> String


gb : Texts
gb =
    Data.AccountScope.fold "Personal" "Collective"


de : Texts
de =
    Data.AccountScope.fold "Persönlich" "Kollektiv"


fr : Texts
fr =
    Data.AccountScope.fold "Personnel" "Groupe"