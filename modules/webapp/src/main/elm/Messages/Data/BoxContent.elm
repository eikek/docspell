module Messages.Data.BoxContent exposing (Texts, de, gb)

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
