{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.Box exposing (Box, boxIcon, decoder, empty, encode, messageBox, queryBox, statsBox, uploadBox)

import Data.BoxContent exposing (BoxContent(..))
import Json.Decode as D
import Json.Encode as E


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



--- JSON


decoder : D.Decoder Box
decoder =
    D.map5 Box
        (D.field "name" D.string)
        (D.field "visible" D.bool)
        (D.field "decoration" D.bool)
        (D.field "colspan" D.int)
        (D.field "content" Data.BoxContent.boxContentDecoder)


encode : Box -> E.Value
encode box =
    E.object
        [ ( "name", E.string box.name )
        , ( "visible", E.bool box.visible )
        , ( "decoration", E.bool box.decoration )
        , ( "colspan", E.int box.colspan )
        , ( "content", Data.BoxContent.boxContentEncode box.content )
        ]
