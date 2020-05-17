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
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Util.List
import Util.String
import Util.Time


type alias Model =
    { results : ItemLightList
    }


type Msg
    = SetResults ItemLightList
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

        SelectItem item ->
            ( model, Cmd.none, Just item )



--- View


view : Model -> Html Msg
view model =
    div [ class "ui container" ]
        (List.map viewGroup model.results.groups)


viewGroup : ItemLightGroup -> Html Msg
viewGroup group =
    div [ class "item-group" ]
        [ div [ class "ui horizontal divider" ]
            [ text group.name
            ]
        , div [ class "ui one column grid" ]
            (List.map viewItem group.items)
        ]


viewItem : ItemLight -> Html Msg
viewItem item =
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
    div [ class "column item-list" ]
        [ a
            [ classList
                [ ( "ui fluid card", True )
                , ( newColor, not isConfirmed )
                ]
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
                    , Util.String.ellipsis 45 item.name |> text
                    ]
                , span [ class "meta" ]
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
                    ]
                , span [ class "right floated meta" ]
                    [ Util.Time.formatDateShort item.date |> text
                    ]
                ]
            , div [ class "content" ]
                [ div [ class "ui horizontal list" ]
                    [ div
                        [ class "item"
                        , title "Correspondent"
                        ]
                        [ i [ class "envelope outline icon" ] []
                        , text " "
                        , Util.String.withDefault "-" corr |> text
                        ]
                    , div
                        [ class "item"
                        , title "Concerning"
                        ]
                        [ i [ class "comment outline icon" ] []
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
                            [ class "item"
                            , title ("Due on " ++ dueDate)
                            ]
                            [ div
                                [ classList
                                    [ ( "ui basic grey label", True )
                                    , ( "invisible hidden", item.dueDate == Nothing )
                                    ]
                                ]
                                [ i [ class "bell icon" ] []
                                , text (" " ++ dueDate)
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
