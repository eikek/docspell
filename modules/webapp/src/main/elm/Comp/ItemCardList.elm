{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.ItemCardList exposing
    ( Model
    , Msg(..)
    , ViewConfig
    , init
    , nextItem
    , prevItem
    , update
    , updateDrag
    , view2
    )

import Api.Model.ItemLight exposing (ItemLight)
import Api.Model.ItemLightGroup exposing (ItemLightGroup)
import Api.Model.ItemLightList exposing (ItemLightList)
import Comp.ItemCard
import Comp.LinkTarget exposing (LinkTarget)
import Data.Flags exposing (Flags)
import Data.ItemSelection exposing (ItemSelection)
import Data.Items
import Data.UiSettings exposing (UiSettings)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Comp.ItemCardList exposing (Texts)
import Page exposing (Page(..))
import Styles as S
import Util.ItemDragDrop as DD
import Util.List


type alias Model =
    { results : ItemLightList
    , itemCards : Dict String Comp.ItemCard.Model
    }


type Msg
    = SetResults ItemLightList
    | AddResults ItemLightList
    | ItemCardMsg ItemLight Comp.ItemCard.Msg
    | RemoveItem String


init : Model
init =
    { results = Api.Model.ItemLightList.empty
    , itemCards = Dict.empty
    }


nextItem : Model -> String -> Maybe ItemLight
nextItem model id =
    List.concatMap .items model.results.groups
        |> Util.List.findNext (\i -> i.id == id)


prevItem : Model -> String -> Maybe ItemLight
prevItem model id =
    List.concatMap .items model.results.groups
        |> Util.List.findPrev (\i -> i.id == id)



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    let
        res =
            updateDrag DD.init flags msg model
    in
    ( res.model, res.cmd )


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , dragModel : DD.Model
    , selection : ItemSelection
    , linkTarget : LinkTarget
    }


updateDrag :
    DD.Model
    -> Flags
    -> Msg
    -> Model
    -> UpdateResult
updateDrag dm _ msg model =
    case msg of
        SetResults list ->
            let
                newModel =
                    { model | results = list }
            in
            UpdateResult newModel
                Cmd.none
                dm
                Data.ItemSelection.Inactive
                Comp.LinkTarget.LinkNone

        AddResults list ->
            if list.groups == [] then
                UpdateResult model
                    Cmd.none
                    dm
                    Data.ItemSelection.Inactive
                    Comp.LinkTarget.LinkNone

            else
                let
                    newModel =
                        { model | results = Data.Items.concat model.results list }
                in
                UpdateResult newModel
                    Cmd.none
                    dm
                    Data.ItemSelection.Inactive
                    Comp.LinkTarget.LinkNone

        ItemCardMsg item lm ->
            let
                cardModel =
                    Dict.get item.id model.itemCards
                        |> Maybe.withDefault Comp.ItemCard.init

                result =
                    Comp.ItemCard.update dm lm cardModel

                cards =
                    Dict.insert item.id result.model model.itemCards
            in
            UpdateResult { model | itemCards = cards }
                Cmd.none
                result.dragModel
                result.selection
                result.linkTarget

        RemoveItem id ->
            UpdateResult { model | results = removeItemById id model.results }
                Cmd.none
                dm
                Data.ItemSelection.Inactive
                Comp.LinkTarget.LinkNone



--- View2


type alias ViewConfig =
    { current : Maybe String
    , selection : ItemSelection
    }


view2 : Texts -> ViewConfig -> UiSettings -> Model -> Html Msg
view2 texts cfg settings model =
    div
        [ classList
            [ ( "ds-item-list", True )
            , ( "ds-multi-select-mode", isMultiSelectMode cfg )
            ]
        ]
        (List.map (viewGroup2 texts model cfg settings) model.results.groups)


viewGroup2 : Texts -> Model -> ViewConfig -> UiSettings -> ItemLightGroup -> Html Msg
viewGroup2 texts model cfg settings group =
    div [ class "ds-item-group" ]
        [ div
            [ class "flex py-1 mt-2 mb-2 flex flex-row items-center"
            , class "bg-white dark:bg-bluegray-800 text-xl font-bold z-35"
            , class "relative sticky top-10"
            ]
            [ hr
                [ class S.border2
                , class "w-16"
                ]
                []
            , div [ class "px-6" ]
                [ i [ class "fa fa-calendar-alt font-thin" ] []
                , span [ class "ml-2" ]
                    [ text group.name
                    ]
                ]
            , hr
                [ class S.border2
                , class "flex-grow"
                ]
                []
            ]
        , div [ class "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 2xl:grid-cols-4 gap-2" ]
            (List.map (viewItem2 texts model cfg settings) group.items)
        ]


viewItem2 : Texts -> Model -> ViewConfig -> UiSettings -> ItemLight -> Html Msg
viewItem2 texts model cfg settings item =
    let
        currentClass =
            if cfg.current == Just item.id then
                "current"

            else
                ""

        vvcfg =
            Comp.ItemCard.ViewConfig cfg.selection currentClass

        cardModel =
            Dict.get item.id model.itemCards
                |> Maybe.withDefault Comp.ItemCard.init

        cardHtml =
            Comp.ItemCard.view2 texts.itemCard vvcfg settings cardModel item
    in
    Html.map (ItemCardMsg item) cardHtml



--- Helpers


isMultiSelectMode : ViewConfig -> Bool
isMultiSelectMode cfg =
    case cfg.selection of
        Data.ItemSelection.Active _ ->
            True

        Data.ItemSelection.Inactive ->
            False


removeItemById : String -> ItemLightList -> ItemLightList
removeItemById id list =
    let
        filterItem item =
            item.id /= id

        filterGroup group =
            { group | items = List.filter filterItem group.items }
    in
    { list | groups = List.map filterGroup list.groups }
