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
    , view
    )

import Api.Model.AttachmentLight exposing (AttachmentLight)
import Api.Model.ItemLight exposing (ItemLight)
import Api.Model.ItemLightGroup exposing (ItemLightGroup)
import Api.Model.ItemLightList exposing (ItemLightList)
import Comp.ItemCard
import Comp.LinkTarget exposing (LinkTarget)
import Data.Flags exposing (Flags)
import Data.ItemArrange exposing (ItemArrange)
import Data.ItemSelection exposing (ItemSelection)
import Data.Items
import Data.UiSettings exposing (UiSettings)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Comp.ItemCardList exposing (Texts)
import Page exposing (Page(..))
import Set exposing (Set)
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


update : Flags -> Msg -> Model -> UpdateResult
update flags msg model =
    updateDrag DD.init flags msg model


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , dragModel : DD.Model
    , selection : ItemSelection
    , linkTarget : LinkTarget
    , toggleOpenRow : Maybe String
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
                Nothing

        AddResults list ->
            if list.groups == [] then
                UpdateResult model
                    Cmd.none
                    dm
                    Data.ItemSelection.Inactive
                    Comp.LinkTarget.LinkNone
                    Nothing

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
                    Nothing

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
                result.toggleRow

        RemoveItem id ->
            UpdateResult { model | results = removeItemById id model.results }
                Cmd.none
                dm
                Data.ItemSelection.Inactive
                Comp.LinkTarget.LinkNone
                Nothing



--- View2


type alias ViewConfig =
    { current : Maybe String
    , selection : ItemSelection
    , previewUrl : AttachmentLight -> String
    , previewUrlFallback : ItemLight -> String
    , attachUrl : AttachmentLight -> String
    , detailPage : ItemLight -> Page
    , arrange : ItemArrange
    , showGroups : Bool
    , rowOpen : String -> Bool
    }


view : Texts -> ViewConfig -> UiSettings -> Flags -> Model -> Html Msg
view texts cfg settings flags model =
    case cfg.arrange of
        Data.ItemArrange.Cards ->
            viewCards texts cfg settings flags model

        Data.ItemArrange.List ->
            viewList texts cfg settings flags model


viewList : Texts -> ViewConfig -> UiSettings -> Flags -> Model -> Html Msg
viewList texts cfg settings flags model =
    let
        items =
            Data.Items.unwrapGroups model.results.groups

        listingCss =
            "grid grid-cols-1 space-y-1"
    in
    if cfg.showGroups then
        div [ class listingCss ]
            (List.map (viewGroup texts model cfg settings flags) model.results.groups)

    else
        div [ class (itemContainerCss cfg) ]
            (List.map (viewItem texts model cfg settings flags) items)


itemContainerCss : ViewConfig -> String
itemContainerCss cfg =
    case cfg.arrange of
        Data.ItemArrange.Cards ->
            "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 2xl:grid-cols-4 gap-2"

        Data.ItemArrange.List ->
            "flex flex-col divide-y"


viewCards : Texts -> ViewConfig -> UiSettings -> Flags -> Model -> Html Msg
viewCards texts cfg settings flags model =
    let
        items =
            Data.Items.unwrapGroups model.results.groups
    in
    if cfg.showGroups then
        div
            [ classList
                [ ( "ds-item-list", True )
                , ( "ds-multi-select-mode", isMultiSelectMode cfg )
                ]
            ]
            (List.map (viewGroup texts model cfg settings flags) model.results.groups)

    else
        div
            [ class "ds-item-list"
            , class (itemContainerCss cfg)
            , classList
                [ ( "ds-multi-select-mode", isMultiSelectMode cfg )
                ]
            ]
            (List.map (viewItem texts model cfg settings flags) items)


viewGroup : Texts -> Model -> ViewConfig -> UiSettings -> Flags -> ItemLightGroup -> Html Msg
viewGroup texts model cfg settings flags group =
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
        , div [ class (itemContainerCss cfg) ]
            (List.map (viewItem texts model cfg settings flags) group.items)
        ]


viewItem : Texts -> Model -> ViewConfig -> UiSettings -> Flags -> ItemLight -> Html Msg
viewItem texts model cfg settings flags item =
    let
        currentClass =
            if cfg.current == Just item.id then
                "current"

            else
                ""

        itemClass =
            case cfg.arrange of
                Data.ItemArrange.List ->
                    " py-1 "

                Data.ItemArrange.Cards ->
                    ""

        vvcfg =
            { selection = cfg.selection
            , extraClasses = currentClass ++ itemClass
            , previewUrl = cfg.previewUrl
            , previewUrlFallback = cfg.previewUrlFallback
            , attachUrl = cfg.attachUrl
            , detailPage = cfg.detailPage
            , isRowOpen = cfg.rowOpen item.id
            , arrange = cfg.arrange
            }

        cardModel =
            Dict.get item.id model.itemCards
                |> Maybe.withDefault Comp.ItemCard.init

        cardHtml =
            Comp.ItemCard.view texts.itemCard vvcfg settings flags cardModel item
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
