module Data.Box exposing (Box, boxIcon, empty, messageBox, queryBox, statsBox, uploadBox)

import Data.BoxContent exposing (BoxContent(..))


type alias Box =
    { name : String
    , visible : Bool
    , decoration : Bool
    , colspan : Int
    , content : BoxContent
    }


empty : BoxContent -> Box
empty cnt =
    { name = ""
    , visible = True
    , decoration = True
    , colspan = 1
    , content = cnt
    }


boxIcon : Box -> String
boxIcon box =
    Data.BoxContent.boxContentIcon box.content


queryBox : Box
queryBox =
    empty (BoxQuery Data.BoxContent.emptyQueryData)


statsBox : Box
statsBox =
    empty (BoxStats Data.BoxContent.emptyStatsData)


messageBox : Box
messageBox =
    empty (BoxMessage Data.BoxContent.emptyMessageData)


uploadBox : Box
uploadBox =
    empty (BoxUpload Data.BoxContent.emptyUploadData)
