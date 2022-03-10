{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Data.ChannelType exposing (Texts, de, fr, gb)

import Data.ChannelType exposing (ChannelType)


type alias Texts =
    ChannelType -> String


gb : Texts
gb ct =
    case ct of
        Data.ChannelType.Matrix ->
            "Matrix"

        Data.ChannelType.Gotify ->
            "Gotify"

        Data.ChannelType.Mail ->
            "E-Mail"

        Data.ChannelType.Http ->
            "JSON"


de : Texts
de ct =
    case ct of
        Data.ChannelType.Matrix ->
            "Matrix"

        Data.ChannelType.Gotify ->
            "Gotify"

        Data.ChannelType.Mail ->
            "E-Mail"

        Data.ChannelType.Http ->
            "JSON"


fr : Texts
fr ct =
    case ct of
        Data.ChannelType.Matrix ->
            "Matrix"

        Data.ChannelType.Gotify ->
            "Gotify"

        Data.ChannelType.Mail ->
            "E-Mail"

        Data.ChannelType.Http ->
            "JSON"
