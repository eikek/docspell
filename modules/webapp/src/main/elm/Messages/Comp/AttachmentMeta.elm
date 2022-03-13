{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.AttachmentMeta exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.TimeZone exposing (TimeZone)
import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.DateFormat as DF
import Messages.UiLanguage


type alias Texts =
    { basics : Messages.Basics.Texts
    , httpError : Http.Error -> String
    , extractedMetadata : String
    , content : String
    , labels : String
    , proposals : String
    , correspondentOrg : String
    , correspondentPerson : String
    , concerningPerson : String
    , concerningEquipment : String
    , itemDate : String
    , itemDueDate : String
    , formatDateShort : Int -> String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , httpError = Messages.Comp.HttpError.gb
    , extractedMetadata = "Extracted Meta Data"
    , content = "Content"
    , labels = "Labels"
    , proposals = "Proposals"
    , correspondentOrg = "Correspondent Organization"
    , correspondentPerson = "Correspondent Person"
    , concerningPerson = "Concerning Person"
    , concerningEquipment = "Concerning Equipment"
    , itemDate = "Item Date"
    , itemDueDate = "Item Due Date"
    , formatDateShort = DF.formatDateShort Messages.UiLanguage.English tz
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , httpError = Messages.Comp.HttpError.de
    , extractedMetadata = "Extrahierte Metadaten"
    , content = "Inhalt"
    , labels = "Label"
    , proposals = "Vorschläge"
    , correspondentOrg = "Korrespondierende Organisation"
    , correspondentPerson = "Korrespondierende Person"
    , concerningPerson = "Betreffende Person"
    , concerningEquipment = "Betreffende Ausstattung"
    , itemDate = "Datum"
    , itemDueDate = "Fälligkeitsdatum"
    , formatDateShort = DF.formatDateShort Messages.UiLanguage.German tz
    }


fr : TimeZone -> Texts
fr tz =
    { basics = Messages.Basics.fr
    , httpError = Messages.Comp.HttpError.fr
    , extractedMetadata = "Métadonnées extraites"
    , content = "Contenu"
    , labels = "Labels"
    , proposals = "Propositions"
    , correspondentOrg = "Organisation correspondante"
    , correspondentPerson = "Personne correspondante"
    , concerningPerson = "Personne concernée"
    , concerningEquipment = "Equipment concerné"
    , itemDate = "Date du document"
    , itemDueDate = "Date d'échéance"
    , formatDateShort = DF.formatDateShort Messages.UiLanguage.French tz
    }
