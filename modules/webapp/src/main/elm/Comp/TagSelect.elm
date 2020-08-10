module Comp.TagSelect exposing
    ( Category
    , Model
    , Msg
    , Selection
    , emptySelection
    , init
    , update
    , updateDrop
    , viewCats
    , viewTags
    , viewTagsDrop
    )

import Api.Model.TagCount exposing (TagCount)
import Data.Icons as I
import Data.UiSettings exposing (UiSettings)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Simple.Fuzzy
import Util.ExpandCollapse
import Util.ItemDragDrop as DD
import Util.String as S


type alias Model =
    { all : List TagCount
    , filteredTags : List TagCount
    , categories : List Category
    , filteredCats : List Category
    , selectedTags : Dict String Bool
    , selectedCats : Dict String Bool
    , expandedTags : Bool
    , expandedCats : Bool
    }


type alias Category =
    { name : String
    , count : Int
    }


init : Selection -> List TagCount -> Model
init sel tags =
    let
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

        cats =
            sumCategories tags
    in
    { all = tags
    , filteredTags = tags
    , categories = cats
    , filteredCats = cats
    , selectedTags = selTag
    , selectedCats = selCat
    , expandedTags = False
    , expandedCats = False
    }


sumCategories : List TagCount -> List Category
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
    Dict.toList cats
        |> List.map (\( n, c ) -> Category n c)



--- Update


type Msg
    = ToggleTag String
    | ToggleCat String
    | ToggleExpandTags
    | ToggleExpandCats
    | TagDDMsg DD.Msg
    | Search String


type alias Selection =
    { includeTags : List TagCount
    , excludeTags : List TagCount
    , includeCats : List Category
    , excludeCats : List Category
    }


emptySelection : Selection
emptySelection =
    Selection [] [] [] []


update : Msg -> Model -> ( Model, Selection )
update msg model =
    let
        ( m, s, _ ) =
            updateDrop DD.init msg model
    in
    ( m, s )


