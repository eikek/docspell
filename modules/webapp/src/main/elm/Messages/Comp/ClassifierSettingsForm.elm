{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Messages.Comp.ClassifierSettingsForm exposing
    ( Texts
    , de
    , gb
    )

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


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , calEventInput = Messages.Comp.CalEventInput.gb
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


de : Texts
de =
    { basics = Messages.Basics.de
    , calEventInput = Messages.Comp.CalEventInput.de
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
