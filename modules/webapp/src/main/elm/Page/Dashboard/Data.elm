{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Dashboard.Data exposing
    ( Model
    , Msg(..)
    , init
    )

import Data.Flags exposing (Flags)


type alias Model =
    {}


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( {}, Cmd.none )


type Msg
    = Init
