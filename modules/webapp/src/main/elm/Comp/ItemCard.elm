module Comp.ItemCard exposing
    ( Model
    , Msg
    , UpdateResult
    , ViewConfig
    , init
    , update
    , view
    )

import Api
import Api.Model.AttachmentLight exposing (AttachmentLight)
import Api.Model.HighlightEntry exposing (HighlightEntry)
import Api.Model.ItemLight exposing (ItemLight)
import Comp.LinkTarget exposing (LinkTarget(..))
import Data.Direction
import Data.Fields
import Data.Icons as Icons
import Data.ItemSelection exposing (ItemSelection)
import Data.ItemTemplate as IT
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Markdown
import Page exposing (Page(..))
import Set exposing (Set)
import Util.CustomField
import Util.ItemDragDrop as DD
import Util.List
import Util.Maybe
import Util.String


type alias Model =
    { previewAttach : Maybe AttachmentLight
    }


type Msg
    = CyclePreview ItemLight
    | ToggleSelectItem (Set String) String
    | ItemDDMsg DD.Msg
    | SetLinkTarget LinkTarget


type alias ViewConfig =
    { selection : ItemSelection
    , extraClasses : String
    }


type alias UpdateResult =
    { model : Model
    , dragModel : DD.Model
    , selection : ItemSelection
    , linkTarget : LinkTarget
    }


init : Model
init =
    { previewAttach = Nothing
    }


currentAttachment : Model -> ItemLight -> Maybe AttachmentLight
currentAttachment model item =
    Util.Maybe.or
        [ model.previewAttach
        , List.head item.attachments
        ]


currentPosition : Model -> ItemLight -> Int
currentPosition model item =
    let
        filter cur el =
            cur.id == el.id
    in
    case model.previewAttach of
        Just a ->
            case Util.List.findIndexed (filter a) item.attachments of
                Just ( _, n ) ->
                    n + 1

                Nothing ->
                    1

        Nothing ->
            1


update : DD.Model -> Msg -> Model -> UpdateResult
update ddm msg model =
    case msg of
        ItemDDMsg lm ->
            let
                ddd =
                    DD.update lm ddm
            in
            UpdateResult model ddd.model Data.ItemSelection.Inactive LinkNone

        ToggleSelectItem ids id ->
            let
                newSet =
                    if Set.member id ids then
                        Set.remove id ids

                    else
                        Set.insert id ids
            in
            UpdateResult model ddm (Data.ItemSelection.Active newSet) LinkNone

        CyclePreview item ->
            let
                mainAttach =
                    currentAttachment model item

                next =
                    Util.List.findNext (\e -> Just e.id == Maybe.map .id mainAttach) item.attachments
            in
            UpdateResult { model | previewAttach = next }
                ddm
                Data.ItemSelection.Inactive
                LinkNone

        SetLinkTarget target ->
            UpdateResult model ddm Data.ItemSelection.Inactive target


view : ViewConfig -> UiSettings -> Model -> ItemLight -> Html Msg
view cfg settings model item =
    let
        isConfirmed =
            item.state /= "created"

        cardColor =
            if not isConfirmed then
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

        selectedDimmer =
            div
                [ classList
                    [ ( "ui light dimmer", True )
                    , ( "active", isSelected cfg item.id )
                    ]
                ]
                [ div [ class "content" ]
                    [ a
                        [ cardAction
                        ]
                        [ i [ class "huge icons purple" ]
                            [ i [ class "big circle outline icon" ] []
                            , i [ class "check icon" ] []
                            ]
                        ]
                    ]
                ]
    in
    div
        ([ classList
            [ ( "ui fluid card", True )
            , ( cardColor, True )
            , ( cfg.extraClasses, True )
            ]
         , id item.id
         ]
            ++ DD.draggable ItemDDMsg item.id
        )
        ((if fieldHidden Data.Fields.PreviewImage then
            []

          else
            [ selectedDimmer
            , previewMenu settings model item (currentAttachment model item)
            , previewImage settings cardAction model item
            ]
         )
            ++ [ mainContent cardAction cardColor isConfirmed settings cfg item
               , notesContent settings item
               , metaDataContent settings item
               , fulltextResultsContent item
               ]
        )


fulltextResultsContent : ItemLight -> Html Msg
fulltextResultsContent item =
    div
        [ classList
            [ ( "content search-highlight", True )
            , ( "invisible hidden", item.highlighting == [] )
            ]
        ]
        [ div [ class "ui list" ]
            (List.map renderHighlightEntry item.highlighting)
        ]


