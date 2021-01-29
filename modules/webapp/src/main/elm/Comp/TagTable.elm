module Comp.TagTable exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view
    , view2
    )

import Api.Model.Tag exposing (Tag)
import Comp.Basic as B
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Styles as S


type alias Model =
    { tags : List Tag
    , selected : Maybe Tag
    }


emptyModel : Model
emptyModel =
    { tags = []
    , selected = Nothing
    }


type Msg
    = SetTags (List Tag)
    | Select Tag
    | Deselect


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        SetTags list ->
            ( { model | tags = list, selected = Nothing }, Cmd.none )

        Select tag ->
            ( { model | selected = Just tag }, Cmd.none )

        Deselect ->
            ( { model | selected = Nothing }, Cmd.none )


view : Model -> Html Msg
view model =
    table [ class "ui very basic aligned table" ]
        [ thead []
            [ tr []
                [ th [ class "collapsing" ] []
                , th [ class "eight wide" ] [ text "Name" ]
                , th [] [ text "Category" ]
                ]
            ]
        , tbody []
            (List.map (renderTagLine model) model.tags)
        ]


renderTagLine : Model -> Tag -> Html Msg
renderTagLine model tag =
    tr
        []
        [ td [ class "collapsing" ]
            [ a
                [ href "#"
                , class "ui basic small blue label"
                , onClick (Select tag)
                ]
                [ i [ class "edit icon" ] []
                , text "Edit"
                ]
            ]
        , td []
            [ text tag.name
            ]
        , td []
            [ Maybe.withDefault "-" tag.category |> text
            ]
        ]



--- View2


view2 : Model -> Html Msg
view2 model =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "" ] []
                , th [ class "text-left" ] [ text "Name" ]
                , th [ class "text-left" ] [ text "Category" ]
                ]
            ]
        , tbody []
            (List.map (renderTagLine2 model) model.tags)
        ]


renderTagLine2 : Model -> Tag -> Html Msg
renderTagLine2 model tag =
    tr
        [ classList [ ( "active", model.selected == Just tag ) ]
        , class S.tableRow
        ]
        [ B.editLinkTableCell (Select tag)
        , td [ class "text-left py-4 md:py-2" ]
            [ text tag.name
            ]
        , td [ class "text-left py-4 md:py-2" ]
            [ Maybe.withDefault "-" tag.category |> text
            ]
        ]
