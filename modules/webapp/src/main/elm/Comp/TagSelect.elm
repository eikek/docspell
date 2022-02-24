{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.TagSelect exposing (Model, Msg, Selection, emptySelection, init, initAll, initCounts, reset, toggleTag, update, view, viewCats, viewTags)

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
import Set exposing (Set)
import Simple.Fuzzy
import String as S
import Styles as S
import Util.ItemDragDrop as DD
import Util.Maybe


type alias Model =
    { availableTags : List Tag
    , availableCats : List String
    , filteredCats : List String
    , filteredTags : List Tag
    , tagCounts : Dict String Int
    , catCounts : Dict String Int
    , filterTerm : Maybe String
    , expandedTags : Bool
    , expandedCats : Bool
    , showEmpty : Bool
    }


emptyModel : Model
emptyModel =
    { availableTags = []
    , availableCats = []
    , filteredCats = []
    , filteredTags = []
    , tagCounts = Dict.empty
    , catCounts = Dict.empty
    , filterTerm = Nothing
    , expandedTags = False
    , expandedCats = False
    , showEmpty = True
    }


type Msg
    = ToggleTag String
    | ToggleCat String
    | ToggleExpandTags
    | ToggleExpandCats
    | ToggleShowEmpty
    | TagDDMsg DD.Msg
    | Search String


type alias Selection =
    { includeTags : Set String
    , excludeTags : Set String
    , includeCats : Set String
    , excludeCats : Set String
    }


type SelState
    = Include
    | Exclude
    | Deselect


emptySelection : Selection
emptySelection =
    Selection Set.empty Set.empty Set.empty Set.empty


init : List TagCount -> List NameCount -> Model
init allTags allCats =
    initAll allTags allCats emptyModel


initAll : List TagCount -> List NameCount -> Model -> Model
initAll allTags allCats model =
    model
        |> initAvailable allTags allCats
        |> initCounts allTags allCats
        |> applyFilter


initAvailable : List TagCount -> List NameCount -> Model -> Model
initAvailable allTags allCats model =
    let
        tags =
            List.sortBy (.count >> negate) allTags
                |> List.map .tag

        cats =
            List.sortBy (.count >> negate) allCats
                |> List.filterMap .name
    in
    { model
        | availableTags = tags
        , availableCats = cats
        , filteredTags = tags
        , filteredCats = cats
    }


initCounts : List TagCount -> List NameCount -> Model -> Model
initCounts tags cats model =
    let
        tc =
            List.map (\t -> ( t.tag.id, t.count )) tags |> Dict.fromList

        cc =
            List.map (\c -> ( Maybe.withDefault "" c.name, c.count )) cats |> Dict.fromList
    in
    { model | tagCounts = tc, catCounts = cc }


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


{-| Goes from included -> excluded -> deselected
-}
updateTagSelection : String -> Selection -> Selection
updateTagSelection id sel =
    case tagState sel id of
        Include ->
            { sel
                | includeTags = Set.remove id sel.includeTags
                , excludeTags = Set.insert id sel.excludeTags
            }

        Exclude ->
            { sel
                | includeTags = Set.remove id sel.includeTags
                , excludeTags = Set.remove id sel.excludeTags
            }

        Deselect ->
            { sel
                | includeTags = Set.insert id sel.includeTags
            }


{-| Goes from included -> excluded -> deselected
-}
updateCatSelection : String -> Selection -> Selection
updateCatSelection id sel =
    case catState sel id of
        Include ->
            { sel
                | includeCats = Set.remove id sel.includeCats
                , excludeCats = Set.insert id sel.excludeCats
            }

        Exclude ->
            { sel
                | includeCats = Set.remove id sel.includeCats
                , excludeCats = Set.remove id sel.excludeCats
            }

        Deselect ->
            { sel
                | includeCats = Set.insert id sel.includeCats
            }


tagFilter : Model -> Tag -> Bool
tagFilter model tag =
    let
        showIfEmpty =
            model.showEmpty || ((Dict.get tag.id model.tagCounts |> Maybe.withDefault 0) > 0)
    in
    case model.filterTerm of
        Just f ->
            Simple.Fuzzy.match f tag.name && showIfEmpty

        Nothing ->
            showIfEmpty


catFilter : Model -> String -> Bool
catFilter model cat =
    let
        showIfEmpty =
            model.showEmpty || ((Dict.get cat model.catCounts |> Maybe.withDefault 0) > 0)
    in
    case model.filterTerm of
        Just f ->
            Simple.Fuzzy.match f cat && showIfEmpty

        Nothing ->
            showIfEmpty


applyFilter : Model -> Model
applyFilter model =
    { model
        | filteredTags = List.filter (tagFilter model) model.availableTags
        , filteredCats = List.filter (catFilter model) model.availableCats
    }



--- Update


update : DD.Model -> Selection -> Msg -> Model -> ( Model, Selection, DD.DragDropData )
update ddm sel msg model =
    case msg of
        ToggleShowEmpty ->
            ( applyFilter { model | showEmpty = not model.showEmpty }
            , sel
            , DD.DragDropData ddm Nothing
            )

        ToggleTag id ->
            let
                next =
                    updateTagSelection id sel
            in
            ( model, next, DD.DragDropData ddm Nothing )

        ToggleCat name ->
            let
                next =
                    updateCatSelection name sel
            in
            ( model, next, DD.DragDropData ddm Nothing )

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
            ( applyFilter { model | filterTerm = Util.Maybe.fromString str }
            , sel
            , DD.DragDropData ddm Nothing
            )



--- View


noEmptyTags : Model -> Bool
noEmptyTags model =
    let
        countGreaterThan num tag =
            Dict.get tag.name model.tagCounts
                |> Maybe.withDefault 0
                |> (>) num
    in
    List.all (countGreaterThan 0) model.availableTags


tagState : Selection -> String -> SelState
tagState model id =
    if Set.member id model.includeTags then
        Include

    else if Set.member id model.excludeTags then
        Exclude

    else
        Deselect


catState : Selection -> String -> SelState
catState model name =
    if Set.member name model.includeCats then
        Include

    else if Set.member name model.excludeCats then
        Exclude

    else
        Deselect


view : Texts -> DD.Model -> UiSettings -> Selection -> Model -> List (Html Msg)
view texts ddm settings sel model =
    viewTags texts ddm settings sel model ++ [ viewCats texts settings sel model ]


viewTags : Texts -> DD.Model -> UiSettings -> Selection -> Model -> List (Html Msg)
viewTags texts ddm settings sel model =
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
        (renderTagItems texts ddm settings model sel)
    ]