metaDataContent : UiSettings -> ItemLight -> Html Msg
metaDataContent settings item =
    let
        fieldHidden f =
            Data.UiSettings.fieldHidden settings f

        dueDate =
            IT.render IT.dueDateShort item
    in
    div [ class "content" ]
        [ div [ class "ui horizontal link list" ]
            [ div
                [ classList
                    [ ( "link item", True )
                    , ( "invisible hidden"
                      , fieldHidden Data.Fields.CorrOrg
                            && fieldHidden Data.Fields.CorrPerson
                      )
                    ]
                , title "Correspondent"
                ]
                (Icons.correspondentIcon ""
                    :: Comp.LinkTarget.makeCorrLink item SetLinkTarget
                )
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
                (Icons.concernedIcon
                    :: Comp.LinkTarget.makeConcLink item SetLinkTarget
                )
            , div
                [ classList
                    [ ( "item", True )
                    , ( "invisible hidden", fieldHidden Data.Fields.Folder )
                    ]
                , title "Folder"
                ]
                [ Icons.folderIcon ""
                , Comp.LinkTarget.makeFolderLink item SetLinkTarget
                ]
            ]
        , div [ class "right floated meta" ]
            [ div [ class "ui horizontal list" ]
                [ div
                    [ class "item"
                    , title "Source"
                    ]
                    [ IT.render IT.source item |> text
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


notesContent : UiSettings -> ItemLight -> Html Msg
notesContent settings item =
    div
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


mainContent : Attribute Msg -> String -> Bool -> UiSettings -> ViewConfig -> ItemLight -> Html Msg
mainContent cardAction cardColor isConfirmed settings _ item =
    let
        dirIcon =
            i [ class (Data.Direction.iconFromMaybe item.direction) ] []

        fieldHidden f =
            Data.UiSettings.fieldHidden settings f

        titlePattern =
            settings.cardTitleTemplate.template

        subtitlePattern =
            settings.cardSubtitleTemplate.template
    in
    a
        [ class "content"
        , href "#"
        , cardAction
        ]
        [ if fieldHidden Data.Fields.Direction then
            div [ class "header" ]
                [ IT.render titlePattern item |> text
                ]

          else
            div
                [ class "header"
                , IT.render IT.direction item |> title
                ]
                [ dirIcon
                , IT.render titlePattern item |> text
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
            [ IT.render subtitlePattern item |> text
            ]
        , div [ class "meta description" ]
            [ mainTagsAndFields settings item
            ]
        ]


mainTagsAndFields : UiSettings -> ItemLight -> Html Msg
mainTagsAndFields settings item =
    let
        fieldHidden f =
            Data.UiSettings.fieldHidden settings f

        hideTags =
            item.tags == [] || fieldHidden Data.Fields.Tag

        hideFields =
            item.customfields == [] || fieldHidden Data.Fields.CustomFields

        showTag tag =
            div
                [ classList
                    [ ( "ui basic label", True )
                    , ( Data.UiSettings.tagColorString tag settings, True )
                    ]
                ]
                [ i [ class "tag icon" ] []
                , div [ class "detail" ]
                    [ text tag.name
                    ]
                ]

        showField fv =
            Util.CustomField.renderValue "ui basic label" fv

        renderFields =
            if hideFields then
                []

            else
                List.map showField item.customfields

        renderTags =
            if hideTags then
                []

            else
                List.map showTag item.tags
    in
    div
        [ classList
            [ ( "ui right floated tiny labels", True )
            , ( "invisible hidden", hideTags && hideFields )
            ]
        ]
        (renderFields ++ renderTags)


previewImage : UiSettings -> Attribute Msg -> Model -> ItemLight -> Html Msg
previewImage settings cardAction model item =
    let
        mainAttach =
            currentAttachment model item

        previewUrl =
            Maybe.map .id mainAttach
                |> Maybe.map Api.attachmentPreviewURL
                |> Maybe.withDefault (Api.itemBasePreviewURL item.id)
    in
    a
        [ class "image ds-card-image"
        , Data.UiSettings.cardPreviewSize settings
        , cardAction
        ]
        [ img
            [ class "preview-image"
            , src previewUrl
            , Data.UiSettings.cardPreviewSize settings
            ]
            []
        ]


previewMenu : UiSettings -> Model -> ItemLight -> Maybe AttachmentLight -> Html Msg
previewMenu settings model item mainAttach =
    let
        pageCount =
            Maybe.andThen .pageCount mainAttach
                |> Maybe.withDefault 0

        mkAttachUrl id =
            if settings.nativePdfPreview then
                Api.fileURL id

            else
                Api.fileURL id ++ "/view"

        attachUrl =
            Maybe.map .id mainAttach
                |> Maybe.map mkAttachUrl
                |> Maybe.withDefault "/api/v1/sec/attachment/none"

        gotoFileBtn =
            a
                [ class "ui compact basic icon button"
                , href attachUrl
                , target "_self"
                , title "Open attachment file"
                ]
                [ i [ class "eye icon" ] []
                ]
    in
    if pageCount == 0 || (List.length item.attachments == 1 && pageCount == 1) then
        div [ class "card-attachment-nav" ]
            [ gotoFileBtn
            ]

    else if List.length item.attachments == 1 then
        div [ class "card-attachment-nav" ]
            [ div [ class "ui small top attached basic icon buttons" ]
                [ gotoFileBtn
                ]
            , div [ class "ui attached basic fitted center aligned blue segment" ]
                [ span
                    [ title "Number of pages"
                    ]
                    [ text (String.fromInt pageCount)
                    , text "p."
                    ]
                ]
            ]

    else
        div [ class "card-attachment-nav" ]
            [ div [ class "ui small top attached basic icon buttons" ]
                [ gotoFileBtn
                , a
                    [ class "ui compact icon button"
                    , href "#"
                    , onClick (CyclePreview item)
                    ]
                    [ i [ class "arrow right icon" ] []
                    ]
                ]
            , div [ class "ui attached basic blue fitted center aligned segment" ]
                [ currentPosition model item
                    |> String.fromInt
                    |> text
                , text "/"
                , text (List.length item.attachments |> String.fromInt)
                , text ", "
                , text (String.fromInt pageCount)
                , text "p."
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


isSelected : ViewConfig -> String -> Bool
isSelected cfg id =
    case cfg.selection of
        Data.ItemSelection.Active ids ->
            Set.member id ids

        Data.ItemSelection.Inactive ->
            False
