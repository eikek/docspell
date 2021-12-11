{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.EventSample exposing
    ( Texts
    , de
    , gb
    )

import Data.EventType exposing (EventType)
import Http
import Messages.Comp.HttpError
import Messages.Data.EventType


type alias Texts =
    { eventType : EventType -> Messages.Data.EventType.Texts
    , httpError : Http.Error -> String
    , selectEvent : String
    }


gb : Texts
gb =
    { eventType = Messages.Data.EventType.gb
    , httpError = Messages.Comp.HttpError.gb
    , selectEvent = "Select event…"
    }


de : Texts
de =
    { eventType = Messages.Data.EventType.de
    , httpError = Messages.Comp.HttpError.de
    , selectEvent = "Ereignis wählen…"
    }
