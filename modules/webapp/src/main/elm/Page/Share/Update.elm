{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Share.Update exposing (UpdateResult, update)

import Data.Flags exposing (Flags)
import Page.Share.Data exposing (..)


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    }


update : Flags -> String -> Msg -> Model -> UpdateResult
update flags shareId msg model =
    UpdateResult model Cmd.none Sub.none
