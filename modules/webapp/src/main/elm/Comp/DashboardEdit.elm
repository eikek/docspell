module Comp.DashboardEdit exposing (Model, Msg, SubmitAction(..), init, update, view, viewBox)

import Comp.BoxEdit
import Comp.FixedDropdown
import Comp.MenuBar as MB
import Data.Box exposing (Box)
import Data.Dashboard exposing (Dashboard)
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Dict exposing (Dict)
import Html exposing (Html, div, i, input, label, text)
import Html.Attributes exposing (class, classList, href, placeholder, type_, value)
import Html.Events exposing (onClick, onInput)
import Html5.DragDrop as DD
import Messages.Comp.DashboardEdit exposing (Texts)
import Styles as S
import Util.Maybe


type alias Model =
    { dashboard : Dashboard
    , originalName : String
    , boxModels : Dict Int Comp.BoxEdit.Model
    , nameValue : Maybe String
    , columnsModel : Comp.FixedDropdown.Model Int
    , columnsValue : Maybe Int
    , newBoxMenuOpen : Bool
    , boxDragDrop : DD.Model Int Int
    }


type Msg
    = BoxMsg Int Comp.BoxEdit.Msg
    | SaveDashboard
    | Cancel
    | RequestDelete
    | SetName String
    | ColumnsMsg (Comp.FixedDropdown.Msg Int)
    | ToggleNewBoxMenu
    | PrependNew Box
    | DragDropMsg (DD.Msg Int Int)


type SubmitAction
    = SubmitSave Dashboard
    | SubmitCancel
    | SubmitDelete String
    | SubmitNone


init : Flags -> Dashboard -> ( Model, Cmd Msg, Sub Msg )
init flags db =
    let
        ( boxModels, cmdsAndSubs ) =
            List.map (Comp.BoxEdit.init flags) db.boxes
                |> List.indexedMap
                    (\a ->
                        \( bm, bc, bs ) ->
                            ( bm, ( Cmd.map (BoxMsg a) bc, Sub.map (BoxMsg a) bs ) )
                    )
                |> List.unzip

        ( cmds, subs ) =
            List.unzip cmdsAndSubs
    in
    ( { dashboard = db
      , originalName = db.name
      , nameValue = Just db.name
      , columnsModel = Comp.FixedDropdown.init [ 1, 2, 3, 4, 5 ]
      , columnsValue = Just db.columns
      , newBoxMenuOpen = False
      , boxModels =
            List.indexedMap Tuple.pair boxModels
                |> Dict.fromList
      , boxDragDrop = DD.init
      }
    , Cmd.batch cmds
    , Sub.batch subs
    )



--- Update


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    , action : SubmitAction
    }