updateDrop : DD.Model -> Msg -> Model -> ( Model, Selection, DD.DragDropData )
updateDrop ddm msg model =
    case msg of
        ToggleTag id ->
            let
                next =
                    updateSelection id model.selectedTags

                model_ =
                    { model | selectedTags = next }
            in
            ( model_, getSelection model_, DD.DragDropData ddm Nothing )

        ToggleCat name ->
            let
                next =
                    updateSelection name model.selectedCats

                model_ =
                    { model | selectedCats = next }
            in
            ( model_, getSelection model_, DD.DragDropData ddm Nothing )

        ToggleExpandTags ->
            ( { model | expandedTags = not model.expandedTags }
            , getSelection model
            , DD.DragDropData ddm Nothing
            )

        ToggleExpandCats ->
            ( { model | expandedCats = not model.expandedCats }
            , getSelection model
            , DD.DragDropData ddm Nothing
            )

        TagDDMsg lm ->
            let
                ddd =
                    DD.update lm ddm
            in
            ( model, getSelection model, ddd )

        Search str ->
            let
                forTags t =
                    Simple.Fuzzy.match str t.tag.name

                forCats c =
                    Simple.Fuzzy.match str c.name
            in
            ( { model
                | filteredTags =
                    if S.isBlank str then
                        model.all

                    else
                        List.filter forTags model.all
                , filteredCats =
                    if S.isBlank str then
                        model.categories

                    else
                        List.filter forCats model.categories
              }
            , getSelection model
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


getSelection : Model -> Selection
getSelection model =
    let
        ( inclTags, exclTags ) =
            getSelection1 (\t -> t.tag.id) model.selectedTags model.all

        ( inclCats, exclCats ) =
            getSelection1 (\c -> c.name) model.selectedCats model.categories
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


tagState : Model -> String -> SelState
tagState model id =
    case Dict.get id model.selectedTags of
        Just True ->
            Include

        Just False ->
            Exclude

        Nothing ->
            Deselect


catState : Model -> String -> SelState
catState model name =
    case Dict.get name model.selectedCats of
        Just True ->
            Include

        Just False ->
            Exclude

        Nothing ->
            Deselect


viewTags : UiSettings -> Model -> Html Msg
viewTags =
    viewTagsDrop DD.init


viewTagsDrop : DD.Model -> UiSettings -> Model -> Html Msg
viewTagsDrop ddm settings model =
    div [ class "ui list" ]
        [ div [ class "item" ]
            [ I.tagIcon ""
            , div [ class "content" ]
                [ div [ class "header" ]
                    [ text "Tags"
                    , div [ class "ui small transparent icon right floated input width-70" ]
                        [ input
                            [ type_ "text"
                            , placeholder "Filter …"
                            , onInput Search
                            ]
                            []
                        , i [ class "search icon" ] []
                        ]
                    ]
                , div [ class "ui relaxed list" ]
                    (renderTagItems ddm settings model)
                ]
            ]
        ]


viewCats : UiSettings -> Model -> Html Msg
viewCats settings model =
    div [ class "ui list" ]
        [ div [ class "item" ]
            [ I.tagsIcon ""
            , div [ class "content" ]
                [ div [ class "header" ]
                    [ text "Categories"
                    ]
                , div [ class "ui relaxed list" ]
                    (renderCatItems settings model)
                ]
            ]
        ]


renderTagItems : DD.Model -> UiSettings -> Model -> List (Html Msg)
renderTagItems ddm settings model =
    let
        tags =
            model.filteredTags

        max =
            settings.searchMenuTagCount

        exp =
            Util.ExpandCollapse.expandToggle
                max
                (List.length tags)
                ToggleExpandTags

        cps =
            Util.ExpandCollapse.collapseToggle
                max
                (List.length tags)
                ToggleExpandTags
    in
    if max <= 0 then
        List.map (viewTagItem ddm settings model) tags

    else if model.expandedTags then
        List.map (viewTagItem ddm settings model) tags ++ cps

    else
        List.map (viewTagItem ddm settings model) (List.take max tags) ++ exp


renderCatItems : UiSettings -> Model -> List (Html Msg)
renderCatItems settings model =
    let
        cats =
            model.filteredCats

        max =
            settings.searchMenuTagCatCount

        exp =
            Util.ExpandCollapse.expandToggle
                max
                (List.length cats)
                ToggleExpandCats

        cps =
            Util.ExpandCollapse.collapseToggle
                max
                (List.length cats)
                ToggleExpandCats
    in
    if max <= 0 then
        List.map (viewCategoryItem settings model) cats

    else if model.expandedCats then
        List.map (viewCategoryItem settings model) cats ++ cps

    else
        List.map (viewCategoryItem settings model) (List.take max cats) ++ exp


viewCategoryItem : UiSettings -> Model -> Category -> Html Msg
viewCategoryItem settings model cat =
    let
        state =
            catState model cat.name

        color =
            Data.UiSettings.catColorString settings cat.name

        icon =
            getIcon state color I.tagsIcon
    in
    a
        [ class "item"
        , href "#"
        , onClick (ToggleCat cat.name)
        ]
        [ icon
        , div [ class "content" ]
            [ div
                [ classList
                    [ ( "header", state == Include )
                    , ( "description", state /= Include )
                    ]
                ]
                [ text cat.name
                , div [ class "ui right floated circular label" ]
                    [ text (String.fromInt cat.count)
                    ]
                ]
            ]
        ]


viewTagItem : DD.Model -> UiSettings -> Model -> TagCount -> Html Msg
viewTagItem ddm settings model tag =
    let
        state =
            tagState model tag.tag.id

        color =
            Data.UiSettings.tagColorString tag.tag settings

        icon =
            getIcon state color I.tagIcon

        dropActive =
            DD.getDropId ddm == Just (DD.Tag tag.tag.id)
    in
    a
        ([ classList
            [ ( "item", True )
            , ( "current-drop-target", dropActive )
            ]
         , href "#"
         , onClick (ToggleTag tag.tag.id)
         ]
            ++ DD.droppable TagDDMsg (DD.Tag tag.tag.id)
        )
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


getIcon : SelState -> String -> (String -> Html msg) -> Html msg
getIcon state color default =
    case state of
        Include ->
            i [ class ("check icon " ++ color) ] []

        Exclude ->
            i [ class ("minus icon " ++ color) ] []

        Deselect ->
            default color
