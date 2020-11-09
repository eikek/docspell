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

import Api
import Api.Model.HighlightEntry exposing (HighlightEntry)
import Api.Model.ItemLight exposing (ItemLight)
import Api.Model.ItemLightGroup exposing (ItemLightGroup)
import Api.Model.ItemLightList exposing (ItemLightList)
import Data.Direction
import Data.Fields
import Data.Flags exposing (Flags)
import Data.Icons as Icons
import Data.ItemSelection exposing (ItemSelection)
import Data.Items
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Markdown
import Page exposing (Page(..))
import Set exposing (Set)
import Util.Html
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
    | ItemDDMsg DD.Msg
    | ToggleSelectItem (Set String) String


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

        ItemDDMsg lm ->
            let
                ddd =
                    DD.update lm dm
            in
            UpdateResult model Cmd.none ddd.model Data.ItemSelection.Inactive

        ToggleSelectItem ids id ->
            let
                newSet =
                    if Set.member id ids then
                        Set.remove id ids

                    else
                        Set.insert id ids
            in
            UpdateResult model Cmd.none dm (Data.ItemSelection.Active newSet)



--- View


type alias ViewConfig =
    { current : Maybe String
    , selection : ItemSelection
    }


isSelected : ViewConfig -> String -> Bool
isSelected cfg id =
    case cfg.selection of
        Data.ItemSelection.Active ids ->
            Set.member id ids

        Data.ItemSelection.Inactive ->
            False


view : ViewConfig -> UiSettings -> Model -> Html Msg
view cfg settings model =
    div [ class "ui container" ]
        (List.map (viewGroup cfg settings) model.results.groups)


viewGroup : ViewConfig -> UiSettings -> ItemLightGroup -> Html Msg
viewGroup cfg settings group =
    div [ class "item-group" ]
        [ div [ class "ui horizontal divider header item-list" ]
            [ i [ class "calendar alternate outline icon" ] []
            , text group.name
            ]
        , div [ class "ui stackable three cards" ]
            (List.map (viewItem cfg settings) group.items)
        ]


viewItem : ViewConfig -> UiSettings -> ItemLight -> Html Msg
viewItem cfg settings item =
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

        cardColor =
            if isSelected cfg item.id then
                "purple"

            else if not isConfirmed then
                "blue"

            else
                ""

        fieldHidden f =
            Data.UiSettings.fieldHidden settings f

        cardAction =
            case cfg.selection of
                Data.ItemSelection.Inactive ->
                    Page.href (ItemDetailPage item.id)

                Data.ItemSelection.Active ids ->
                    onClick (ToggleSelectItem ids item.id)
    in
    a
        ([ classList
            [ ( "ui fluid card", True )
            , ( cardColor, True )
            , ( "current", cfg.current == Just item.id )
            ]
         , id item.id
         , href "#"
         , cardAction
         ]
            ++ DD.draggable ItemDDMsg item.id
        )
        [ if fieldHidden Data.Fields.PreviewImage then
            span [ class "invisible" ] []

          else
            div [ class "image" ]
                [ img
                    [ class "preview-image"
                    , src (Api.itemPreviewURL item.id)
                    , Data.UiSettings.cardPreviewSize settings
                    ]
                    []
                ]
        , div [ class "content" ]
            [ case cfg.selection of
                Data.ItemSelection.Active ids ->
                    div [ class "header" ]
                        [ Util.Html.checkbox (Set.member item.id ids)
                        , dirIcon
                        , Util.String.underscoreToSpace item.name
                            |> text
                        ]

                Data.ItemSelection.Inactive ->
                    if fieldHidden Data.Fields.Direction then
                        div [ class "header" ]
                            [ Util.String.underscoreToSpace item.name |> text
                            ]

                    else
                        div
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
                    , ( cardColor, True )
                    , ( "invisible", isConfirmed )
                    ]
                , title "New"
                ]
                [ i [ class "exclamation icon" ] []
                ]
            , div
                [ classList
                    [ ( "meta", True )
                    , ( "invisible hidden", fieldHidden Data.Fields.Date )
                    ]
                ]
                [ Util.Time.formatDate item.date |> text
                ]
            , div [ class "meta description" ]
                [ div
                    [ classList
                        [ ( "ui right floated tiny labels", True )
                        , ( "invisible hidden", item.tags == [] || fieldHidden Data.Fields.Tag )
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
                    [ classList
                        [ ( "item", True )
                        , ( "invisible hidden"
                          , fieldHidden Data.Fields.CorrOrg
                                && fieldHidden Data.Fields.CorrPerson
                          )
                        ]
                    , title "Correspondent"
                    ]
                    [ Icons.correspondentIcon ""
                    , text " "
                    , Util.String.withDefault "-" corr |> text
                    ]
                , div
                    [ classList
                        [ ( "item", True )
                        , ( "invisible hidden"
                          , fieldHidden Data.Fields.ConcPerson
                                && fieldHidden Data.Fields.ConcEquip
                          )
                        ]
                    , title "Concerning"
                    ]
                    [ Icons.concernedIcon
                    , text " "
                    , Util.String.withDefault "-" conc |> text
                    ]
                , div
                    [ classList
                        [ ( "item", True )
                        , ( "invisible hidden", fieldHidden Data.Fields.Folder )
                        ]
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
                            , ( "invisible hidden"
                              , item.dueDate
                                    == Nothing
                                    || fieldHidden Data.Fields.DueDate
                              )
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
