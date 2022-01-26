{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Dashboard.Update exposing (update)

import Data.Flags exposing (Flags)
import Page.Dashboard.Data exposing (..)


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        Init ->
            ( model, Cmd.none )
