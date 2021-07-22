{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Util.Size exposing
    ( SizeUnit(..)
    , bytesReadable
    )


type SizeUnit
    = G
    | M
    | K
    | B


prettyNumber : Float -> String
prettyNumber n =
    let
        parts =
            String.split "." (String.fromFloat n)
    in
    case parts of
        n0 :: d :: [] ->
            n0 ++ "." ++ String.left 2 d

        _ ->
            String.join "." parts


bytesReadable : SizeUnit -> Float -> String
bytesReadable unit n =
    let
        k =
            n / 1024

        num =
            prettyNumber n
    in
    case unit of
        G ->
            num ++ "G"

        M ->
            if k > 1 then
                bytesReadable G k

            else
                num ++ "M"

        K ->
            if k > 1 then
                bytesReadable M k

            else
                num ++ "K"

        B ->
            if k > 1 then
                bytesReadable K k

            else
                num ++ "B"
