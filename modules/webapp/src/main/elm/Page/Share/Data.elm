{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Share.Data exposing (Model, Msg, init)

import Data.Flags exposing (Flags)


type alias Model =
    {}


init : Maybe String -> Flags -> ( Model, Cmd Msg )
init shareId flags =
    case shareId of
        Just id ->
            let
                _ =
                    Debug.log "share" id
            in
            ( {}, Cmd.none )

        Nothing ->
            ( {}, Cmd.none )


type Msg
    = Msg
