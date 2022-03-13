{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ItemMerge exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.TimeZone exposing (TimeZone)
import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.DateFormat
import Messages.UiLanguage


type alias Texts =
    { basics : Messages.Basics.Texts
    , httpError : Http.Error -> String
    , title : String
    , infoText : String
    , deleteWarn : String
    , formatDateLong : Int -> String
    , formatDateShort : Int -> String
    , submitMerge : String
    , cancelMerge : String
    , submitMergeTitle : String
    , cancelMergeTitle : String
    , mergeSuccessful : String
    , mergeInProcess : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , httpError = Messages.Comp.HttpError.gb
    , title = "Merge Items"
    , infoText = "When merging items the first item in the list acts as the target. Every other items metadata is copied into the target item. If the property is a single value (like correspondent), it is only set if not already present. Tags, custom fields and attachments are added. The items can be reordered using drag&drop."
    , deleteWarn = "Note that all items but the first one is deleted after a successful merge!"
    , formatDateLong = Messages.DateFormat.formatDateLong Messages.UiLanguage.English tz
    , formatDateShort = Messages.DateFormat.formatDateShort Messages.UiLanguage.English tz
    , submitMerge = "Merge"
    , submitMergeTitle = "Merge the documents now"
    , cancelMerge = "Cancel"
    , cancelMergeTitle = "Back to select view"
    , mergeSuccessful = "Items merged successfully"
    , mergeInProcess = "Items are merged …"
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , httpError = Messages.Comp.HttpError.de
    , title = "Dokumente zusammenführen"
    , infoText = "Beim Zusammenführen der Dokumente, wird das erste in der Liste als Zieldokument verwendet. Die Metadaten der anderen Dokumente werden der Reihe nach auf des Zieldokument geschrieben. Metadaten die nur einen Wert haben, werden nur gesetzt falls noch kein Wert existiert. Tags, Benutzerfelder und Anhänge werden zu dem Zieldokument hinzugefügt. Die Einträge können mit Drag&Drop umgeordnet werden."
    , deleteWarn = "Bitte beachte, dass nach erfolgreicher Zusammenführung alle anderen Dokumente gelöscht werden!"
    , formatDateLong = Messages.DateFormat.formatDateLong Messages.UiLanguage.German tz
    , formatDateShort = Messages.DateFormat.formatDateShort Messages.UiLanguage.German tz
    , submitMerge = "Zusammenführen"
    , submitMergeTitle = "Dokumente jetzt zusammenführen"
    , cancelMerge = "Abbrechen"
    , cancelMergeTitle = "Zurück zur Auswahl"
    , mergeSuccessful = "Die Dokumente wurden erfolgreich zusammengeführt."
    , mergeInProcess = "Dokumente werden zusammengeführt…"
    }


fr : TimeZone -> Texts
fr tz =
    { basics = Messages.Basics.fr
    , httpError = Messages.Comp.HttpError.fr
    , title = "Fusionner des documents"
    , infoText = "Lors d'une fusion, le premier document sert de cible. Les métadonnées des autres documents sont ajoutées à la cible. Si la propriété est un valeur seule (comme correspondant), ceci est ajouté si pas déjà présent. Tags, champs personnalisés et pièces-jointes sont ajoutés. Les documents peuvent être réordonnés avec le glisser/déposer."
    , deleteWarn = "Veuillez noter que tous les documents sont supprimés après une fusion réussie !"
    , formatDateLong = Messages.DateFormat.formatDateLong Messages.UiLanguage.French tz
    , formatDateShort = Messages.DateFormat.formatDateShort Messages.UiLanguage.French tz
    , submitMerge = "Fusionner"
    , submitMergeTitle = "Lancer la fusion"
    , cancelMerge = "Annuler"
    , cancelMergeTitle = "Annuler la fusion"
    , mergeSuccessful = "Documents fusionnés avec succès"
    , mergeInProcess = "Fusion en cours ..."
    }
