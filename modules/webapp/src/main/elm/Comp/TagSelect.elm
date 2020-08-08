module Comp.TagSelect exposing
    ( Model
    , Msg
    , Selection
    , emptySelection
    , init
    , update
    , view
    )

import Api.Model.TagCount exposing (TagCount)
import Data.Icons as I
import Data.UiSettings exposing (UiSettings)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)


type alias Model =
    { all : List TagCount
    , selected : Dict String Bool
    , expanded : Bool
    }


init : List TagCount -> Model
init tags =
    { all = tags
    , selected = Dict.empty
    , expanded = False
    }



--- Update


type Msg
    = Toggle String
    | ToggleExpand


type alias Selection =
    { include : List TagCount
    , exclude : List TagCount
    }


emptySelection : Selection
emptySelection =
    Selection [] []


update : Msg -> Model -> ( Model, Selection )
update msg model =
    case msg of
        Toggle id ->
            let
                current =
                    Dict.get id model.selected

                next =
                    case current of
                        Nothing ->
                            Dict.insert id True model.selected

                        Just True ->
                            Dict.insert id False model.selected

                        Just False ->
                            Dict.remove id model.selected

                model_ =
                    { model | selected = next }
            in
            ( model_, getSelection model_ )

        ToggleExpand ->
            ( { model | expanded = not model.expanded }
            , getSelection model
            )


getSelection : Model -> Selection
getSelection model =
    let
        selectedOnly t =
            Dict.member t.tag.id model.selected

        isIncluded t =
            Dict.get t.tag.id model.selected
                |> Maybe.withDefault False

        ( incl, excl ) =
            List.filter selectedOnly model.all
                |> List.partition isIncluded
    in
    Selection incl excl



--- View


type SelState
    = Include
    | Exclude
    | Deselect


selState : Model -> String -> SelState
selState model id =
    case Dict.get id model.selected of
        Just True ->
            Include

        Just False ->
            Exclude

        Nothing ->
            Deselect


view : UiSettings -> Model -> Html Msg
view settings model =
    div [ class "ui list" ]
        [ div [ class "item" ]
            [ I.tagIcon ""
            , div [ class "content" ]
                [ div [ class "header" ]
                    [ text "Tags"
                    ]
                , div [ class "ui relaxed list" ]
                    (List.map (viewItem settings model) model.all)
                ]
            ]
        ]


viewItem : UiSettings -> Model -> TagCount -> Html Msg
viewItem settings model tag =
    let
        state =
            selState model tag.tag.id

        color =
            Data.UiSettings.tagColorString tag.tag settings

        icon =
            case state of
                Include ->
                    i [ class ("check icon " ++ color) ] []

                Exclude ->
                    i [ class ("minus icon " ++ color) ] []

                Deselect ->
                    I.tagIcon color
    in
    a
        [ class "item"
        , href "#"
        , onClick (Toggle tag.tag.id)
        ]
        [ icon
        , div [ class "content" ]
            [ div
                [ classList
                    [ ( "header", state == Include )
                    , ( "description", state /= Include )
                    ]
                ]
                [ text tag.tag.name
                , div [ class "ui right floated circular label" ]
                    [ text (String.fromInt tag.count)
                    ]
                ]
            ]
        ]
