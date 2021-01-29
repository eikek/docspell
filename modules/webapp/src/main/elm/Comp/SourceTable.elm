module Comp.SourceTable exposing
    ( Msg
    , SelectMode(..)
    , isEdit
    , update
    , view
    , view2
    )

import Api.Model.SourceAndTags exposing (SourceAndTags)
import Comp.Basic as B
import Data.Flags exposing (Flags)
import Data.Priority
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
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



--- View


view : List SourceAndTags -> Html Msg
view sources =
    table [ class "ui table" ]
        [ thead []
            [ tr []
                [ th [ class "collapsing" ] []
                , th [ class "collapsing" ] [ text "Abbrev" ]
                , th [ class "collapsing" ] [ text "Enabled" ]
                , th [ class "collapsing" ] [ text "Counter" ]
                , th [ class "collapsing" ] [ text "Priority" ]
                , th [] [ text "Id" ]
                ]
            ]
        , tbody []
            (List.map renderSourceLine sources)
        ]


renderSourceLine : SourceAndTags -> Html Msg
renderSourceLine source =
    tr
        []
        [ td [ class "collapsing" ]
            [ a
                [ class "ui basic tiny primary button"
                , href "#"
                , onClick (Select source)
                ]
                [ i [ class "edit icon" ] []
                , text "Edit"
                ]
            , a
                [ classList
                    [ ( "ui basic tiny primary button", True )
                    , ( "disabled", not source.source.enabled )
                    ]
                , href "#"
                , disabled (not source.source.enabled)
                , onClick (Show source)
                ]
                [ i [ class "eye icon" ] []
                , text "Show"
                ]
            ]
        , td [ class "collapsing" ]
            [ text source.source.abbrev
            ]
        , td [ class "collapsing" ]
            [ if source.source.enabled then
                i [ class "check square outline icon" ] []

              else
                i [ class "minus square outline icon" ] []
            ]
        , td [ class "collapsing" ]
            [ source.source.counter |> String.fromInt |> text
            ]
        , td [ class "collapsing" ]
            [ Data.Priority.fromString source.source.priority
                |> Maybe.map Data.Priority.toName
                |> Maybe.withDefault source.source.priority
                |> text
            ]
        , td []
            [ text source.source.id
            ]
        ]



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
