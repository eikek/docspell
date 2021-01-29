module Comp.FolderTable exposing
    ( Action(..)
    , Model
    , Msg
    , init
    , update
    , view
    , view2
    )

import Api.Model.FolderItem exposing (FolderItem)
import Comp.Basic as B
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Styles as S
import Util.Html
import Util.Time


type alias Model =
    {}


type Msg
    = EditItem FolderItem


type Action
    = NoAction
    | EditAction FolderItem


init : Model
init =
    {}


update : Msg -> Model -> ( Model, Action )
update msg model =
    case msg of
        EditItem item ->
            ( model, EditAction item )



--- View


view : Model -> List FolderItem -> Html Msg
view _ items =
    div []
        [ table [ class "ui very basic aligned table" ]
            [ thead []
                [ tr []
                    [ th [ class "collapsing" ] []
                    , th [] [ text "Name" ]
                    , th [] [ text "Owner" ]
                    , th [ class "collapsing" ] [ text "Owner or Member" ]
                    , th [ class "collapsing" ] [ text "#Member" ]
                    , th [ class "collapsing" ] [ text "Created" ]
                    ]
                ]
            , tbody []
                (List.map viewItem items)
            ]
        ]


viewItem : FolderItem -> Html Msg
viewItem item =
    tr []
        [ td [ class "collapsing" ]
            [ a
                [ href "#"
                , class "ui basic small blue label"
                , onClick (EditItem item)
                ]
                [ i [ class "edit icon" ] []
                , text "Edit"
                ]
            ]
        , td []
            [ text item.name
            ]
        , td []
            [ text item.owner.name
            ]
        , td [ class "center aligned" ]
            [ Util.Html.checkbox item.isMember
            ]
        , td [ class "center aligned" ]
            [ String.fromInt item.memberCount
                |> text
            ]
        , td [ class "center aligned" ]
            [ Util.Time.formatDateShort item.created
                |> text
            ]
        ]



--- View2


view2 : Model -> List FolderItem -> Html Msg
view2 _ items =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "w-px whitespace-nowrap pr-1 md:pr-3" ] []
                , th [ class "text-left" ] [ text "Name" ]
                , th [ class "text-left hidden sm:table-cell" ] [ text "Owner" ]
                , th [ class "text-center" ]
                    [ span [ class "hidden sm:inline" ]
                        [ text "#Member"
                        ]
                    , span [ class "sm:hidden" ]
                        [ text "#"
                        ]
                    ]
                , th [ class "text-center" ] [ text "Created" ]
                ]
            ]
        , tbody []
            (List.map viewItem2 items)
        ]


viewItem2 : FolderItem -> Html Msg
viewItem2 item =
    tr
        [ class S.tableRow
        ]
        [ B.editLinkTableCell (EditItem item)
        , td [ class " py-4 md:py-2" ]
            [ text item.name
            , span
                [ classList [ ( "hidden", item.isMember ) ]
                ]
                [ span [ class "ml-1 text-red-700" ]
                    [ text "*"
                    ]
                ]
            ]
        , td [ class " py-4 md:py-2 hidden sm:table-cell" ]
            [ text item.owner.name
            ]
        , td [ class "text-center  py-4 md:py-2" ]
            [ String.fromInt item.memberCount
                |> text
            ]
        , td [ class "text-center  py-4 md:py-2" ]
            [ Util.Time.formatDateShort item.created
                |> text
            ]
        ]
