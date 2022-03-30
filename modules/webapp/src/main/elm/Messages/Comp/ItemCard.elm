{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ItemCard exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.Direction exposing (Direction)
import Data.TimeZone exposing (TimeZone)
import Messages.Basics
import Messages.Data.Direction
import Messages.DateFormat
import Messages.UiLanguage


type alias Texts =
    { basics : Messages.Basics.Texts
    , dueOn : String
    , new : String
    , openAttachmentFile : String
    , gotoDetail : String
    , cycleAttachments : String
    , formatDateLong : Int -> String
    , formatDateShort : Int -> String
    , directionLabel : Direction -> String
    , showRelatedItems : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , dueOn = "Due on"
    , new = "New"
    , openAttachmentFile = "Open attachment file"
    , gotoDetail = "Go to detail view"
    , cycleAttachments = "Cycle attachments"
    , formatDateLong = Messages.DateFormat.formatDateLong Messages.UiLanguage.English tz
    , formatDateShort = Messages.DateFormat.formatDateShort Messages.UiLanguage.English tz
    , directionLabel = Messages.Data.Direction.gb
    , showRelatedItems = "Show linked items"
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , dueOn = "Fällig am"
    , new = "Neu"
    , openAttachmentFile = "Anhang öffnen"
    , gotoDetail = "Detailansicht"
    , cycleAttachments = "Anhänge durchschalten"
    , formatDateLong = Messages.DateFormat.formatDateLong Messages.UiLanguage.German tz
    , formatDateShort = Messages.DateFormat.formatDateShort Messages.UiLanguage.German tz
    , directionLabel = Messages.Data.Direction.de
    , showRelatedItems = "Verknüpfte Dokumente anzeigen"
    }


fr : TimeZone -> Texts
fr tz =
    { basics = Messages.Basics.fr
    , dueOn = "Échéance le"
    , new = "Nouveau"
    , openAttachmentFile = "Ouvrir la pièce-jointe"
    , gotoDetail = "Voir en détail"
    , cycleAttachments = "Parcourir les pièces-jointes"
    , formatDateLong = Messages.DateFormat.formatDateLong Messages.UiLanguage.French tz
    , formatDateShort = Messages.DateFormat.formatDateShort Messages.UiLanguage.French tz
    , directionLabel = Messages.Data.Direction.fr
    , showRelatedItems = "Afficher les documents liés"
    }
