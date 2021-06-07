module Messages.Comp.ItemDetail.MultiEditMenu exposing
    ( Texts
    , de
    , gb
    )

import Data.Direction exposing (Direction)
import Messages.Basics
import Messages.Comp.CustomFieldMultiInput
import Messages.Data.Direction


type alias Texts =
    { basics : Messages.Basics.Texts
    , customFieldMultiInput : Messages.Comp.CustomFieldMultiInput.Texts
    , tagModeAddInfo : String
    , tagModeRemoveInfo : String
    , tagModeReplaceInfo : String
    , chooseDirection : String
    , confirmUnconfirm : String
    , confirm : String
    , unconfirm : String
    , changeTagMode : String
    , dueDateTab : String
    , direction : Direction -> String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , customFieldMultiInput = Messages.Comp.CustomFieldMultiInput.gb
    , tagModeAddInfo = "Tags chosen here are *added* to all selected items."
    , tagModeRemoveInfo = "Tags chosen here are *removed* from all selected items."
    , tagModeReplaceInfo = "Tags chosen here *replace* those on selected items."
    , chooseDirection = "Choose a direction…"
    , confirmUnconfirm = "Confirm/Unconfirm item metadata"
    , confirm = "Confirm"
    , unconfirm = "Unconfirm"
    , changeTagMode = "Change tag edit mode"
    , dueDateTab = "Due Date"
    , direction = Messages.Data.Direction.gb
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , customFieldMultiInput = Messages.Comp.CustomFieldMultiInput.de
    , tagModeAddInfo = "Tags werden zu gewählten Dokumenten *hinzugefügt*."
    , tagModeRemoveInfo = "Tags werden von gewählten Dokumenten *entfernt*."
    , tagModeReplaceInfo = "Tags *ersetzen* die der gewählten Dokumente."
    , chooseDirection = "Wähle eine Richtung…"
    , confirmUnconfirm = "Bestätige/Widerrufe Metadaten"
    , confirm = "Bestätige"
    , unconfirm = "Widerufe Betätigung"
    , changeTagMode = "Wechsel den Änderungs-Modus für Tags"
    , dueDateTab = "Fälligkeits-Datum"
    , direction = Messages.Data.Direction.de
    }
