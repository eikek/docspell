module Comp.EmailSettingsTable exposing
    ( Model
    , Msg
    , emptyModel
    , init
    , update
    , view
    )

import Api.Model.EmailSettings exposing (EmailSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)


type alias Model =
    { emailSettings : List EmailSettings
    , selected : Maybe EmailSettings
    }


emptyModel : Model
emptyModel =
    init []


init : List EmailSettings -> Model
init ems =
    { emailSettings = ems
    , selected = Nothing
    }


type Msg
    = Select EmailSettings


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Select ems ->
            ( { model | selected = Just ems }, Cmd.none )


view : Model -> Html Msg
view model =
    table [ class "ui selectable pointer table" ]
        [ thead []
            [ tr []
                [ th [ class "collapsible" ] [ text "Name" ]
                , th [] [ text "Host/Port" ]
                , th [] [ text "From" ]
                ]
            ]
        , tbody []
            (List.map (renderLine model) model.emailSettings)
        ]


renderLine : Model -> EmailSettings -> Html Msg
renderLine model ems =
    let
        hostport =
            case ems.smtpPort of
                Just p ->
                    ems.smtpHost ++ ":" ++ String.fromInt p

                Nothing ->
                    ems.smtpHost
    in
    tr
        [ classList [ ( "active", model.selected == Just ems ) ]
        , onClick (Select ems)
        ]
        [ td [ class "collapsible" ] [ text ems.name ]
        , td [] [ text hostport ]
        , td [] [ text ems.from ]
        ]
