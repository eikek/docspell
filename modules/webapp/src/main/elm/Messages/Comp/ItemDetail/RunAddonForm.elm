{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ItemDetail.RunAddonForm exposing (Texts, de, fr
    , ja, gb)

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , runAddon : String
    , addonRunConfig : String
    , runAddonTitle : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , runAddon = "Run an addon"
    , addonRunConfig = "Addon run configuration"
    , runAddonTitle = "Run the selected addon on this item."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , runAddon = "Addon ausführen"
    , addonRunConfig = "Addon Konfiguration"
    , runAddonTitle = "Run the selected addon on this item."
    }



-- TODO: translate-fr


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , runAddon = "Run an addon"
    , addonRunConfig = "Addon run configuration"
    , runAddonTitle = "Run the selected addon on this item."
    }


ja : Texts
ja =
    { basics = Messages.Basics.ja
    , runAddon = "アドオンを実行"
    , addonRunConfig = "アドオン実行設定"
    , runAddonTitle = "このアイテムに選択したアドオンを実行します。"
    }
