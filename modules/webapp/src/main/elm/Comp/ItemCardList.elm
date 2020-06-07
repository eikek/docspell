module Comp.ItemCardList exposing
    ( Model
    , Msg(..)
    , init
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
import Data.Icons as Icons
import Data.Items
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Ports
import Util.List
import Util.String
import Util.Time


type alias Model =
    { results : ItemLightList
    }


type Msg
    = SetResults ItemLightList
    | AddResults ItemLightList
    | SelectItem ItemLight


init : Model
init =
    { results = Api.Model.ItemLightList.empty
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


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Maybe ItemLight )
update _ msg model =
    case msg of
        SetResults list ->
            let
                newModel =
                    { model | results = list }
            in
            ( newModel, Cmd.none, Nothing )

        AddResults list ->
            if list.groups == [] then
                ( model, Cmd.none, Nothing )

            else
                let
                    firstNew =
                        Data.Items.first list

                    scrollCmd =
                        case firstNew of
                            Just item ->
                                Ports.scrollToElem item.id

                            Nothing ->
                                Cmd.none

                    newModel =
                        { model | results = Data.Items.concat model.results list }
                in
                ( newModel, scrollCmd, Nothing )

        SelectItem item ->
            ( model, Cmd.none, Just item )



--- View


view : UiSettings -> Model -> Html Msg
view settings model =
    div [ class "ui container" ]
        (List.map (viewGroup settings) model.results.groups)


viewGroup : UiSettings -> ItemLightGroup -> Html Msg
viewGroup settings group =
    div [ class "item-group" ]
        [ div [ class "ui horizontal divider header item-list" ]
            [ i [ class "calendar alternate outline icon" ] []
            , text group.name
            ]
        , div [ class "ui stackable three cards" ]
            (List.map (viewItem settings) group.items)
        ]


viewItem : UiSettings -> ItemLight -> Html Msg
viewItem settings item =
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

        dueDate =
            Maybe.map Util.Time.formatDateShort item.dueDate
                |> Maybe.withDefault ""

        isConfirmed =
            item.state /= "created"

        newColor =
            "blue"
    in
    a
        [ classList
            [ ( "ui fluid card", True )
            , ( newColor, not isConfirmed )
            ]
        , id item.id
        , href "#"
        , onClick (SelectItem item)
        ]
        [ div [ class "content" ]
            [ div
                [ class "header"
                , Data.Direction.labelFromMaybe item.direction
                    |> title
                ]
                [ dirIcon
                , Util.String.underscoreToSpace item.name
                    |> text
                ]
            , div [ class "meta" ]
                [ div
                    [ classList
                        [ ( "ui ribbon label", True )
                        , ( newColor, True )
                        , ( "invisible", isConfirmed )
                        ]
                    ]
                    [ i [ class "exclamation icon" ] []
                    , text " New"
                    ]
                , span
                    [ classList
                        [ ( "right floated", not isConfirmed )
                        ]
                    ]
                    [ Util.Time.formatDate item.date |> text
                    ]
                ]
            , div [ class "meta description" ]
                [ div
                    [ classList
                        [ ( "ui right floated tiny labels", True )
                        , ( "invisible hidden", item.tags == [] )
                        ]
                    ]
                    (List.map
                        (\tag ->
                            div
                                [ classList
                                    [ ( "ui basic label", True )
                                    , ( Data.UiSettings.tagColorString tag settings, True )
                                    ]
                                ]
                                [ text tag.name ]
                        )
                        item.tags
                    )
                ]
            ]
        , div [ class "content" ]
            [ div [ class "ui horizontal list" ]
                [ div
                    [ class "item"
                    , title "Correspondent"
                    ]
                    [ Icons.correspondentIcon
                    , text " "
                    , Util.String.withDefault "-" corr |> text
                    ]
                , div
                    [ class "item"
                    , title "Concerning"
                    ]
                    [ Icons.concernedIcon
                    , text " "
                    , Util.String.withDefault "-" conc |> text
                    ]
                ]
            , div [ class "right floated meta" ]
                [ div [ class "ui horizontal list" ]
                    [ div
                        [ class "item"
                        , title "Source"
                        ]
                        [ text item.source
                        ]
                    , div
                        [ classList
                            [ ( "item", True )
                            , ( "invisible hidden", item.dueDate == Nothing )
                            ]
                        , title ("Due on " ++ dueDate)
                        ]
                        [ div
                            [ class "ui basic grey label"
                            ]
                            [ Icons.dueDateIcon
                            , text (" " ++ dueDate)
                            ]
                        ]
                    ]
                ]
            ]
        ]
