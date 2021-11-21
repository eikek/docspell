{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.ChannelRef exposing (..)

import Data.ChannelType exposing (ChannelType)
import Json.Decode as D
import Json.Encode as E


type alias ChannelRef =
    { id : String
    , channelType : ChannelType
    }


decoder : D.Decoder ChannelRef
decoder =
    D.map2 ChannelRef
        (D.field "id" D.string)
        (D.field "channelType" Data.ChannelType.decoder)


encode : ChannelRef -> E.Value
encode cref =
    E.object
        [ ( "id", E.string cref.id )
        , ( "channelType", Data.ChannelType.encode cref.channelType )
        ]
