{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.TagSelect exposing
    ( CategoryCount
    , Model
    , Msg
    , Selection
    , WorkModel
    , emptySelection
    , init
    , makeWorkModel
    , modifyAll
    , modifyCount
    , modifyCountKeepExisting
    , reset
    , toggleTag
    , update
    , updateDrop
    , viewAll2
    , viewCats2
    , viewTagsDrop2
    )

import Api.Model.NameCount exposing (NameCount)
import Api.Model.Tag exposing (Tag)
import Api.Model.TagCount exposing (TagCount)
import Comp.ExpandCollapse
import Data.Icons as I
import Data.UiSettings exposing (UiSettings)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Messages.Comp.TagSelect exposing (Texts)
import Set
import Simple.Fuzzy
import String as S
import Styles as S
import Util.ItemDragDrop as DD
import Util.Maybe


type alias Model =
    { availableTags : Dict String TagCount
    , availableCats : Dict String CategoryCount
    , tagCounts : List TagCount
    , categoryCounts : List CategoryCount
    , filterTerm : Maybe String
    , expandedTags : Bool
    , expandedCats : Bool
    , showEmpty : Bool
    }


type alias CategoryCount =
    { name : String
    , count : Int
    }


init : List TagCount -> List NameCount -> List TagCount -> List NameCount -> Model
init allTags allCats tags cats =
    { availableTags =
        List.map (\e -> ( e.tag.id, e )) allTags
            |> Dict.fromList
    , availableCats =
        List.filterMap (\e -> Maybe.map (\k -> ( k, CategoryCount k e.count )) e.name) allCats
            |> Dict.fromList
    , tagCounts = tags
    , categoryCounts = List.filterMap (\e -> Maybe.map (\k -> CategoryCount k e.count) e.name) cats
    , filterTerm = Nothing
    , expandedTags = False
    , expandedCats = False
    , showEmpty = True
    }


modifyAll : List TagCount -> List NameCount -> Model -> Model
modifyAll allTags allCats model =
    { model
        | availableTags =
            List.map (\e -> ( e.tag.id, e )) allTags
                |> Dict.fromList
        , availableCats =
            List.filterMap (\e -> Maybe.map (\k -> ( k, CategoryCount k e.count )) e.name) allCats
                |> Dict.fromList
    }


modifyCount : Model -> List TagCount -> List NameCount -> Model
modifyCount model tags cats =
    { model
        | tagCounts = tags
        , categoryCounts = List.filterMap (\e -> Maybe.map (\k -> CategoryCount k e.count) e.name) cats
    }


modifyCountKeepExisting : Model -> List TagCount -> List NameCount -> Model
modifyCountKeepExisting model tags cats =
    let
        tagZeros : Dict String TagCount
        tagZeros =
            Dict.map (\_ -> \tc -> TagCount tc.tag 0) model.availableTags

        tagAvail =
            List.foldl (\tc -> \dict -> Dict.insert tc.tag.id tc dict) tagZeros tags

        tcs =
            Dict.values tagAvail

        catcs =
            List.filterMap (\e -> Maybe.map (\k -> CategoryCount k e.count) e.name) cats

        catZeros : Dict String CategoryCount
        catZeros =
            Dict.map (\_ -> \cc -> CategoryCount cc.name 0) model.availableCats

        catAvail =
            List.foldl (\cc -> \dict -> Dict.insert cc.name cc dict) catZeros catcs

        ccs =
            Dict.values catAvail
    in
    { model
        | tagCounts = tcs
        , availableTags = tagAvail
        , categoryCounts = ccs
        , availableCats = catAvail
    }


reset : Model -> Model
reset model =
    { model
        | filterTerm = Nothing
        , expandedTags = False
        , expandedCats = False
        , showEmpty = True
    }


toggleTag : String -> Msg
toggleTag id =
    ToggleTag id


type alias Selection =
    { includeTags : List TagCount
    , excludeTags : List TagCount
    , includeCats : List CategoryCount
    , excludeCats : List CategoryCount
    }


emptySelection : Selection
emptySelection =
    Selection [] [] [] []


type alias WorkModel =
    { filteredCats : List CategoryCount
    , filteredTags : List TagCount
    , selectedTags : Dict String Bool
    , selectedCats : Dict String Bool
    }


{-| Orders the list of tag counts by their overall counts and not by
their direct counts.
-}
orderTagCountStable : Model -> List TagCount -> List TagCount
orderTagCountStable model tagCounts =
    let
        order tc =
            Dict.get tc.tag.id model.availableTags
                |> Maybe.map (\e -> ( e.count * -1, S.toLower e.tag.name ))
                |> Maybe.withDefault ( 0, S.toLower tc.tag.name )
    in
    List.sortBy order tagCounts


orderCatCountStable : Model -> List CategoryCount -> List CategoryCount
orderCatCountStable model catCounts =
    let
        order cat =
            Dict.get cat.name model.availableCats
                |> Maybe.map (\e -> ( e.count * -1, S.toLower e.name ))
                |> Maybe.withDefault ( 0, S.toLower cat.name )
    in
    List.sortBy order catCounts


removeEmptyTagCounts : Selection -> List TagCount -> List TagCount
removeEmptyTagCounts sel tagCounts =
    let
        selected =
            List.concat
                [ List.map (.tag >> .id) sel.includeTags
                , List.map (.tag >> .id) sel.excludeTags
                ]
                |> Set.fromList

        isSelected tc =
            Set.member tc.tag.id selected
    in
    List.filter (\tc -> isSelected tc || tc.count > 0) tagCounts


removeEmptyCatCounts : Selection -> List CategoryCount -> List CategoryCount
removeEmptyCatCounts sel catCounts =
    let
        selected =
            List.concat
                [ List.map .name sel.includeCats
                , List.map .name sel.excludeCats
                ]
                |> Set.fromList

        isSelected cat =
            Set.member cat.name selected
    in
    List.filter (\tc -> isSelected tc || tc.count > 0) catCounts


makeWorkModel : Selection -> Model -> WorkModel
makeWorkModel sel model =
    let
        tagCounts =
            orderTagCountStable model
                (if model.showEmpty then
                    model.tagCounts

                 else
                    removeEmptyTagCounts sel model.tagCounts
                )

        catCounts =
            orderCatCountStable model
                (if model.showEmpty then
                    model.categoryCounts

                 else
                    removeEmptyCatCounts sel model.categoryCounts
                )

        ( tags, cats ) =
            case model.filterTerm of
                Just filter ->
                    ( List.filter (\t -> Simple.Fuzzy.match filter t.tag.name) tagCounts
                    , List.filter (\c -> Simple.Fuzzy.match filter c.name) catCounts
                    )

                Nothing ->
                    ( tagCounts, catCounts )

        tagId t =
            t.tag.id

        constDict mkId flag list =
            List.map (\e -> ( mkId e, flag )) list
                |> Dict.fromList

        selTag =
            constDict tagId True sel.includeTags
                |> Dict.union (constDict tagId False sel.excludeTags)

        selCat =
            constDict .name True sel.includeCats
                |> Dict.union (constDict .name False sel.excludeCats)
    in
    { filteredCats = cats
    , filteredTags = tags
    , selectedTags = selTag
    , selectedCats = selCat
    }


noEmptyTags : Model -> Bool
noEmptyTags model =
    Dict.filter (\k -> \v -> v.count == 0) model.availableTags
        |> Dict.isEmpty


type Msg
    = ToggleTag String
    | ToggleCat String
    | ToggleExpandTags
    | ToggleExpandCats
    | ToggleShowEmpty
    | TagDDMsg DD.Msg
    | Search String


update : Selection -> Msg -> Model -> ( Model, Selection )
update sel msg model =
    let
        ( m, s, _ ) =
            updateDrop DD.init sel msg model
    in
    ( m, s )


updateDrop : DD.Model -> Selection -> Msg -> Model -> ( Model, Selection, DD.DragDropData )
updateDrop ddm sel msg model =
    let
        wm =
            makeWorkModel sel model
    in
    case msg of
        ToggleShowEmpty ->
            ( { model | showEmpty = not model.showEmpty }
            , sel
            , DD.DragDropData ddm Nothing
            )

        ToggleTag id ->
            let
                next =
                    updateSelection id wm.selectedTags

                wm_ =
                    { wm | selectedTags = next }
            in
            ( model, getSelection wm_, DD.DragDropData ddm Nothing )

        ToggleCat name ->
            let
                next =
                    updateSelection name wm.selectedCats

                wm_ =
                    { wm | selectedCats = next }
            in
            ( model, getSelection wm_, DD.DragDropData ddm Nothing )

        ToggleExpandTags ->
            ( { model | expandedTags = not model.expandedTags }
            , sel
            , DD.DragDropData ddm Nothing
            )

        ToggleExpandCats ->
            ( { model | expandedCats = not model.expandedCats }
            , sel
            , DD.DragDropData ddm Nothing
            )

        TagDDMsg lm ->
            let
                ddd =
                    DD.update lm ddm
            in
            ( model, sel, ddd )

        Search str ->
            ( { model | filterTerm = Util.Maybe.fromString str }
            , sel
            , DD.DragDropData ddm Nothing
            )


updateSelection : String -> Dict String Bool -> Dict String Bool
updateSelection id selected =
    let
        current =
            Dict.get id selected
    in
    case current of
        Nothing ->
            Dict.insert id True selected

        Just True ->
            Dict.insert id False selected

        Just False ->
            Dict.remove id selected


getSelection : WorkModel -> Selection
getSelection model =
    let
        ( inclTags, exclTags ) =
            getSelection1 (\t -> t.tag.id) model.selectedTags model.filteredTags

        ( inclCats, exclCats ) =
            getSelection1 (\c -> c.name) model.selectedCats model.filteredCats
    in
    Selection inclTags exclTags inclCats exclCats


getSelection1 : (a -> String) -> Dict String Bool -> List a -> ( List a, List a )
getSelection1 mkId selected items =
    let
        selectedOnly t =
            Dict.member (mkId t) selected

        isIncluded t =
            Dict.get (mkId t) selected
                |> Maybe.withDefault False
    in
    List.filter selectedOnly items
        |> List.partition isIncluded



--- View


type SelState
    = Include
    | Exclude
    | Deselect


tagState : WorkModel -> String -> SelState
tagState model id =
    case Dict.get id model.selectedTags of
        Just True ->
            Include

        Just False ->
            Exclude

        Nothing ->
            Deselect


catState : WorkModel -> String -> SelState
catState model name =
    case Dict.get name model.selectedCats of
        Just True ->
            Include

        Just False ->
            Exclude

        Nothing ->
            Deselect



--- View2


viewAll2 : Texts -> DD.Model -> UiSettings -> Selection -> Model -> List (Html Msg)
viewAll2 texts ddm settings sel model =
    let
        wm =
            makeWorkModel sel model
    in
    viewTagsDrop2 texts ddm wm settings model ++ [ viewCats2 texts settings wm model ]


viewTagsDrop2 : Texts -> DD.Model -> WorkModel -> UiSettings -> Model -> List (Html Msg)
viewTagsDrop2 texts ddm wm settings model =
    [ div [ class "flex flex-col" ]
        [ div [ class "flex flex-row h-6 items-center text-xs mb-2" ]
            [ a
                [ class S.secondaryBasicButtonPlain
                , class "border rounded flex-none px-1 py-1"
                , classList [ ( "hidden", noEmptyTags model ) ]
                , href "#"
                , onClick ToggleShowEmpty
                ]
                [ if model.showEmpty then
                    text (" " ++ texts.hideEmpty)

                  else
                    text (" " ++ texts.showEmpty)
                ]
            , div [ class "flex-grow" ] []
            , div [ class " relative h-6" ]
                [ input
                    [ type_ "text"
                    , placeholder texts.filterPlaceholder
                    , onInput Search
                    , class "bg-blue-50 w-30 h-6 px-0 py-0 text-xs"
                    , class "border-0 border-b border-gray-200 focus:ring-0 focus:border-black"
                    , class "dark:bg-slate-700 dark:text-slate-200 dark:border-slate-400 dark:focus:border-white"
                    ]
                    []
                , i [ class "fa fa-search absolute top-1/3 right-0 opacity-50" ] []
                ]
            ]
        ]
    , div [ class "flex flex-col space-y-2 md:space-y-1" ]
        (renderTagItems2 texts ddm settings model wm)
    ]


viewCats2 : Texts -> UiSettings -> WorkModel -> Model -> Html Msg
viewCats2 texts settings wm model =
    div [ class "flex flex-col" ]
        [ div [ class "flex flex-col space-y-2 md:space-y-1" ]
            (renderCatItems2 texts settings model wm)
        ]


renderTagItems2 : Texts -> DD.Model -> UiSettings -> Model -> WorkModel -> List (Html Msg)
renderTagItems2 texts ddm settings model wm =
    let
        tags =
            wm.filteredTags

        max =
            settings.searchMenuTagCount

        expLink =
            Comp.ExpandCollapse.expandToggle
                texts.expandCollapse
                { max = max
                , all = List.length tags
                }
                ToggleExpandTags

        cpsLink =
            Comp.ExpandCollapse.collapseToggle
                texts.expandCollapse
                { max = max
                , all = List.length tags
                }
                ToggleExpandTags
    in
    if max <= 0 then
        List.map (viewTagItem2 ddm settings wm) tags

    else if model.expandedTags then
        List.map (viewTagItem2 ddm settings wm) tags ++ cpsLink

    else
        List.map (viewTagItem2 ddm settings wm) (List.take max tags) ++ expLink


viewTagItem2 : DD.Model -> UiSettings -> WorkModel -> TagCount -> Html Msg
viewTagItem2 ddm settings model tag =
    let
        state =
            tagState model tag.tag.id

        color =
            Data.UiSettings.tagColorFg2 tag.tag settings

        icon =
            getIcon2 state color I.tagIcon2

        dropActive =
            DD.getDropId ddm == Just (DD.Tag tag.tag.id)
    in
    a
        ([ classList
            [ ( "bg-blue-100 dark:bg-slate-600", dropActive )
            ]
         , class "flex flex-row items-center"
         , class "rounded px-1 py-1 hover:bg-blue-100 dark:hover:bg-slate-600"
         , href "#"
         , onClick (ToggleTag tag.tag.id)
         ]
            ++ DD.droppable TagDDMsg (DD.Tag tag.tag.id)
        )
        [ icon
        , div
            [ classList
                [ ( "font-semibold", state == Include )
                , ( "", state /= Include )
                ]
            , class "ml-2"
            ]
            [ text tag.tag.name
            ]
        , div [ class "flex-grow" ] []
        , numberLabel tag.count
        ]


viewCategoryItem2 : UiSettings -> WorkModel -> CategoryCount -> Html Msg
viewCategoryItem2 settings model cat =
    let
        state =
            catState model cat.name

        color =
            Data.UiSettings.catColorFg2 settings cat.name

        icon =
            getIcon2 state color I.tagsIcon2
    in
    a
        [ class "flex flex-row items-center"
        , class "rounded px-1 py-1 hover:bg-blue-100 dark:hover:bg-slate-600"
        , href "#"
        , onClick (ToggleCat cat.name)
        ]
        [ icon
        , div
            [ classList
                [ ( "font-semibold", state == Include )
                , ( "", state /= Include )
                ]
            , class "ml-2"
            ]
            [ text cat.name
            ]
        , div [ class "flex-grow" ] []
        , numberLabel cat.count
        ]


renderCatItems2 : Texts -> UiSettings -> Model -> WorkModel -> List (Html Msg)
renderCatItems2 texts settings model wm =
    let
        cats =
            wm.filteredCats

        max =
            settings.searchMenuTagCatCount

        expLink =
            Comp.ExpandCollapse.expandToggle
                texts.expandCollapse
                { max = max
                , all = List.length cats
                }
                ToggleExpandCats

        cpsLink =
            Comp.ExpandCollapse.collapseToggle
                texts.expandCollapse
                { max = max
                , all = List.length cats
                }
                ToggleExpandCats
    in
    if max <= 0 then
        List.map (viewCategoryItem2 settings wm) cats

    else if model.expandedCats then
        List.map (viewCategoryItem2 settings wm) cats ++ cpsLink

    else
        List.map (viewCategoryItem2 settings wm) (List.take max cats) ++ expLink


getIcon2 : SelState -> String -> (String -> Html msg) -> Html msg
getIcon2 state color default =
    case state of
        Include ->
            i [ class ("fa fa-check " ++ color) ] []

        Exclude ->
            i [ class ("fa fa-minus " ++ color) ] []

        Deselect ->
            default color


numberLabel : Int -> Html msg
numberLabel num =
    div
        [ class "bg-gray-200 border rounded-full h-6 w-6 flex items-center justify-center text-xs"
        , class "dark:bg-slate-800 dark:text-slate-200 dark:border-slate-800 dark:bg-opacity-50"
        ]
        [ text (String.fromInt num)
        ]
