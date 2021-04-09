module Comp.EmailSettingsTable exposing
    ( Model
    , Msg
    , emptyModel
    , init
    , update
    , view2
    )

import Api.Model.EmailSettings exposing (EmailSettings)
import Comp.Basic as B
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Comp.EmailSettingsTable exposing (Texts)
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



--- View2


view2 : Texts -> Model -> Html Msg
view2 texts model =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "" ] []
                , th [ class "text-left mr-2" ] [ text texts.name ]
                , th [ class "text-left mr-2" ] [ text texts.hostPort ]
                , th [ class "text-left mr-2 hidden sm:table-cell" ] [ text texts.from ]
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
