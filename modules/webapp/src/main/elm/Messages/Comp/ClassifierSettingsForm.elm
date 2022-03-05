{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ClassifierSettingsForm exposing
    ( Texts
    , de
    , gb
    , fr
    )

import Data.TimeZone exposing (TimeZone)
import Messages.Basics
import Messages.Comp.CalEventInput


type alias Texts =
    { basics : Messages.Basics.Texts
    , calEventInput : Messages.Comp.CalEventInput.Texts
    , autoTaggingText : String
    , blacklistOrWhitelist : String
    , whitelistLabel : String
    , blacklistLabel : String
    , itemCount : String
    , schedule : String
    , itemCountHelp : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , calEventInput = Messages.Comp.CalEventInput.gb tz
    , autoTaggingText =
        """

Auto-tagging works by learning from existing documents. The more
documents you have correctly tagged, the better. Learning is done
periodically based on a schedule. You can specify tag-groups that
should either be used (whitelist) or not used (blacklist) for
learning.

Use an empty whitelist to disable auto tagging.

            """
    , blacklistOrWhitelist = "Is the following a blacklist or whitelist?"
    , whitelistLabel = "Include tag categories for learning"
    , blacklistLabel = "Exclude tag categories from learning"
    , itemCount = "Item Count"
    , schedule = "Schedule"
    , itemCountHelp = "The maximum number of items to learn from, order by date newest first. Use 0 to mean all."
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , calEventInput = Messages.Comp.CalEventInput.de tz
    , autoTaggingText =
        """

Das automatische Taggen funktioniert über das Lernen aus bereits
existierenden Dokumenten. Je mehr Dokumente korrekt getagged sind,
desto besser. Das Lernen geschieht regelmäßig nach einem Zeitplan. Hier
können Tag-Gruppen definiert werden, die entweder nicht gelernt werden
sollen (Blacklist) oder ausschließlich gelernt werden sollen
(Whitelist).

Eine leere Whitelist stellt das Auto-Tagging ab.
"""
    , blacklistOrWhitelist = "Ist das folgende eine Blacklist oder eine Whitelist?"
    , whitelistLabel = "EINschließen der Tag-Kategorien"
    , blacklistLabel = "AUSschließen der Tag-Kategorien"
    , itemCount = "Anzahl"
    , schedule = "Zeitplan"
    , itemCountHelp = "Die maximale Anzahl an Dokumenten, von denen gelernt werden soll (sortiert nach Datum, neueste zuerst). Verwende 0 um alle einzuschließen."
    }


fr : TimeZone -> Texts
fr tz =
    { basics = Messages.Basics.fr
    , calEventInput = Messages.Comp.CalEventInput.fr tz
    , autoTaggingText =
        """
L'Auto-Tagging fonctionne en apprenant des documents existants. Plus
de documents seront tagués correctement, le mieux cela marchera. Les tâches 
d'apprentissage sont effectuées périodiquement selon une programmation.
Il est possible de spécifier la catégorie de tag qui doit être utilisée pour 
l'apprentissage (liste blanche) ou ignorée (liste noire).

Laisser liste blanche vide  désactive l'Auto-Tagging.

            """
    , blacklistOrWhitelist = "Les catégories suivantes sont-elles en liste blanche ou noire ?"
    , whitelistLabel = "Inclure ces catégories de tag pour l'apprentissage"
    , blacklistLabel = "Exclure ces catégories de tag pour l'apprentissage"
    , itemCount = "Nombre maximum de documents à utiliser"
    , schedule = "Programmation"
    , itemCountHelp = "Le nombre de maximum de documents à utilser pour l'apprentissage, classés pas date (le plus récent en premier). Laisser 0 si pas de limite."
    }