viewCats : Texts -> UiSettings -> Selection -> Model -> Html Msg
viewCats texts settings sel model =
    div [ class "flex flex-col" ]
        [ div [ class "flex flex-col space-y-2 md:space-y-1" ]
            (renderCatItems texts settings model sel)
        ]


renderTagItems : Texts -> DD.Model -> UiSettings -> Model -> Selection -> List (Html Msg)
renderTagItems texts ddm settings model sel =
    let
        tags =
            model.filteredTags

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
        List.map (viewTagItem ddm settings sel model) tags

    else if model.expandedTags then
        List.map (viewTagItem ddm settings sel model) tags ++ cpsLink

    else
        List.map (viewTagItem ddm settings sel model) (List.take max tags) ++ expLink


viewTagItem : DD.Model -> UiSettings -> Selection -> Model -> Tag -> Html Msg
viewTagItem ddm settings sel model tag =
    let
        state =
            tagState sel tag.id

        color =
            Data.UiSettings.tagColorFg2 tag settings

        icon =
            getIcon state color I.tagIcon

        dropActive =
            DD.getDropId ddm == Just (DD.Tag tag.id)
    in
    a
        ([ classList
            [ ( "bg-blue-100 dark:bg-slate-600", dropActive )
            ]
         , class "flex flex-row items-center"
         , class "rounded px-1 py-1 hover:bg-blue-100 dark:hover:bg-slate-600"
         , href "#"
         , onClick (ToggleTag tag.id)
         ]
            ++ DD.droppable TagDDMsg (DD.Tag tag.id)
        )
        [ icon
        , div
            [ classList
                [ ( "font-semibold", state == Include )
                , ( "", state /= Include )
                ]
            , class "ml-2"
            ]
            [ text tag.name
            ]
        , div [ class "flex-grow" ] []
        , numberLabel <| Maybe.withDefault 0 (Dict.get tag.id model.tagCounts)
        ]


viewCategoryItem : UiSettings -> Selection -> Model -> String -> Html Msg
viewCategoryItem settings sel model cat =
    let
        state =
            catState sel cat

        color =
            Data.UiSettings.catColorFg2 settings cat

        icon =
            getIcon state color I.tagsIcon
    in
    a
        [ class "flex flex-row items-center"
        , class "rounded px-1 py-1 hover:bg-blue-100 dark:hover:bg-slate-600"
        , href "#"
        , onClick (ToggleCat cat)
        ]
        [ icon
        , div
            [ classList
                [ ( "font-semibold", state == Include )
                , ( "", state /= Include )
                ]
            , class "ml-2"
            ]
            [ text cat
            ]
        , div [ class "flex-grow" ] []
        , numberLabel <| Maybe.withDefault 0 (Dict.get cat model.catCounts)
        ]


renderCatItems : Texts -> UiSettings -> Model -> Selection -> List (Html Msg)
renderCatItems texts settings model sel =
    let
        cats =
            model.filteredCats

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
        List.map (viewCategoryItem settings sel model) cats

    else if model.expandedCats then
        List.map (viewCategoryItem settings sel model) cats ++ cpsLink

    else
        List.map (viewCategoryItem settings sel model) (List.take max cats) ++ expLink


getIcon : SelState -> String -> (String -> Html msg) -> Html msg
getIcon state color default =
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
