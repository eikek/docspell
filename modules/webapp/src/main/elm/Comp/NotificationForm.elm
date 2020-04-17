module Comp.NotificationForm exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Api.Model.NotificationSettings exposing (NotificationSettings)
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)


type alias Model =
    { settings : NotificationSettings
    }


type Msg
    = Submit


init : Model
init =
    { settings = Api.Model.NotificationSettings.empty
    }


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div
        [ classList
            [ ( "ui form", True )
            ]
        ]
        []
