module Comp.BoxView exposing (..)

import Data.Box exposing (Box)
import Data.Flags exposing (Flags)
import Html exposing (Html, div)


type alias Model =
    {}


type Msg
    = Dummy


init : Flags -> Box -> ( Model, Cmd Msg )
init flags box =
    ( {}, Cmd.none )



--- Update
--- View


view : Model -> Html Msg
view model =
    div [] []
