module Comp.SourceTable exposing
    ( Msg
    , SelectMode(..)
    , isEdit
    , update
    , view
    )

import Api.Model.SourceAndTags exposing (SourceAndTags)
import Data.Flags exposing (Flags)
import Data.Priority
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)


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
