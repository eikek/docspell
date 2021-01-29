module Comp.FolderSelect exposing
    ( Model
    , Msg
    , deselect
    , init
    , modify
    , setSelected
    , update
    , updateDrop
    , view
    , viewDrop
    , viewDrop2
    )

import Api.Model.FolderStats exposing (FolderStats)
import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Util.ExpandCollapse
import Util.ItemDragDrop as DD
import Util.List


type alias Model =
    { all : List FolderStats
    , selected : Maybe String
    , expanded : Bool
    }


init : Maybe FolderStats -> List FolderStats -> Model
init selected all =
    { all = List.sortBy .name all
    , selected = Maybe.map .id selected
    , expanded = False
    }


modify : Maybe FolderStats -> Model -> List FolderStats -> Model
modify selected model all =
    if List.isEmpty model.all then
        init selected all

    else
        let
            folderDict =
                List.map (\f -> ( f.id, f )) all
                    |> Dict.fromList

            replaced el =
                Dict.get el.id folderDict |> Maybe.withDefault { el | count = 0 }
        in
        { model
            | all = List.map replaced model.all
            , selected = Maybe.map .id selected
        }


setSelected : String -> Model -> Maybe Msg
setSelected id model =
    List.filter (\fi -> fi.id == id) model.all
        |> List.head
        |> Maybe.map Toggle


deselect : Model -> Maybe Msg
deselect model =
    Maybe.andThen (\id -> setSelected id model) model.selected



--- Update


type Msg
    = Toggle FolderStats
    | ToggleExpand
    | FolderDDMsg DD.Msg


update : Msg -> Model -> ( Model, Maybe FolderStats )
update msg model =
    let
        ( m, f, _ ) =
            updateDrop DD.init msg model
    in
    ( m, f )


updateDrop :
    DD.Model
    -> Msg
    -> Model
    -> ( Model, Maybe FolderStats, DD.DragDropData )
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
            ( model_, selectedFolder model_, DD.DragDropData dropModel Nothing )

        ToggleExpand ->
            ( { model | expanded = not model.expanded }
            , selectedFolder model
            , DD.DragDropData dropModel Nothing
            )

        FolderDDMsg lm ->
            let
                ddd =
                    DD.update lm dropModel
            in
            ( model, selectedFolder model, ddd )


selectedFolder : Model -> Maybe FolderStats
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


viewDrop : DD.Model -> Int -> Model -> Html Msg
viewDrop dropModel constr model =
    let
        highlightDrop =
            DD.getDropId dropModel == Just DD.FolderRemove
    in
    div [ class "ui list" ]
        [ div [ class "item" ]
            [ i [ class "folder open icon" ] []
            , div [ class "content" ]
                [ div
                    (classList
                        [ ( "header", True )
                        , ( "current-drop-target", highlightDrop )
                        ]
                        :: DD.droppable FolderDDMsg DD.FolderRemove
                    )
                    [ text "Folders"
                    ]
                , div [ class "ui relaxed list" ]
                    (renderItems dropModel constr model)
                ]
            ]
        ]


renderItems : DD.Model -> Int -> Model -> List (Html Msg)
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


viewItem : DD.Model -> Model -> FolderStats -> Html Msg
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
            DD.getDropId dropModel == Just (DD.Folder item.id)
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
            ++ DD.droppable FolderDDMsg (DD.Folder item.id)
        )
        [ i [ class icon ] []
        , div [ class "content" ]
            [ div [ class "description" ]
                [ text item.name
                , div [ class "ui right floated circular label" ]
                    [ text (String.fromInt item.count)
                    ]
                ]
            ]
        ]



--- View2


viewDrop2 : DD.Model -> Int -> Model -> Html Msg
viewDrop2 dropModel constr model =
    let
        highlightDrop =
            DD.getDropId dropModel == Just DD.FolderRemove
    in
    div [ class "ui list" ]
        [ div [ class "item" ]
            [ i [ class "folder open icon" ] []
            , div [ class "content" ]
                [ div
                    (classList
                        [ ( "hidden", True )
                        , ( "current-drop-target", highlightDrop )
                        ]
                        :: DD.droppable FolderDDMsg DD.FolderRemove
                     -- note: re-enable this when adding a "no-folder selection"
                     -- this enables a drop target that removes a folder
                    )
                    [ text "Folders"
                    ]
                , div [ class "flex flex-col space-y-2 md:space-y-1" ]
                    (renderItems2 dropModel constr model)
                ]
            ]
        ]


renderItems2 : DD.Model -> Int -> Model -> List (Html Msg)
renderItems2 dropModel constr model =
    if constr <= 0 then
        List.map (viewItem2 dropModel model) model.all

    else if model.expanded then
        List.map (viewItem2 dropModel model) model.all ++ collapseToggle constr model

    else
        List.map (viewItem2 dropModel model) (List.take constr model.all) ++ expandToggle constr model


viewItem2 : DD.Model -> Model -> FolderStats -> Html Msg
viewItem2 dropModel model item =
    let
        selected =
            Just item.id == model.selected

        icon =
            if selected then
                "fa fa-folder-open font-thin"

            else
                "fa fa-folder font-thin"

        highlightDrop =
            DD.getDropId dropModel == Just (DD.Folder item.id)
    in
    a
        ([ classList
            [ ( "current-drop-target", highlightDrop )
            ]
         , class "flex flex-row items-center"
         , class "rounded px-1 py-1 hover:bg-blue-100 dark:hover:bg-bluegray-600"
         , href "#"
         , onClick (Toggle item)
         ]
            ++ DD.droppable FolderDDMsg (DD.Folder item.id)
        )
        [ i [ class icon ] []
        , div [ class "ml-2" ]
            [ text item.name
            ]
        , div [ class "flex-grow" ] []
        , numberLabel item.count
        ]


numberLabel : Int -> Html msg
numberLabel num =
    div
        [ class "bg-gray-200 border rounded-full h-6 w-6 flex items-center justify-center text-xs"
        , class "dark:bg-bluegray-800 dark:text-bluegray-200 dark:border-bluegray-800 dark:bg-opacity-50"
        ]
        [ text (String.fromInt num)
        ]
