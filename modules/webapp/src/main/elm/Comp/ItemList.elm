module Comp.ItemList exposing
    ( Model
    , Msg(..)
    , emptyModel
    , nextItem
    , prevItem
    , update
    , view
    )

import Api.Model.ItemLight exposing (ItemLight)
import Api.Model.ItemLightGroup exposing (ItemLightGroup)
import Api.Model.ItemLightList exposing (ItemLightList)
import Data.Direction
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Set exposing (Set)
import Util.List
import Util.Maybe
import Util.String
import Util.Time


type alias Model =
    { results : ItemLightList
    , openGroups : Set String
    }


emptyModel : Model
emptyModel =
    { results = Api.Model.ItemLightList.empty
    , openGroups = Set.empty
    }


type Msg
    = SetResults ItemLightList
    | ToggleGroupState ItemLightGroup
    | CollapseAll
    | ExpandAll
    | SelectItem ItemLight


nextItem : Model -> String -> Maybe ItemLight
nextItem model id =
    List.concatMap .items model.results.groups
        |> Util.List.findNext (\i -> i.id == id)


prevItem : Model -> String -> Maybe ItemLight
prevItem model id =
    List.concatMap .items model.results.groups
        |> Util.List.findPrev (\i -> i.id == id)


openAllGroups : Model -> Set String
openAllGroups model =
    List.foldl
        (\g -> \set -> Set.insert g.name set)
        model.openGroups
        model.results.groups


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Maybe ItemLight )
update flags msg model =
    case msg of
        SetResults list ->
            let
                newModel =
                    { model | results = list, openGroups = Set.empty }
            in
            ( { newModel | openGroups = openAllGroups newModel }, Cmd.none, Nothing )

        ToggleGroupState group ->
            let
                m2 =
                    if isGroupOpen model group then
                        closeGroup model group

                    else
                        openGroup model group
            in
            ( m2, Cmd.none, Nothing )

        CollapseAll ->
            ( { model | openGroups = Set.empty }, Cmd.none, Nothing )

        ExpandAll ->
            let
                open =
                    openAllGroups model
            in
            ( { model | openGroups = open }, Cmd.none, Nothing )

        SelectItem item ->
            ( model, Cmd.none, Just item )


view : Model -> Html Msg
view model =
    div []
        [ div [ class "ui ablue-comp menu" ]
            [ div [ class "right floated menu" ]
                [ a
                    [ class "item"
                    , title "Expand all"
                    , onClick ExpandAll
                    , href ""
                    ]
                    [ i [ class "double angle down icon" ] []
                    ]
                , a
                    [ class "item"
                    , title "Collapse all"
                    , onClick CollapseAll
                    , href ""
                    ]
                    [ i [ class "double angle up icon" ] []
                    ]
                ]
            ]
        , div [ class "ui middle aligned very relaxed divided basic list segment" ]
            (List.map (viewGroup model) model.results.groups)
        ]


isGroupOpen : Model -> ItemLightGroup -> Bool
isGroupOpen model group =
    Set.member group.name model.openGroups


openGroup : Model -> ItemLightGroup -> Model
openGroup model group =
    { model | openGroups = Set.insert group.name model.openGroups }


closeGroup : Model -> ItemLightGroup -> Model
closeGroup model group =
    { model | openGroups = Set.remove group.name model.openGroups }


viewGroup : Model -> ItemLightGroup -> Html Msg
viewGroup model group =
    let
        groupOpen =
            isGroupOpen model group

        children =
            [ i
                [ classList
                    [ ( "large middle aligned icon", True )
                    , ( "caret right", not groupOpen )
                    , ( "caret down", groupOpen )
                    ]
                ]
                []
            , div [ class "content" ]
                [ div [ class "right floated content" ]
                    [ div [ class "ui blue label" ]
                        [ List.length group.items |> String.fromInt |> text
                        ]
                    ]
                , a
                    [ class "header"
                    , onClick (ToggleGroupState group)
                    , href ""
                    ]
                    [ text group.name
                    ]
                , div [ class "description" ]
                    [ makeSummary group |> text
                    ]
                ]
            ]

        itemTable =
            div [ class "ui basic content segment no-margin" ]
                [ renderItemTable model group.items
                ]
    in
    if isGroupOpen model group then
        div [ class "item" ]
            (List.append children [ itemTable ])

    else
        div [ class "item" ]
            children


renderItemTable : Model -> List ItemLight -> Html Msg
renderItemTable model items =
    table [ class "ui selectable padded table" ]
        [ thead []
            [ tr []
                [ th [ class "collapsing" ] []
                , th [ class "collapsing" ] [ text "Name" ]
                , th [ class "collapsing" ] [ text "Date" ]
                , th [ class "collapsing" ] [ text "Source" ]
                , th [] [ text "Correspondent" ]
                , th [] [ text "Concerning" ]
                ]
            ]
        , tbody []
            (List.map (renderItemLine model) items)
        ]


renderItemLine : Model -> ItemLight -> Html Msg
renderItemLine model item =
    let
        dirIcon =
            i [ class (Data.Direction.iconFromMaybe item.direction) ] []

        corr =
            List.filterMap identity [ item.corrOrg, item.corrPerson ]
                |> List.map .name
                |> List.intersperse ", "
                |> String.concat

        conc =
            List.filterMap identity [ item.concPerson, item.concEquip ]
                |> List.map .name
                |> List.intersperse ", "
                |> String.concat
    in
    tr [ onClick (SelectItem item) ]
        [ td [ class "collapsing" ]
            [ div
                [ classList
                    [ ( "ui teal ribbon label", True )
                    , ( "invisible", item.state /= "created" )
                    ]
                ]
                [ text "New"
                ]
            ]
        , td [ class "collapsing" ]
            [ dirIcon
            , Util.String.ellipsis 45 item.name |> text
            ]
        , td [ class "collapsing" ]
            [ Util.Time.formatDateShort item.date |> text
            , span
                [ classList
                    [ ( "invisible", Util.Maybe.isEmpty item.dueDate )
                    ]
                ]
                [ text " "
                , div [ class "ui basic label" ]
                    [ i [ class "bell icon" ] []
                    , Maybe.map Util.Time.formatDateShort item.dueDate |> Maybe.withDefault "" |> text
                    ]
                ]
            ]
        , td [ class "collapsing" ] [ text item.source ]
        , td [] [ text corr ]
        , td [] [ text conc ]
        ]


makeSummary : ItemLightGroup -> String
makeSummary group =
    let
        corrOrgs =
            List.filterMap .corrOrg group.items

        corrPers =
            List.filterMap .corrPerson group.items

        concPers =
            List.filterMap .concPerson group.items

        concEqui =
            List.filterMap .concEquip group.items

        all =
            List.concat [ corrOrgs, corrPers, concPers, concEqui ]
    in
    List.map .name all
        |> Util.List.distinct
        |> List.intersperse ", "
        |> String.concat
