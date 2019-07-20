module Page.Home.Update exposing (update)

import Api
import Data.Flags exposing (Flags)
import Page.Home.Data exposing (..)

update: Flags -> Msg -> Model -> (Model, Cmd Msg)
update flags msg model =
    (model, Cmd.none)
