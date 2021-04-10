module Messages.Comp.ClassifierSettingsForm exposing (..)

import Messages.Comp.CalEventInput


type alias Texts =
    { calEventInput : Messages.Comp.CalEventInput.Texts
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
    { calEventInput = Messages.Comp.CalEventInput.gb
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
