module Comp.CustomFieldTable exposing
    ( Action(..)
    , Model
    , Msg
    , init
    , update
    , view2
    )

import Api.Model.CustomField exposing (CustomField)
import Comp.Basic as B
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Comp.CustomFieldTable exposing (Texts)
import Styles as S


type alias Model =
    {}


type Msg
    = EditItem CustomField


type Action
    = NoAction
    | EditAction CustomField


init : Model
init =
    {}


update : Msg -> Model -> ( Model, Action )
update msg model =
    case msg of
        EditItem item ->
            ( model, EditAction item )



--- View2


view2 : Texts -> Model -> List CustomField -> Html Msg
view2 texts _ items =
    div []
        [ table [ class S.tableMain ]
            [ thead []
                [ tr []
                    [ th [] []
                    , th [ class "text-left" ] [ text texts.nameLabel ]
                    , th [ class "text-left" ] [ text texts.format ]
                    , th [ class "text-center hidden sm:table-cell" ] [ text texts.usageCount ]
                    , th [ class "text-center hidden sm:table-cell" ] [ text texts.basics.created ]
                    ]
                ]
            , tbody []
                (List.map (viewItem2 texts) items)
            ]
        ]


viewItem2 : Texts -> CustomField -> Html Msg
viewItem2 texts item =
    tr [ class S.tableRow ]
        [ B.editLinkTableCell (EditItem item)
        , td [ class "text-left py-4 md:py-2 pr-2" ]
            [ text <| Maybe.withDefault item.name item.label
            ]
        , td [ class "text-left py-4 md:py-2 pr-2" ]
            [ text item.ftype
            ]
        , td [ class "text-center py-4 md:py-2 sm:pr-2 hidden sm:table-cell" ]
            [ String.fromInt item.usages
                |> text
            ]
        , td [ class "text-center py-4 md:py-2 hidden sm:table-cell" ]
            [ texts.formatDateShort item.created
                |> text
            ]
        ]
