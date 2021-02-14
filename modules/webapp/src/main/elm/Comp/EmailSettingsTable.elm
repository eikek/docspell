module Comp.EmailSettingsTable exposing
    ( Model
    , Msg
    , emptyModel
    , init
    , update
    , view
    , view2
    )

import Api.Model.EmailSettings exposing (EmailSettings)
import Comp.Basic as B
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Styles as S


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



--- View


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



--- View2


view2 : Model -> Html Msg
view2 model =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "" ] []
                , th [ class "text-left mr-2" ] [ text "Name" ]
                , th [ class "text-left mr-2" ] [ text "Host/Port" ]
                , th [ class "text-left mr-2 hidden sm:table-cell" ] [ text "From" ]
                ]
            ]
        , tbody []
            (List.map (renderLine2 model) model.emailSettings)
        ]


renderLine2 : Model -> EmailSettings -> Html Msg
renderLine2 _ ems =
    let
        hostport =
            case ems.smtpPort of
                Just p ->
                    ems.smtpHost ++ ":" ++ String.fromInt p

                Nothing ->
                    ems.smtpHost
    in
    tr
        [ class S.tableRow ]
        [ B.editLinkTableCell (Select ems)
        , td [ class "text-left mr-2" ]
            [ text ems.name
            ]
        , td [ class "text-left mr-2" ] [ text hostport ]
        , td [ class "text-left" ] [ text ems.from ]
        ]
