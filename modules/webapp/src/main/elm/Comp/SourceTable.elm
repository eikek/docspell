module Comp.SourceTable exposing
    ( Msg
    , SelectMode(..)
    , isEdit
    , update
    , view2
    )

import Api.Model.SourceAndTags exposing (SourceAndTags)
import Comp.Basic as B
import Data.Flags exposing (Flags)
import Data.Priority
import Html exposing (..)
import Html.Attributes exposing (..)
import Styles as S
import Util.Html


type SelectMode
    = Edit SourceAndTags
    | Display SourceAndTags
    | None


isEdit : SelectMode -> Bool
isEdit m =
    case m of
        Edit _ ->
            True

        Display _ ->
            False

        None ->
            False


type Msg
    = Select SourceAndTags
    | Show SourceAndTags


update : Flags -> Msg -> ( Cmd Msg, SelectMode )
update _ msg =
    case msg of
        Select source ->
            ( Cmd.none, Edit source )

        Show source ->
            ( Cmd.none, Display source )



--- View2


view2 : List SourceAndTags -> Html Msg
view2 sources =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "" ] []
                , th [ class "text-left" ] [ text "Abbrev" ]
                , th [ class "px-2 text-center" ] [ text "Enabled" ]
                , th [ class "hidden md:table-cell" ] [ text "Counter" ]
                , th [ class "hidden md:table-cell" ] [ text "Priority" ]
                , th [ class "hidden sm:table-cell" ] [ text "Id" ]
                ]
            ]
        , tbody []
            (List.map renderSourceLine2 sources)
        ]


renderSourceLine2 : SourceAndTags -> Html Msg
renderSourceLine2 source =
    tr
        [ class S.tableRow ]
        [ td [ class S.editLinkTableCellStyle ]
            [ div
                [ class "inline-flex space-x-2"
                ]
                [ B.editLinkLabel (Select source)
                , B.linkLabel
                    { label = "Show"
                    , icon = "fa fa-eye"
                    , handler = Show source
                    , disabled = not source.source.enabled
                    }
                ]
            ]
        , td [ class "text-left" ]
            [ text source.source.abbrev
            ]
        , td [ class "w-px px-2 text-center" ]
            [ Util.Html.checkbox2 source.source.enabled
            ]
        , td [ class "text-center hidden md:table-cell" ]
            [ source.source.counter |> String.fromInt |> text
            ]
        , td [ class "text-center hidden md:table-cell" ]
            [ Data.Priority.fromString source.source.priority
                |> Maybe.map Data.Priority.toName
                |> Maybe.withDefault source.source.priority
                |> text
            ]
        , td [ class "text-center hidden sm:table-cell" ]
            [ text source.source.id
            ]
        ]
