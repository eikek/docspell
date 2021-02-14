module Comp.NotificationList exposing
    ( Action(..)
    , Model
    , Msg
    , init
    , update
    , view
    , view2
    )

import Api.Model.NotificationSettings exposing (NotificationSettings)
import Comp.Basic as B
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Styles as S
import Util.Html


type alias Model =
    {}


type Msg
    = EditSettings NotificationSettings


type Action
    = NoAction
    | EditAction NotificationSettings


init : Model
init =
    {}


update : Msg -> Model -> ( Model, Action )
update msg model =
    case msg of
        EditSettings settings ->
            ( model, EditAction settings )



--- View


view : Model -> List NotificationSettings -> Html Msg
view _ items =
    div []
        [ table [ class "ui very basic center aligned table" ]
            [ thead []
                [ tr []
                    [ th [ class "collapsing" ] []
                    , th [ class "collapsing" ]
                        [ i [ class "check icon" ] []
                        ]
                    , th [] [ text "Schedule" ]
                    , th [] [ text "Connection" ]
                    , th [] [ text "Recipients" ]
                    , th [] [ text "Remind Days" ]
                    ]
                ]
            , tbody []
                (List.map viewItem items)
            ]
        ]


viewItem : NotificationSettings -> Html Msg
viewItem item =
    tr []
        [ td [ class "collapsing" ]
            [ a
                [ href "#"
                , class "ui basic small blue label"
                , onClick (EditSettings item)
                ]
                [ i [ class "edit icon" ] []
                , text "Edit"
                ]
            ]
        , td [ class "collapsing" ]
            [ Util.Html.checkbox item.enabled
            ]
        , td []
            [ code []
                [ text item.schedule
                ]
            ]
        , td []
            [ text item.smtpConnection
            ]
        , td []
            [ String.join ", " item.recipients |> text
            ]
        , td []
            [ String.fromInt item.remindDays
                |> text
            ]
        ]



--- View2


view2 : Model -> List NotificationSettings -> Html Msg
view2 _ items =
    div []
        [ table [ class S.tableMain ]
            [ thead []
                [ tr []
                    [ th [ class "" ] []
                    , th [ class "text-center mr-2" ]
                        [ i [ class "fa fa-check" ] []
                        ]
                    , th [ class "text-left hidden sm:table-cell mr-2" ]
                        [ text "Schedule" ]
                    , th [ class "text-left mr-2" ]
                        [ text "Connection" ]
                    , th [ class "text-left hidden sm:table-cell mr-2" ]
                        [ text "Recipients" ]
                    , th [ class "text-center " ] [ text "Remind Days" ]
                    ]
                ]
            , tbody []
                (List.map viewItem2 items)
            ]
        ]


viewItem2 : NotificationSettings -> Html Msg
viewItem2 item =
    tr []
        [ B.editLinkTableCell (EditSettings item)
        , td [ class "w-px whitespace-nowrap px-2 text-center" ]
            [ Util.Html.checkbox2 item.enabled
            ]
        , td [ class "text-left hidden sm:table-cell mr-2" ]
            [ code [ class "font-mono text-sm" ]
                [ text item.schedule
                ]
            ]
        , td [ class "text-left mr-2" ]
            [ text item.smtpConnection
            ]
        , td [ class "text-left hidden sm:table-cell mr-2" ]
            [ String.join ", " item.recipients |> text
            ]
        , td [ class "text-center" ]
            [ String.fromInt item.remindDays
                |> text
            ]
        ]
