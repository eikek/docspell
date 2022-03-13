{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.BookmarkChooser exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.AccountScope exposing (AccountScope(..))
import Messages.Basics
import Messages.Data.AccountScope


type alias Texts =
    { basics : Messages.Basics.Texts
    , userLabel : String
    , collectiveLabel : String
    , shareLabel : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , userLabel = Messages.Data.AccountScope.gb User
    , collectiveLabel = Messages.Data.AccountScope.gb Collective
    , shareLabel = "Shares"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , userLabel = Messages.Data.AccountScope.de User
    , collectiveLabel = Messages.Data.AccountScope.de Collective
    , shareLabel = "Freigaben"
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , userLabel = Messages.Data.AccountScope.fr User
    , collectiveLabel = Messages.Data.AccountScope.fr Collective
    , shareLabel = "Partages"
    }
