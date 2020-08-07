module Comp.FolderSelect exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Api.Model.FolderItem exposing (FolderItem)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Util.List


type alias Model =
    { all : List FolderItem
    , selected : Maybe String
    , expanded : Bool
    }


init : List FolderItem -> Model
init all =
    { all = List.sortBy .name all
    , selected = Nothing
    , expanded = False
    }



--- Update


type Msg
    = Toggle FolderItem
    | ToggleExpand


update : Msg -> Model -> ( Model, Maybe FolderItem )
update msg model =
    case msg of
        Toggle item ->
            let
                selection =
                    if model.selected == Just item.id then
                        Nothing

                    else
                        Just item.id

                model_ =
                    { model | selected = selection }
            in
            ( model_, selectedFolder model_ )

        ToggleExpand ->
            ( { model | expanded = not model.expanded }
            , selectedFolder model
            )


selectedFolder : Model -> Maybe FolderItem
selectedFolder model =
    let
        isSelected f =
            Just f.id == model.selected
    in
    Util.List.find isSelected model.all



--- View


view : Int -> Model -> Html Msg
view constr model =
    div [ class "ui list" ]
        [ div [ class "item" ]
            [ i [ class "folder open icon" ] []
            , div [ class "content" ]
                [ div [ class "header" ]
                    [ text "All"
                    ]
                , div [ class "ui relaxed list" ]
                    (renderItems constr model)
                ]
            ]
        ]


renderItems : Int -> Model -> List (Html Msg)
renderItems constr model =
    if constr <= 0 then
        List.map (viewItem model) model.all

    else if model.expanded then
        List.map (viewItem model) model.all ++ collapseToggle constr model

    else
        List.map (viewItem model) (List.take constr model.all) ++ expandToggle constr model


expandToggle : Int -> Model -> List (Html Msg)
expandToggle max model =
    if max > List.length model.all then
        []

    else
        [ a
            [ class "item"
            , onClick ToggleExpand
            , href "#"
            ]
            [ i [ class "angle down icon" ] []
            , div [ class "content" ]
                [ div [ class "description" ]
                    [ em [] [ text "Show More …" ]
                    ]
                ]
            ]
        ]


collapseToggle : Int -> Model -> List (Html Msg)
collapseToggle max model =
    if max > List.length model.all then
        []

    else
        [ a
            [ class "item"
            , onClick ToggleExpand
            , href "#"
            ]
            [ i [ class "angle up icon" ] []
            , div [ class "content" ]
                [ div [ class "description" ]
                    [ em [] [ text "Show Less …" ]
                    ]
                ]
            ]
        ]


viewItem : Model -> FolderItem -> Html Msg
viewItem model item =
    let
        selected =
            Just item.id == model.selected

        icon =
            if selected then
                "folder outline open icon"

            else
                "folder outline icon"
    in
    a
        [ classList
            [ ( "item", True )
            , ( "active", selected )
            ]
        , href "#"
        , onClick (Toggle item)
        ]
        [ i [ class icon ] []
        , div [ class "content" ]
            [ div [ class "header" ]
                [ text item.name
                ]
            ]
        ]
