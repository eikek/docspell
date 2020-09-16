module Comp.ItemCardList exposing
    ( Model
    , Msg(..)
    , init
    , nextItem
    , prevItem
    , update
    , updateDrag
    , view
    )

import Api.Model.HighlightEntry exposing (HighlightEntry)
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
import Markdown
import Util.ItemDragDrop as DD
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
    | ItemDDMsg DD.Msg


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
update flags msg model =
    let
        res =
            updateDrag DD.init flags msg model
    in
    ( res.model, res.cmd, res.selected )


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , selected : Maybe ItemLight
    , dragModel : DD.Model
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
            UpdateResult newModel Cmd.none Nothing dm

        AddResults list ->
            if list.groups == [] then
                UpdateResult model Cmd.none Nothing dm

            else
                let
                    newModel =
                        { model | results = Data.Items.concat model.results list }
                in
                UpdateResult newModel Cmd.none Nothing dm

        SelectItem item ->
            UpdateResult model Cmd.none (Just item) dm

        ItemDDMsg lm ->
            let
                ddd =
                    DD.update lm dm
            in
            UpdateResult model Cmd.none Nothing ddd.model



--- View


view : Maybe String -> UiSettings -> Model -> Html Msg
view current settings model =
    div [ class "ui container" ]
        (List.map (viewGroup current settings) model.results.groups)


viewGroup : Maybe String -> UiSettings -> ItemLightGroup -> Html Msg
viewGroup current settings group =
    div [ class "item-group" ]
        [ div [ class "ui horizontal divider header item-list" ]
            [ i [ class "calendar alternate outline icon" ] []
            , text group.name
            ]
        , div [ class "ui stackable three cards" ]
            (List.map (viewItem current settings) group.items)
        ]


viewItem : Maybe String -> UiSettings -> ItemLight -> Html Msg
viewItem current settings item =
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

        folder =
            Maybe.map .name item.folder
                |> Maybe.withDefault ""

        dueDate =
            Maybe.map Util.Time.formatDateShort item.dueDate
                |> Maybe.withDefault ""

        isConfirmed =
            item.state /= "created"

        newColor =
            "blue"
    in
    a
        ([ classList
            [ ( "ui fluid card", True )
            , ( newColor, not isConfirmed )
            , ( "current", current == Just item.id )
            ]
         , id item.id
         , href "#"
         , onClick (SelectItem item)
         ]
            ++ DD.draggable ItemDDMsg item.id
        )
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
            , div
                [ classList
                    [ ( "ui right corner label", True )
                    , ( newColor, True )
                    , ( "invisible", isConfirmed )
                    ]
                , title "New"
                ]
                [ i [ class "exclamation icon" ] []
                ]
            , div [ class "meta" ]
                [ span []
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
        , div
            [ classList
                [ ( "content", True )
                , ( "invisible hidden"
                  , settings.itemSearchNoteLength
                        <= 0
                        || Util.String.isNothingOrBlank item.notes
                  )
                ]
            ]
            [ span [ class "small-info" ]
                [ Maybe.withDefault "" item.notes
                    |> Util.String.ellipsis settings.itemSearchNoteLength
                    |> text
                ]
            ]
        , div [ class "content" ]
            [ div [ class "ui horizontal list" ]
                [ div
                    [ class "item"
                    , title "Correspondent"
                    ]
                    [ Icons.correspondentIcon ""
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
                , div
                    [ class "item"
                    , title "Folder"
                    ]
                    [ Icons.folderIcon ""
                    , text " "
                    , Util.String.withDefault "-" folder |> text
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
                            [ Icons.dueDateIcon ""
                            , text (" " ++ dueDate)
                            ]
                        ]
                    ]
                ]
            ]
        , div
            [ classList
                [ ( "content search-highlight", True )
                , ( "invisible hidden", item.highlighting == [] )
                ]
            ]
            [ div [ class "ui list" ]
                (List.map renderHighlightEntry item.highlighting)
            ]
        ]


renderHighlightEntry : HighlightEntry -> Html Msg
renderHighlightEntry entry =
    let
        stripWhitespace str =
            String.trim str
                |> String.replace "```" ""
                |> String.replace "\t" "  "
                |> String.replace "\n\n" "\n"
                |> String.lines
                |> List.map String.trim
                |> String.join "\n"
    in
    div [ class "item" ]
        [ div [ class "content" ]
            (div [ class "header" ]
                [ i [ class "caret right icon" ] []
                , text (entry.name ++ ":")
                ]
                :: List.map
                    (\str ->
                        Markdown.toHtml [ class "description" ] <|
                            (stripWhitespace str ++ "…")
                    )
                    entry.lines
            )
        ]
