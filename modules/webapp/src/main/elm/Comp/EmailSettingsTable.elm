module Comp.EmailSettingsTable exposing
    ( Model
    , Msg
    , emptyModel
    , update
    , view
    )

import Api.Model.EmailSettings exposing (EmailSettings)
import Html exposing (..)
import Html.Attributes exposing (..)


type alias Model =
    { emailSettings : List EmailSettings
    }


emptyModel : Model
emptyModel =
    init []


init : List EmailSettings -> Model
init ems =
    { emailSettings = ems
    }


type Msg
    = Select EmailSettings


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    table [ class "ui table" ]
        [ thead []
            [ th [] [ text "Name" ]
            , th [] [ text "Host/Port" ]
            , th [] [ text "From" ]
            ]
        , tbody []
            []
        ]
