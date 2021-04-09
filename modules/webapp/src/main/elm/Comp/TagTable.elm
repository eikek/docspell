module Comp.TagTable exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view2
    )

import Api.Model.Tag exposing (Tag)
import Comp.Basic as B
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Comp.TagTable exposing (Texts)
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



--- View2


view2 : Texts -> Model -> Html Msg
view2 texts model =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "" ] []
                , th [ class "text-left" ] [ text texts.name ]
                , th [ class "text-left" ] [ text texts.category ]
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
