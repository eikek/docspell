module Comp.ScanMailboxList exposing
    ( Action(..)
    , Model
    , Msg
    , init
    , update
    , view2
    )

import Api.Model.ScanMailboxSettings exposing (ScanMailboxSettings)
import Comp.Basic as B
import Html exposing (..)
import Html.Attributes exposing (..)
import Styles as S
import Util.Html


type alias Model =
    {}


type Msg
    = EditSettings ScanMailboxSettings


type Action
    = NoAction
    | EditAction ScanMailboxSettings


init : Model
init =
    {}


update : Msg -> Model -> ( Model, Action )
update msg model =
    case msg of
        EditSettings settings ->
            ( model, EditAction settings )



--- View2


view2 : Model -> List ScanMailboxSettings -> Html Msg
view2 _ items =
    div []
        [ table [ class S.tableMain ]
            [ thead []
                [ tr []
                    [ th [ class "" ] []
                    , th [ class "" ]
                        [ i [ class "fa fa-check" ] []
                        ]
                    , th [ class "text-left" ] [ text "Summary" ]
                    , th [ class "text-left mr-2" ] [ text "Schedule" ]
                    , th [ class "text-left mr-2 hidden md:table-cell" ] [ text "Connection" ]
                    , th [ class "text-left mr-2 hidden md:table-cell" ] [ text "Folders" ]
                    , th [ class "text-left mr-2 hidden lg:table-cell" ] [ text "Received Since" ]
                    ]
                ]
            , tbody []
                (List.map viewItem2 items)
            ]
        ]


viewItem2 : ScanMailboxSettings -> Html Msg
viewItem2 item =
    tr [ class S.tableRow ]
        [ B.editLinkTableCell (EditSettings item)
        , td [ class "w-px px-2" ]
            [ Util.Html.checkbox2 item.enabled
            ]
        , td [ class "text-left" ]
            [ Maybe.withDefault "–" item.summary |> text
            ]
        , td [ class "mr-2" ]
            [ code [ class "font-mono text-sm" ]
                [ text item.schedule
                ]
            ]
        , td [ class "text-left mr-2 hidden md:table-cell" ]
            [ text item.imapConnection
            ]
        , td [ class "text-left mr-2 hidden md:table-cell" ]
            [ String.join ", " item.folders |> text
            ]
        , td [ class "text-left mr-2 hidden lg:table-cell" ]
            [ Maybe.map String.fromInt item.receivedSinceHours
                |> Maybe.withDefault "-"
                |> text
            , text " h"
            ]
        ]
