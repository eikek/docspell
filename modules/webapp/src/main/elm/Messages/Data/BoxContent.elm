{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Data.BoxContent exposing (Texts, de, gb, fr)

import Data.BoxContent exposing (BoxContent(..))


type alias Texts =
    { forContent : BoxContent -> String
    , queryBox : String
    , statsBox : String
    , messageBox : String
    , uploadBox : String
    }


gb : Texts
gb =
    updateForContent
        { forContent = \_ -> ""
        , queryBox = "Query box"
        , statsBox = "Statistics box"
        , messageBox = "Message box"
        , uploadBox = "Upload box"
        }


de : Texts
de =
    updateForContent
        { forContent = \_ -> ""
        , queryBox = "Suchabfrage Kachel"
        , statsBox = "Statistik Kachel"
        , messageBox = "Mitteilung Kachel"
        , uploadBox = "Datei hochladen Kachel"
        }


updateForContent : Texts -> Texts
updateForContent init =
    { init
        | forContent =
            \cnt ->
                case cnt of
                    BoxMessage _ ->
                        init.messageBox

                    BoxUpload _ ->
                        init.uploadBox

                    BoxQuery _ ->
                        init.queryBox

                    BoxStats _ ->
                        init.statsBox
    }

fr : Texts
fr =
    updateForContent
        { forContent = \_ -> ""
        , queryBox = "Boite de recherche"
        , statsBox = "Boite de statistique"
        , messageBox = "Boite de message"
        , uploadBox = "Boite d'envoi"
        }
