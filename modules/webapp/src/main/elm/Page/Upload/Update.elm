{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Upload.Update exposing (update)

import Comp.UploadForm
import Data.Flags exposing (Flags)
import Page.Upload.Data exposing (..)


update : Maybe String -> Flags -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update sourceId flags msg model =
    case msg of
        UploadMsg lm ->
            let
                ( um, uc, us ) =
                    Comp.UploadForm.update sourceId flags lm model.uploadForm
            in
            ( { model | uploadForm = um }, Cmd.map UploadMsg uc, Sub.map UploadMsg us )
