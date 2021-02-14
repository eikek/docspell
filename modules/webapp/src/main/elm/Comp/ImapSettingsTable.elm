module Comp.ImapSettingsTable exposing
    ( Model
    , Msg
    , emptyModel
    , init
    , update
    , view
    , view2
    )

import Api.Model.ImapSettings exposing (ImapSettings)
import Comp.Basic as B
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Styles as S


type alias Model =
    { emailSettings : List ImapSettings
    , selected : Maybe ImapSettings
    }


emptyModel : Model
emptyModel =
    init []


init : List ImapSettings -> Model
init ems =
    { emailSettings = ems
    , selected = Nothing
    }


type Msg
    = Select ImapSettings


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
                ]
            ]
        , tbody []
            (List.map (renderLine model) model.emailSettings)
        ]


renderLine : Model -> ImapSettings -> Html Msg
renderLine model ems =
    let
        hostport =
            case ems.imapPort of
                Just p ->
                    ems.imapHost ++ ":" ++ String.fromInt p

                Nothing ->
                    ems.imapHost
    in
    tr
        [ classList [ ( "active", model.selected == Just ems ) ]
        , onClick (Select ems)
        ]
        [ td [ class "collapsible" ] [ text ems.name ]
        , td [] [ text hostport ]
        ]



--- View2


view2 : Model -> Html Msg
view2 model =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [] []
                , th [ class "text-left mr-2" ] [ text "Name" ]
                , th [ class "text-left mr-2" ] [ text "Host/Port" ]
                ]
            ]
        , tbody []
            (List.map (renderLine2 model) model.emailSettings)
        ]


renderLine2 : Model -> ImapSettings -> Html Msg
renderLine2 _ ems =
    let
        hostport =
            case ems.imapPort of
                Just p ->
                    ems.imapHost ++ ":" ++ String.fromInt p

                Nothing ->
                    ems.imapHost
    in
    tr
        [ class S.tableRow ]
        [ B.editLinkTableCell (Select ems)
        , td [ class "text-left mr-2" ] [ text ems.name ]
        , td [ class "text-left" ] [ text hostport ]
        ]
