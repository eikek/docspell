module Comp.ImapSettingsTable exposing
    ( Model
    , Msg
    , emptyModel
    , init
    , update
    , view2
    )

import Api.Model.ImapSettings exposing (ImapSettings)
import Comp.Basic as B
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.ImapSettingsTableComp exposing (Texts)
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



--- View2


view2 : Texts -> Model -> Html Msg
view2 texts model =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [] []
                , th [ class "text-left mr-2" ] [ text texts.name ]
                , th [ class "text-left mr-2" ] [ text texts.hostPort ]
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
