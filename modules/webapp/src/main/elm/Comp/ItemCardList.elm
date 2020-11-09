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

import Api.Model.ItemLight exposing (ItemLight)
import Api.Model.ItemLightGroup exposing (ItemLightGroup)
import Api.Model.ItemLightList exposing (ItemLightList)
import Comp.ItemCard
import Data.Flags exposing (Flags)
import Data.ItemSelection exposing (ItemSelection)
import Data.Items
import Data.UiSettings exposing (UiSettings)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Page exposing (Page(..))
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
            UpdateResult newModel Cmd.none dm Data.ItemSelection.Inactive

        AddResults list ->
            if list.groups == [] then
                UpdateResult model Cmd.none dm Data.ItemSelection.Inactive

            else
                let
                    newModel =
                        { model | results = Data.Items.concat model.results list }
                in
                UpdateResult newModel Cmd.none dm Data.ItemSelection.Inactive

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



--- View


type alias ViewConfig =
    { current : Maybe String
    , selection : ItemSelection
    }


view : ViewConfig -> UiSettings -> Model -> Html Msg
view cfg settings model =
    div [ class "ui container" ]
        (List.map (viewGroup model cfg settings) model.results.groups)


viewGroup : Model -> ViewConfig -> UiSettings -> ItemLightGroup -> Html Msg
viewGroup model cfg settings group =
    div [ class "item-group" ]
        [ div [ class "ui horizontal divider header item-list" ]
            [ i [ class "calendar alternate outline icon" ] []
            , text group.name
            ]
        , div [ class "ui stackable three cards" ]
            (List.map (viewItem model cfg settings) group.items)
        ]


viewItem : Model -> ViewConfig -> UiSettings -> ItemLight -> Html Msg
viewItem model cfg settings item =
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
            Comp.ItemCard.view vvcfg settings cardModel item
    in
    Html.map (ItemCardMsg item) cardHtml