update : Flags -> Msg -> Model -> UpdateResult
update flags msg model =
    case msg of
        BoxMsg index lm ->
            case Dict.get index model.boxModels of
                Just bm ->
                    let
                        result =
                            Comp.BoxEdit.update flags lm bm

                        newBoxes =
                            applyBoxAction index result.action <|
                                Dict.insert index result.model model.boxModels

                        db =
                            model.dashboard

                        db_ =
                            { db | boxes = List.map .box (Dict.values newBoxes) }
                    in
                    { model = { model | boxModels = newBoxes, dashboard = db_ }
                    , cmd = Cmd.map (BoxMsg index) result.cmd
                    , sub = Sub.map (BoxMsg index) result.sub
                    , action = SubmitNone
                    }

                Nothing ->
                    unit model

        SetName str ->
            case Util.Maybe.fromString str of
                Just s ->
                    let
                        db =
                            model.dashboard

                        db_ =
                            { db | name = s }
                    in
                    unit { model | dashboard = db_, nameValue = Just s }

                Nothing ->
                    unit { model | nameValue = Nothing }

        ColumnsMsg lm ->
            let
                ( cm, value ) =
                    Comp.FixedDropdown.update lm model.columnsModel

                db =
                    model.dashboard

                db_ =
                    { db | columns = Maybe.withDefault db.columns value }
            in
            unit { model | columnsValue = value, columnsModel = cm, dashboard = db_ }

        SaveDashboard ->
            UpdateResult model Cmd.none Sub.none (SubmitSave model.dashboard)

        Cancel ->
            UpdateResult model Cmd.none Sub.none SubmitCancel

        RequestDelete ->
            UpdateResult model Cmd.none Sub.none (SubmitDelete model.originalName)

        ToggleNewBoxMenu ->
            unit { model | newBoxMenuOpen = not model.newBoxMenuOpen }

        PrependNew box ->
            let
                min =
                    Dict.keys model.boxModels
                        |> List.minimum
                        |> Maybe.withDefault 1

                index =
                    min - 1

                db =
                    model.dashboard

                db_ =
                    { db | boxes = box :: db.boxes }

                ( bm, bc, bs ) =
                    Comp.BoxEdit.init flags box

                newBoxes =
                    Dict.insert index bm model.boxModels
            in
            { model = { model | boxModels = newBoxes, dashboard = db_, newBoxMenuOpen = False }
            , cmd = Cmd.map (BoxMsg index) bc
            , sub = Sub.map (BoxMsg index) bs
            , action = SubmitNone
            }

        DragDropMsg lm ->
            let
                ( dm, dropped ) =
                    DD.update lm model.boxDragDrop

                m_ =
                    { model | boxDragDrop = dm }

                nextModel =
                    case dropped of
                        Just ( dragId, dropId, _ ) ->
                            applyDrop dragId dropId m_

                        Nothing ->
                            m_
            in
            unit nextModel


unit : Model -> UpdateResult
unit model =
    UpdateResult model Cmd.none Sub.none SubmitNone


applyBoxAction :
    Int
    -> Comp.BoxEdit.BoxAction
    -> Dict Int Comp.BoxEdit.Model
    -> Dict Int Comp.BoxEdit.Model
applyBoxAction index action boxes =
    let
        swap n1 n2 =
            Maybe.map2
                (\e1 -> \e2 -> Dict.insert n2 e1 boxes |> Dict.insert n1 e2)
                (Dict.get n1 boxes)
                (Dict.get n2 boxes)
                |> Maybe.withDefault boxes
    in
    case action of
        Comp.BoxEdit.BoxNoAction ->
            boxes

        Comp.BoxEdit.BoxDelete ->
            Dict.remove index boxes

        Comp.BoxEdit.BoxMoveLeft ->
            swap (index - 1) index

        Comp.BoxEdit.BoxMoveRight ->
            swap index (index + 1)


applyDrop : Int -> Int -> Model -> Model
applyDrop dragId dropId model =
    let
        dragEl =
            Dict.get dragId model.boxModels
    in
    if dragId == dropId then
        model

    else
        case dragEl of
            Just box ->
                let
                    withoutDragged =
                        Dict.remove dragId model.boxModels

                    ( begin, end ) =
                        Dict.partition (\k -> \_ -> k < dropId) withoutDragged

                    incKeys =
                        Dict.toList end
                            |> List.map (\( k, v ) -> ( k + 1, v ))
                            |> Dict.fromList

                    newBoxes =
                        Dict.insert dropId box (Dict.union begin incKeys)

                    db =
                        model.dashboard

                    db_ =
                        { db | boxes = List.map .box (Dict.values newBoxes) }
                in
                { model | boxModels = newBoxes, dashboard = db_ }

            Nothing ->
                model



--- View


