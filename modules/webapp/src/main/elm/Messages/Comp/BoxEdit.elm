module Messages.Comp.BoxEdit exposing (Texts, de, gb)

import Messages.Basics
import Messages.Comp.BoxMessageEdit
import Messages.Comp.BoxQueryEdit
import Messages.Comp.BoxStatsEdit
import Messages.Comp.BoxUploadEdit
import Messages.Data.BoxContent


type alias Texts =
    { messageEdit : Messages.Comp.BoxMessageEdit.Texts
    , uploadEdit : Messages.Comp.BoxUploadEdit.Texts
    , queryEdit : Messages.Comp.BoxQueryEdit.Texts
    , statsEdit : Messages.Comp.BoxStatsEdit.Texts
    , boxContent : Messages.Data.BoxContent.Texts
    , basics : Messages.Basics.Texts
    , namePlaceholder : String
    , visible : String
    , decorations : String
    , colspan : String
    , contentProperties : String
    , reallyDeleteBox : String
    , moveToLeft : String
    , moveToRight : String
    , deleteBox : String
    }


gb : Texts
gb =
    { messageEdit = Messages.Comp.BoxMessageEdit.gb
    , uploadEdit = Messages.Comp.BoxUploadEdit.gb
    , queryEdit = Messages.Comp.BoxQueryEdit.gb
    , statsEdit = Messages.Comp.BoxStatsEdit.gb
    , boxContent = Messages.Data.BoxContent.gb
    , basics = Messages.Basics.gb
    , namePlaceholder = "Box name"
    , visible = "Visible"
    , decorations = "Box decorations"
    , colspan = "Column span"
    , contentProperties = "Content"
    , reallyDeleteBox = "Really delete this box?"
    , moveToLeft = "Move to left"
    , moveToRight = "Move to right"
    , deleteBox = "Delete box"
    }


de : Texts
de =
    { messageEdit = Messages.Comp.BoxMessageEdit.de
    , uploadEdit = Messages.Comp.BoxUploadEdit.de
    , queryEdit = Messages.Comp.BoxQueryEdit.de
    , statsEdit = Messages.Comp.BoxStatsEdit.de
    , boxContent = Messages.Data.BoxContent.de
    , basics = Messages.Basics.de
    , namePlaceholder = "Boxname"
    , visible = "Sichtbar"
    , decorations = "Kachel-Dekoration anzeigen"
    , colspan = "Spalten überspannen"
    , contentProperties = "Inhalt"
    , reallyDeleteBox = "Die Kachel wirklich entfernen?"
    , moveToLeft = "Nach links verschieben"
    , moveToRight = "Nach rechts verschieben"
    , deleteBox = "Kachel entfernen"
    }
