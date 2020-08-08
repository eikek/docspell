module Comp.FolderSelect exposing
    ( Model
    , Msg
    , init
    , update
    , updateDrop
    , view
    , viewDrop
    )

import Api.Model.FolderItem exposing (FolderItem)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html5.DragDrop as DD
import Util.ExpandCollapse
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
    | FolderDDMsg (DD.Msg String String)


update : Msg -> Model -> ( Model, Maybe FolderItem )
update msg model =
    let
        ( m, f, _ ) =
            updateDrop DD.init msg model
    in
    ( m, f )


updateDrop :
    DD.Model String String
    -> Msg
    -> Model
    -> ( Model, Maybe FolderItem, DD.Model String String )
updateDrop dropModel msg model =
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
            ( model_, selectedFolder model_, dropModel )

        ToggleExpand ->
            ( { model | expanded = not model.expanded }
            , selectedFolder model
            , dropModel
            )

        FolderDDMsg lm ->
            let
                ( dm_, result ) =
                    DD.update lm dropModel

                _ =
                    case result of
                        Just ( item, folder, _ ) ->
                            let
                                _ =
                                    Debug.log "item menu" item

                                _ =
                                    Debug.log "folder menu" folder
                            in
                            Cmd.none

                        Nothing ->
                            Cmd.none
            in
            ( model, selectedFolder model, dm_ )


selectedFolder : Model -> Maybe FolderItem
selectedFolder model =
    let
        isSelected f =
            Just f.id == model.selected
    in
    Util.List.find isSelected model.all



--- View


view : Int -> Model -> Html Msg
view =
    viewDrop DD.init


viewDrop : DD.Model String String -> Int -> Model -> Html Msg
viewDrop dropModel constr model =
    div [ class "ui list" ]
        [ div [ class "item" ]
            [ i [ class "folder open icon" ] []
            , div [ class "content" ]
                [ div [ class "header" ]
                    [ text "Folders"
                    ]
                , div [ class "ui relaxed list" ]
                    (renderItems dropModel constr model)
                ]
            ]
        ]


renderItems : DD.Model String String -> Int -> Model -> List (Html Msg)
renderItems dropModel constr model =
    if constr <= 0 then
        List.map (viewItem dropModel model) model.all

    else if model.expanded then
        List.map (viewItem dropModel model) model.all ++ collapseToggle constr model

    else
        List.map (viewItem dropModel model) (List.take constr model.all) ++ expandToggle constr model


expandToggle : Int -> Model -> List (Html Msg)
expandToggle max model =
    Util.ExpandCollapse.expandToggle
        max
        (List.length model.all)
        ToggleExpand


collapseToggle : Int -> Model -> List (Html Msg)
collapseToggle max model =
    Util.ExpandCollapse.collapseToggle
        max
        (List.length model.all)
        ToggleExpand


viewItem : DD.Model String String -> Model -> FolderItem -> Html Msg
viewItem dropModel model item =
    let
        selected =
            Just item.id == model.selected

        icon =
            if selected then
                "folder outline open icon"

            else
                "folder outline icon"

        highlightDrop =
            DD.getDropId dropModel == Just item.id
    in
    a
        ([ classList
            [ ( "item", True )
            , ( "active", selected )
            , ( "current-drop-target", highlightDrop )
            ]
         , href "#"
         , onClick (Toggle item)
         ]
            ++ DD.droppable FolderDDMsg item.id
        )
        [ i [ class icon ] []
        , div [ class "content" ]
            [ div [ class "header" ]
                [ text item.name
                ]
            ]
        ]
