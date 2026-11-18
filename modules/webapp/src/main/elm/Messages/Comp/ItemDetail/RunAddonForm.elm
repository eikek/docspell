{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ItemDetail.RunAddonForm exposing (Texts, de, fr, gb, pt)

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


pt : Texts
pt =
    { basics = Messages.Basics.pt
    , runAddon = "Executar um addon"
    , addonRunConfig = "Configuração de execução do addon"
    , runAddonTitle = "Executar o addon selecionado neste item."
    }
