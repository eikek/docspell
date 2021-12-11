{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ChannelForm exposing
    ( Texts
    , de
    , gb
    )

import Messages.Basics
import Messages.Comp.NotificationGotifyForm
import Messages.Comp.NotificationHttpForm
import Messages.Comp.NotificationMailForm
import Messages.Comp.NotificationMatrixForm


type alias Texts =
    { basics : Messages.Basics.Texts
    , matrixForm : Messages.Comp.NotificationMatrixForm.Texts
    , gotifyForm : Messages.Comp.NotificationGotifyForm.Texts
    , mailForm : Messages.Comp.NotificationMailForm.Texts
    , httpForm : Messages.Comp.NotificationHttpForm.Texts
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , matrixForm = Messages.Comp.NotificationMatrixForm.gb
    , gotifyForm = Messages.Comp.NotificationGotifyForm.gb
    , mailForm = Messages.Comp.NotificationMailForm.gb
    , httpForm = Messages.Comp.NotificationHttpForm.gb
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , matrixForm = Messages.Comp.NotificationMatrixForm.de
    , gotifyForm = Messages.Comp.NotificationGotifyForm.de
    , mailForm = Messages.Comp.NotificationMailForm.de
    , httpForm = Messages.Comp.NotificationHttpForm.de
    }