view : Texts -> Flags -> UiSettings -> Model -> Html Msg
view texts flags settings model =
    let
        boxMenuItem box =
            { icon = i [ class (Data.Box.boxIcon box) ] []
            , label = texts.boxContent.forContent box.content
            , disabled = False
            , attrs =
                [ href "#"
                , onClick (PrependNew box)
                ]
            }
    in
    div []
        [ viewMain texts flags settings model
        , div [ class S.formHeader ]
            [ text texts.dashboardBoxes
            ]
        , MB.view
            { start = []
            , end =
                [ MB.Dropdown
                    { linkIcon = "fa fa-plus"
                    , label = texts.newBox
                    , linkClass =
                        [ ( S.secondaryBasicButton, True )
                        ]
                    , toggleMenu = ToggleNewBoxMenu
                    , menuOpen = model.newBoxMenuOpen
                    , items =
                        [ boxMenuItem Data.Box.queryBox
                        , boxMenuItem Data.Box.statsBox
                        , boxMenuItem Data.Box.messageBox
                        , boxMenuItem Data.Box.uploadBox
                        ]
                    }
                ]
            , rootClasses = "mb-2"
            }
        , div
            [ class (gridStyle model.dashboard)
            ]
            (List.map
                (viewBox texts flags settings model)
                (Dict.toList model.boxModels)
            )
        ]


viewBox : Texts -> Flags -> UiSettings -> Model -> ( Int, Comp.BoxEdit.Model ) -> Html Msg
viewBox texts flags settings model ( index, box ) =
    let
        dropId =
            DD.getDropId model.boxDragDrop

        dragId =
            DD.getDragId model.boxDragDrop

        styles =
            [ classList [ ( "opacity-40", dropId == Just index && dropId /= dragId ) ]
            , class (spanStyle box.box)
            ]
    in
    div
        (DD.draggable DragDropMsg index ++ DD.droppable DragDropMsg index ++ styles)
        [ Html.map (BoxMsg index)
            (Comp.BoxEdit.view texts.boxView flags settings box)
        ]


viewMain : Texts -> Flags -> UiSettings -> Model -> Html Msg
viewMain texts _ _ model =
    let
        columnsSettings =
            { display = String.fromInt
            , icon = \_ -> Nothing
            , selectPlaceholder = ""
            , style = DS.mainStyle
            }
    in
    div [ class "my-2 " ]
        [ MB.view
            { start =
                [ MB.PrimaryButton
                    { tagger = SaveDashboard
                    , title = texts.basics.submitThisForm
                    , icon = Just "fa fa-save"
                    , label = texts.basics.submit
                    }
                , MB.SecondaryButton
                    { tagger = Cancel
                    , title = texts.basics.cancel
                    , icon = Just "fa fa-times"
                    , label = texts.basics.cancel
                    }
                ]
            , end = []
            , rootClasses = ""
            }
        , div [ class "flex flex-col" ]
            [ div [ class "mt-2" ]
                [ label [ class S.inputLabel ]
                    [ text texts.basics.name
                    ]
                , input
                    [ type_ "text"
                    , placeholder texts.namePlaceholder
                    , class S.textInput
                    , value (Maybe.withDefault "" model.nameValue)
                    , onInput SetName
                    ]
                    []
                ]
            , div [ class "mt-2" ]
                [ label [ class S.inputLabel ]
                    [ text texts.columns
                    ]
                ]
            , Html.map ColumnsMsg
                (Comp.FixedDropdown.viewStyled2 columnsSettings
                    False
                    model.columnsValue
                    model.columnsModel
                )
            ]
        ]



--- Helpers


gridStyle : Dashboard -> String
gridStyle db =
    let
        colStyle =
            case db.columns of
                1 ->
                    ""

                2 ->
                    "md:grid-cols-2"

                3 ->
                    "md:grid-cols-3"

                4 ->
                    "md:grid-cols-4"

                _ ->
                    "md:grid-cols-5"
    in
    "grid gap-4 grid-cols-1 " ++ colStyle


spanStyle : Box -> String
spanStyle box =
    case box.colspan of
        1 ->
            ""

        2 ->
            "col-span-1 md:col-span-2"

        3 ->
            "col-span-1 md:col-span-3"

        4 ->
            "col-span-1 md:col-span-4"

        _ ->
            "col-span-1 md:col-span-5"
