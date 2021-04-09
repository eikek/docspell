module Comp.TagSelect exposing
    ( Category
    , Model
    , Msg
    , Selection
    , WorkModel
    , emptySelection
    , init
    , makeWorkModel
    , modifyAll
    , modifyCount
    , reset
    , toggleTag
    , update
    , updateDrop
    , viewAll2
    , viewCats2
    , viewTagsDrop2
    )

import Api.Model.Tag exposing (Tag)
import Api.Model.TagCount exposing (TagCount)
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
import Util.ExpandCollapse
import Util.ItemDragDrop as DD
import Util.Maybe


type alias Model =
    { availableTags : Dict String TagCount
    , availableCats : Dict String Category
    , tagCounts : List TagCount
    , categoryCounts : List Category
    , filterTerm : Maybe String
    , expandedTags : Bool
    , expandedCats : Bool
    , showEmpty : Bool
    }


type alias Category =
    { name : String
    , count : Int
    }


init : List TagCount -> List TagCount -> Model
init allTags tags =
    { availableTags =
        List.map (\e -> ( e.tag.id, e )) allTags
            |> Dict.fromList
    , availableCats = sumCategories allTags
    , tagCounts = tags
    , categoryCounts =
        sumCategories tags
            |> Dict.toList
            |> List.map Tuple.second
    , filterTerm = Nothing
    , expandedTags = False
    , expandedCats = False
    , showEmpty = True
    }


modifyAll : List TagCount -> Model -> Model
modifyAll allTags model =
    { model
        | availableTags =
            List.map (\e -> ( e.tag.id, e )) allTags
                |> Dict.fromList
        , availableCats = sumCategories allTags
    }


modifyCount : Model -> List TagCount -> Model
modifyCount model tags =
    { model
        | tagCounts = tags
        , categoryCounts =
            sumCategories tags
                |> Dict.toList
                |> List.map Tuple.second
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


sumCategories : List TagCount -> Dict String Category
sumCategories tags =
    let
        filterCat tc =
            Maybe.map (\cat -> Category cat tc.count) tc.tag.category

        withCats =
            List.filterMap filterCat tags

        sum cat mc =
            Maybe.map ((+) cat.count) mc
                |> Maybe.withDefault cat.count
                |> Just

        sumCounts cat dict =
            Dict.update cat.name (sum cat) dict

        cats =
            List.foldl sumCounts Dict.empty withCats
    in
    Dict.map (\name -> \count -> Category name count) cats


type alias Selection =
    { includeTags : List TagCount
    , excludeTags : List TagCount
    , includeCats : List Category
    , excludeCats : List Category
    }


emptySelection : Selection
emptySelection =
    Selection [] [] [] []


type alias WorkModel =
    { filteredCats : List Category
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


orderCatCountStable : Model -> List Category -> List Category
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


removeEmptyCatCounts : Selection -> List Category -> List Category
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
    viewTagsDrop2 texts ddm wm settings model ++ [ viewCats2 settings wm model ]


viewTagsDrop2 : Texts -> DD.Model -> WorkModel -> UiSettings -> Model -> List (Html Msg)
viewTagsDrop2 texts ddm wm settings model =
    [ div [ class "flex flex-col" ]
        [ div [ class "flex flex-row h-6 items-center text-xs mb-2" ]
            [ a
                [ class S.secondaryBasicButtonPlain
                , class "border rounded flex-none px-1 py-1"
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
                    , class "dark:bg-bluegray-700 dark:text-bluegray-200 dark:border-bluegray-400 dark:focus:border-white"
                    ]
                    []
                , i [ class "fa fa-search absolute top-1/3 right-0 opacity-50" ] []
                ]
            ]
        ]
    , div [ class "flex flex-col space-y-2 md:space-y-1" ]
        (renderTagItems2 ddm settings model wm)
    ]


viewCats2 : UiSettings -> WorkModel -> Model -> Html Msg
viewCats2 settings wm model =
    div [ class "flex flex-col" ]
        [ div [ class "flex flex-col space-y-2 md:space-y-1" ]
            (renderCatItems2 settings model wm)
        ]


renderTagItems2 : DD.Model -> UiSettings -> Model -> WorkModel -> List (Html Msg)
renderTagItems2 ddm settings model wm =
    let
        tags =
            wm.filteredTags

        max =
            settings.searchMenuTagCount

        expLink =
            Util.ExpandCollapse.expandToggle2
                max
                (List.length tags)
                ToggleExpandTags

        cpsLink =
            Util.ExpandCollapse.collapseToggle2
                max
                (List.length tags)
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
            [ ( "bg-blue-100 dark:bg-bluegray-600", dropActive )
            ]
         , class "flex flex-row items-center"
         , class "rounded px-1 py-1 hover:bg-blue-100 dark:hover:bg-bluegray-600"
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


viewCategoryItem2 : UiSettings -> WorkModel -> Category -> Html Msg
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
        , class "rounded px-1 py-1 hover:bg-blue-100 dark:hover:bg-bluegray-600"
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


renderCatItems2 : UiSettings -> Model -> WorkModel -> List (Html Msg)
renderCatItems2 settings model wm =
    let
        cats =
            wm.filteredCats

        max =
            settings.searchMenuTagCatCount

        expLink =
            Util.ExpandCollapse.expandToggle2
                max
                (List.length cats)
                ToggleExpandCats

        cpsLink =
            Util.ExpandCollapse.collapseToggle2
                max
                (List.length cats)
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
        , class "dark:bg-bluegray-800 dark:text-bluegray-200 dark:border-bluegray-800 dark:bg-opacity-50"
        ]
        [ text (String.fromInt num)
        ]
