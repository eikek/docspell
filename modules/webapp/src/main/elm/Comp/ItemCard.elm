{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.ItemCard exposing
    ( Model
    , Msg
    , UpdateResult
    , ViewConfig
    , init
    , update
    , view
    )

import Api.Model.AttachmentLight exposing (AttachmentLight)
import Api.Model.HighlightEntry exposing (HighlightEntry)
import Api.Model.ItemLight exposing (ItemLight)
import Comp.LinkTarget exposing (LinkTarget(..))
import Data.Direction
import Data.Fields
import Data.Flags exposing (Flags)
import Data.Icons as Icons
import Data.ItemArrange exposing (ItemArrange)
import Data.ItemSelection exposing (ItemSelection)
import Data.ItemTemplate as IT
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Markdown
import Messages.Comp.ItemCard exposing (Texts)
import Page exposing (Page(..))
import Set exposing (Set)
import Styles as S
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
    | ToggleRowOpen String


type alias ViewConfig =
    { selection : ItemSelection
    , extraClasses : String
    , previewUrl : AttachmentLight -> String
    , previewUrlFallback : ItemLight -> String
    , attachUrl : AttachmentLight -> String
    , detailPage : ItemLight -> Page
    , isRowOpen : Bool
    , arrange : ItemArrange
    }


type alias UpdateResult =
    { model : Model
    , dragModel : DD.Model
    , selection : ItemSelection
    , linkTarget : LinkTarget
    , toggleRow : Maybe String
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



--- Update


update : DD.Model -> Msg -> Model -> UpdateResult
update ddm msg model =
    case msg of
        ToggleRowOpen id ->
            UpdateResult model ddm Data.ItemSelection.Inactive LinkNone (Just id)

        ItemDDMsg lm ->
            let
                ddd =
                    DD.update lm ddm
            in
            UpdateResult model ddd.model Data.ItemSelection.Inactive LinkNone Nothing

        ToggleSelectItem ids id ->
            let
                newSet =
                    if Set.member id ids then
                        Set.remove id ids

                    else
                        Set.insert id ids
            in
            UpdateResult model ddm (Data.ItemSelection.Active newSet) LinkNone Nothing

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
                Nothing

        SetLinkTarget target ->
            UpdateResult model ddm Data.ItemSelection.Inactive target Nothing



--- View2


view : Texts -> ViewConfig -> UiSettings -> Flags -> Model -> ItemLight -> Html Msg
view texts cfg settings flags model item =
    case cfg.arrange of
        Data.ItemArrange.List ->
            viewRow texts cfg settings flags model item

        Data.ItemArrange.Cards ->
            viewCard texts cfg settings flags model item


viewRow : Texts -> ViewConfig -> UiSettings -> Flags -> Model -> ItemLight -> Html Msg
viewRow texts cfg settings flags model item =
    let
        isCreated =
            item.state == "created"

        isDeleted =
            item.state == "deleted"

        cardColor =
            if isCreated then
                "text-blue-500 dark:text-sky-500"

            else if isDeleted then
                "text-red-600 dark:text-orange-600"

            else
                ""

        attachCount =
            List.length item.attachments

        rowOpen =
            cfg.isRowOpen

        mkAttachUrl attach =
            Data.UiSettings.pdfUrl settings flags (cfg.attachUrl attach)

        mainAttach =
            currentAttachment model item

        attachUrl =
            Maybe.map mkAttachUrl mainAttach
                |> Maybe.withDefault "/api/v1/sec/attachment/none"

        fieldHidden f =
            Data.UiSettings.fieldHidden settings f

        expandCollapseLink =
            a
                [ classList
                    [ ( "my-auto flex text-lg w-4 text-left w-1", not rowOpen )
                    , ( "flex w-full block text-xl bg-gray-50 dark:bg-slate-700 mb-2 rounded ", rowOpen )
                    , ( "invisible", isSelected cfg item.id )
                    ]
                , href "#"
                , onClick (ToggleRowOpen item.id)
                ]
                [ if rowOpen then
                    i [ class "fa fa-caret-down pl-1" ] []

                  else
                    i [ class "fa fa-caret-right" ] []
                ]

        titleTemplate =
            settings.cardTitleTemplate.template

        subtitleTemplate =
            settings.cardSubtitleTemplate.template

        dirIcon =
            i
                [ class (Data.Direction.iconFromMaybe2 item.direction)
                , class "mr-2 w-4 text-center"
                , classList [ ( "hidden", fieldHidden Data.Fields.Direction ) ]
                , IT.render IT.direction (templateCtx texts) item |> title
                ]
                []

        newIcon =
            i
                [ class "fa fa-exclamation-circle mr-1"
                , class cardColor
                , title texts.new
                , classList [ ( "hidden", not isCreated ) ]
                ]
                []

        trashIcon =
            i
                [ class Icons.trash
                , class "mr-1"
                , classList [ ( "hidden", not isDeleted ) ]
                ]
                []

        dueDateLong =
            IT.render IT.dueDateLong (templateCtx texts) item

        selectedDimmer =
            div
                [ classList
                    [ ( "hidden", not (isSelected cfg item.id) )
                    ]
                , class S.dimmerRow
                ]
                [ div [ class "text-2xl font-bold text-blue-100 hover:text-blue-200 dark:text-sky-300 dark:hover:text-sky-200" ]
                    [ a
                        (mkCardAction texts cfg settings item)
                        [ i [ class "fa fa-check-circle" ] []
                        ]
                    ]
                ]

        cardAction =
            mkCardAction texts cfg settings item
    in
    div
        ([ classList [ ( "border border-gray-800 border-dashed dark:border-sky-500", isMultiSelectMode cfg ) ]
         , class "flex flex-col dark:border-slate-600 ds-item-row relative "
         , class cfg.extraClasses
         , id item.id
         ]
            ++ DD.draggable ItemDDMsg item.id
        )
        [ div
            [ class "h-14 flex flex-row space-x-1 justify-items-start truncate"
            , classList [ ( "hidden", rowOpen ) ]
            ]
            [ div [ class "flex flex-row mr-1" ]
                [ expandCollapseLink
                , div
                    [ class "flex  pt-0.5 w-12"
                    , classList [ ( "hidden", fieldHidden Data.Fields.PreviewImage ) ]
                    ]
                    [ previewImage2 texts cfg settings model item
                    ]
                ]
            , div [ class "flex flex-grow flex-col truncate text-left" ]
                [ div
                    [ class "truncate w-full text-black dark:text-white pointer font-medium pt-1"
                    ]
                    [ trashIcon
                    , newIcon
                    , i
                        [ class Icons.dueDate2
                        , class "mr-1"
                        , title (texts.dueOn ++ " " ++ dueDateLong)
                        , classList [ ( "hidden", item.dueDate == Nothing ) ]
                        ]
                        []
                    , a (href "#" :: cardAction)
                        [ IT.render titleTemplate (templateCtx texts) item |> text
                        ]
                    , a
                        [ classList [ ( "hidden", List.length item.attachments == 1 ) ]
                        , class "ml-2 opacity-50 text-xs hover:opacity-75"
                        , title texts.cycleAttachments
                        , href "#"
                        , onClick (CyclePreview item)
                        ]
                        [ currentPosition model item
                            |> String.fromInt
                            |> text
                        , text "/"
                        , text (attachCount |> String.fromInt)
                        ]
                    ]
                , div
                    [ class "opacity-75  truncate flex flex-row items-center text-sm -mt-1"
                    , classList
                        [ ( "hidden", IT.render subtitleTemplate (templateCtx texts) item == "" )
                        ]
                    ]
                    [ div [ class "flex mr-2 flex-grow items-center" ]
                        [ dirIcon
                        , IT.render subtitleTemplate (templateCtx texts) item |> text
                        ]
                    , div [ class "opacity-90" ]
                        [ mainTagsAndFields2 settings "flex truncate overflow-hidden flex-nowrap text-xs justify-start hidden md:flex" item
                        ]
                    ]
                ]
            , div [ class "flex items-end" ]
                [ a
                    [ class S.secondaryBasicButtonPlain
                    , class "px-2 py-1 border rounded "
                    , href attachUrl
                    , target "_blank"
                    , title texts.openAttachmentFile
                    ]
                    [ i [ class "fa fa-eye" ] []
                    ]
                , a
                    [ class S.secondaryBasicButtonPlain
                    , class "px-2 py-1 border rounded ml-2"
                    , Page.href (cfg.detailPage item)
                    , title texts.gotoDetail
                    ]
                    [ i [ class "fa fa-edit" ] []
                    ]
                ]
            ]
        , div
            [ class "flex flex-col py-1"
            , classList [ ( "hidden", not rowOpen ) ]
            ]
            [ expandCollapseLink
            , div [ class "flex flex-col sm:flex-row ml-2" ]
                [ div
                    [ class "flex max-w-sm flex-col max-h-96 sm:max-h-full"
                    , classList [ ( "hidden", fieldHidden Data.Fields.PreviewImage ) ]
                    ]
                    [ previewImage2 texts cfg settings model item
                    , previewMenu2 texts settings flags cfg model item (currentAttachment model item)
                    ]
                , div [ class "flex flex-grow flex-col ml-2 text-base" ]
                    [ h3 [ class "text-xl tracking-wide font-bold" ]
                        [ newIcon
                        , trashIcon
                        , IT.render titleTemplate (templateCtx texts) item |> text
                        ]
                    , h4 [ class "opacity-75 font-normal mb-3" ]
                        [ dirIcon
                        , IT.render subtitleTemplate (templateCtx texts) item |> text
                        ]
                    , div [ class "space-y-1 mb-3" ]
                        [ div
                            [ classList
                                [ ( "hidden"
                                  , fieldHidden Data.Fields.CorrOrg
                                        && fieldHidden Data.Fields.CorrPerson
                                  )
                                ]
                            , title texts.basics.correspondent
                            ]
                            (Icons.correspondentIcon2 "mr-2 w-4 text-center"
                                :: Comp.LinkTarget.makeCorrLink item [ ( "hover:opacity-75", True ) ] SetLinkTarget
                            )
                        , div
                            [ classList
                                [ ( "hidden"
                                  , fieldHidden Data.Fields.ConcPerson
                                        && fieldHidden Data.Fields.ConcEquip
                                  )
                                ]
                            , title texts.basics.concerning
                            ]
                            (Icons.concernedIcon2 "mr-2 w-4 text-center"
                                :: Comp.LinkTarget.makeConcLink item [ ( "hover:opacity-75", True ) ] SetLinkTarget
                            )
                        , div
                            [ classList
                                [ ( "hidden", fieldHidden Data.Fields.Folder )
                                ]
                            , class "hover:opacity-60"
                            , title texts.basics.folder
                            ]
                            [ Icons.folderIcon "mr-2"
                            , Comp.LinkTarget.makeFolderLink item
                                [ ( "hover:opacity-60", True ) ]
                                SetLinkTarget
                            ]
                        , div
                            [ classList
                                [ ( "hidden", fieldHidden Data.Fields.Date ) ]
                            ]
                            [ Icons.dateIcon2 "mr-2"
                            , IT.render IT.dateLong (templateCtx texts) item
                                |> Util.String.withDefault "-"
                                |> text
                            ]
                        , div
                            [ classList
                                [ ( "hidden", fieldHidden Data.Fields.DueDate ) ]
                            ]
                            [ Icons.dueDateIcon2 "mr-2"
                            , dueDateLong
                                |> Util.String.withDefault "-"
                                |> text
                            ]
                        , div
                            [ classList
                                [ ( "hidden", fieldHidden Data.Fields.SourceName ) ]
                            ]
                            [ Icons.sourceIcon2 "mr-2"
                            , Comp.LinkTarget.makeSourceLink
                                [ ( "hover:opacity-60", True ) ]
                                SetLinkTarget
                                (IT.render IT.source (templateCtx texts) item)
                            ]
                        ]
                    , mainTagsAndFields2 settings "justify-start text-sm" item
                    , notesContent2 settings item
                    ]
                ]
            ]
        , fulltextResultsContent2 item
        , selectedDimmer
        ]


viewCard : Texts -> ViewConfig -> UiSettings -> Flags -> Model -> ItemLight -> Html Msg
viewCard texts cfg settings flags model item =
    let
        isCreated =
            item.state == "created"

        isDeleted =
            item.state == "deleted"

        cardColor =
            if isCreated then
                "text-blue-500 dark:text-sky-500"

            else if isDeleted then
                "text-red-600 dark:text-orange-600"

            else
                ""

        cardAction =
            mkCardAction texts cfg settings item

        fieldHidden f =
            Data.UiSettings.fieldHidden settings f

        selectedDimmer =
            div
                [ classList
                    [ ( "hidden", not (isSelected cfg item.id) )
                    ]
                , class S.dimmerCard
                , class "rounded-lg"
                ]
                [ div [ class "text-9xl text-blue-400 hover:text-blue-500 dark:text-sky-300 dark:hover:text-sky-200" ]
                    [ a
                        cardAction
                        [ i [ class "fa fa-check-circle font-thin" ] []
                        ]
                    ]
                ]
    in
    div
        ([ class cfg.extraClasses
         , class "ds-item-card relative hover:shadow-lg rounded-lg flex flex-col break-all"
         , classList
            [ ( "border border-gray-400 dark:border-slate-600 dark:hover:border-slate-500", not (isMultiSelectMode cfg) )
            , ( "border-2 border-gray-800 border-dashed dark:border-sky-500", isMultiSelectMode cfg )
            ]
         , id item.id
         ]
            ++ DD.draggable ItemDDMsg item.id
        )
        ((if fieldHidden Data.Fields.PreviewImage then
            []

          else
            [ previewImage2 texts cfg settings model item
            ]
         )
            ++ [ mainContent2 texts cardAction cardColor isCreated isDeleted settings cfg item
               , metaDataContent2 texts settings item
               , notesContent2 settings item
               , fulltextResultsContent2 item
               , previewMenu2 texts settings flags cfg model item (currentAttachment model item)
               , selectedDimmer
               ]
        )


mkCardAction : Texts -> ViewConfig -> UiSettings -> ItemLight -> List (Attribute Msg)
mkCardAction texts cfg settings item =
    case cfg.selection of
        Data.ItemSelection.Inactive ->
            case cfg.arrange of
                Data.ItemArrange.List ->
                    if cfg.isRowOpen then
                        [ Page.href (cfg.detailPage item)
                        , title texts.gotoDetail
                        ]

                    else
                        [ onClick (ToggleRowOpen item.id)
                        , href "#"
                        ]

                Data.ItemArrange.Cards ->
                    [ Page.href (cfg.detailPage item)
                    , title texts.gotoDetail
                    ]

        Data.ItemSelection.Active ids ->
            [ onClick (ToggleSelectItem ids item.id)
            , href "#"
            ]


fulltextResultsContent2 : ItemLight -> Html Msg
fulltextResultsContent2 item =
    div
        [ class "ds-card-search-hl flex flex-col text-sm px-2 bg-yellow-50 dark:bg-indigo-800 dark:bg-opacity-10 bg-opacity-50"
        , classList
            [ ( "hidden", item.highlighting == [] )
            ]
        ]
        (List.map renderHighlightEntry2 item.highlighting)


templateCtx : Texts -> IT.TemplateContext
templateCtx texts =
    { dateFormatLong = texts.formatDateLong
    , dateFormatShort = texts.formatDateShort
    , directionLabel = texts.directionLabel
    }


metaDataContent2 : Texts -> UiSettings -> ItemLight -> Html Msg
metaDataContent2 texts settings item =
    let
        fieldHidden f =
            Data.UiSettings.fieldHidden settings f
    in
    div [ class "px-2 pb-1 flex flex-row items-center justify-between text-sm opacity-80" ]
        [ div [ class "flex flex-row justify-between" ]
            [ div
                [ classList
                    [ ( "hidden", fieldHidden Data.Fields.Folder )
                    ]
                , class "hover:opacity-60"
                , title texts.basics.folder
                ]
                [ Icons.folderIcon "mr-2"
                , Comp.LinkTarget.makeFolderLink item
                    [ ( "hover:opacity-60", True ) ]
                    SetLinkTarget
                ]
            ]
        , div [ class "flex-grow" ] []
        , div [ class "flex flex-row items-center justify-end" ]
            [ div [ class "" ]
                [ Icons.sourceIcon2 "mr-2"
                , Comp.LinkTarget.makeSourceLink
                    [ ( "hover:opacity-60", True ) ]
                    SetLinkTarget
                    (IT.render IT.source (templateCtx texts) item)
                ]
            ]
        ]


notesContent2 : UiSettings -> ItemLight -> Html Msg
notesContent2 settings item =
    div
        [ classList
            [ ( "hidden"
              , settings.itemSearchNoteLength
                    <= 0
                    || Util.String.isNothingOrBlank item.notes
              )
            ]
        , class "px-2 py-2 border-t  dark:border-slate-600 opacity-50 text-sm"
        ]
        [ Maybe.withDefault "" item.notes
            |> Util.String.ellipsis settings.itemSearchNoteLength
            |> text
        ]


mainContent2 :
    Texts
    -> List (Attribute Msg)
    -> String
    -> Bool
    -> Bool
    -> UiSettings
    -> ViewConfig
    -> ItemLight
    -> Html Msg
mainContent2 texts _ cardColor isCreated isDeleted settings _ item =
    let
        dirIcon =
            i
                [ class (Data.Direction.iconFromMaybe2 item.direction)
                , class "mr-2 w-4 text-center"
                , classList [ ( "hidden", fieldHidden Data.Fields.Direction ) ]
                , IT.render IT.direction (templateCtx texts) item |> title
                ]
                []

        fieldHidden f =
            Data.UiSettings.fieldHidden settings f

        titlePattern =
            settings.cardTitleTemplate.template

        subtitlePattern =
            settings.cardSubtitleTemplate.template
    in
    div
        [ class "flex flex-col px-2 py-2 mb-auto" ]
        [ div
            [ classList
                [ ( "hidden"
                  , fieldHidden Data.Fields.CorrOrg
                        && fieldHidden Data.Fields.CorrPerson
                  )
                ]
            , title texts.basics.correspondent
            ]
            (Icons.correspondentIcon2 "mr-2 w-4 text-center"
                :: Comp.LinkTarget.makeCorrLink item [ ( "hover:opacity-75", True ) ] SetLinkTarget
            )
        , div
            [ classList
                [ ( "hidden"
                  , fieldHidden Data.Fields.ConcPerson
                        && fieldHidden Data.Fields.ConcEquip
                  )
                ]
            , title texts.basics.concerning
            ]
            (Icons.concernedIcon2 "mr-2 w-4 text-center"
                :: Comp.LinkTarget.makeConcLink item [ ( "hover:opacity-75", True ) ] SetLinkTarget
            )
        , div
            [ class "font-bold py-1 text-lg"
            , classList [ ( "hidden", IT.render titlePattern (templateCtx texts) item == "" ) ]
            ]
            [ IT.render titlePattern (templateCtx texts) item |> text
            ]
        , div
            [ classList
                [ ( "absolute right-1 top-1 text-4xl", True )
                , ( cardColor, True )
                , ( "hidden", not isCreated )
                ]
            , title texts.new
            ]
            [ i [ class "ml-2 fa fa-exclamation-circle" ] []
            ]
        , div
            [ classList
                [ ( "absolute right-1 top-1 text-4xl", True )
                , ( cardColor, True )
                , ( "hidden", not isDeleted )
                ]
            , title texts.basics.deleted
            ]
            [ i [ class "ml-2 fa fa-trash-alt" ] []
            ]
        , div
            [ classList
                [ ( "opacity-75", True )
                , ( "hidden", IT.render subtitlePattern (templateCtx texts) item == "" )
                ]
            ]
            [ dirIcon
            , IT.render subtitlePattern (templateCtx texts) item |> text
            ]
        , div [ class "" ]
            [ mainTagsAndFields2 settings "justify-end text-xs" item
            ]
        ]


mainTagsAndFields2 : UiSettings -> String -> ItemLight -> Html Msg
mainTagsAndFields2 settings extraCss item =
    let
        fieldHidden f =
            Data.UiSettings.fieldHidden settings f

        hideTags =
            item.tags == [] || fieldHidden Data.Fields.Tag

        hideFields =
            item.customfields == [] || fieldHidden Data.Fields.CustomFields

        showTag tag =
            Comp.LinkTarget.makeTagIconLink
                tag
                (i [ class "fa fa-tag mr-2" ] [])
                [ ( "label ml-1 mt-1 font-semibold hover:opacity-75", True )
                , ( Data.UiSettings.tagColorString2 tag settings, True )
                ]
                SetLinkTarget

        showField fv =
            Comp.LinkTarget.makeCustomFieldLink2 fv
                [ ( S.basicLabel, True )
                , ( "ml-1 mt-1 font-semibold hover:opacity-75", True )
                ]
                SetLinkTarget

        renderFields =
            if hideFields then
                []

            else
                List.sortBy Util.CustomField.nameOrLabel item.customfields
                    |> List.map showField

        renderTags =
            if hideTags then
                []

            else
                List.map showTag item.tags
    in
    div
        [ classList
            [ ( "flex flex-row items-center flex-wrap font-medium", True )
            , ( "hidden", hideTags && hideFields )
            ]
        , class extraCss
        ]
        (renderFields ++ renderTags)


previewImage2 : Texts -> ViewConfig -> UiSettings -> Model -> ItemLight -> Html Msg
previewImage2 texts cfg settings model item =
    let
        mainAttach =
            currentAttachment model item

        previewUrl =
            Maybe.map cfg.previewUrl mainAttach
                |> Maybe.withDefault (cfg.previewUrlFallback item)

        isCardView =
            case cfg.arrange of
                Data.ItemArrange.List ->
                    False

                Data.ItemArrange.Cards ->
                    True

        isRowOpen =
            cfg.isRowOpen

        isListView =
            not isCardView
    in
    a
        ([ class "overflow-hidden block bg-gray-50 dark:bg-slate-700 dark:bg-opacity-40  border-gray-400 dark:hover:border-slate-500 w-full"
         , classList
            [ ( "rounded-t-lg", isCardView )
            , ( Data.UiSettings.cardPreviewSize2 settings, isCardView )
            ]
         ]
            ++ mkCardAction texts cfg settings item
        )
        [ img
            [ class "preview-image mx-auto"
            , classList
                [ ( "rounded-t-lg w-full -mt-1", settings.cardPreviewFullWidth && isCardView )
                , ( Data.UiSettings.cardPreviewSize2 settings, not settings.cardPreviewFullWidth && isCardView )
                , ( "h-12", isListView && not isRowOpen )
                , ( "border-t border-r border-l dark:border-slate-600", isListView && isRowOpen )
                ]
            , src previewUrl
            ]
            []
        ]


previewMenu2 : Texts -> UiSettings -> Flags -> ViewConfig -> Model -> ItemLight -> Maybe AttachmentLight -> Html Msg
previewMenu2 texts settings flags cfg model item mainAttach =
    let
        pageCount =
            Maybe.andThen .pageCount mainAttach
                |> Maybe.withDefault 0

        attachCount =
            List.length item.attachments

        fieldHidden f =
            Data.UiSettings.fieldHidden settings f

        mkAttachUrl attach =
            Data.UiSettings.pdfUrl settings flags (cfg.attachUrl attach)

        attachUrl =
            Maybe.map mkAttachUrl mainAttach
                |> Maybe.withDefault "/api/v1/sec/attachment/none"

        dueDate =
            IT.render IT.dueDateShort (templateCtx texts) item

        dueDateLabel =
            div
                [ classList
                    [ ( " hidden"
                      , item.dueDate
                            == Nothing
                            || fieldHidden Data.Fields.DueDate
                      )
                    ]
                , class "label font-semibold text-sm border-gray-300 dark:border-slate-600"
                , title (texts.dueOn ++ " " ++ dueDate)
                ]
                [ Icons.dueDateIcon2 "mr-2"
                , text (" " ++ dueDate)
                ]

        isCardView =
            case cfg.arrange of
                Data.ItemArrange.List ->
                    False

                Data.ItemArrange.Cards ->
                    True

        isRowOpen =
            cfg.isRowOpen

        isListView =
            not isCardView
    in
    div
        [ class "px-2 py-1 flex flex-row flex-wrap bg-gray-50 dark:bg-slate-700 dark:bg-opacity-40 rounded-b-lg md:text-sm"
        , classList
            [ ( "border-0", isCardView || not isRowOpen )
            , ( "border-b border-l border-r dark:border-slate-600", isListView && isRowOpen )
            ]
        ]
        [ a
            [ class S.secondaryBasicButtonPlain
            , class "px-2 py-1 border rounded "
            , href attachUrl
            , target "_self"
            , title texts.openAttachmentFile
            ]
            [ i [ class "fa fa-eye" ] []
            ]
        , a
            [ class S.secondaryBasicButtonPlain
            , class "px-2 py-1 border rounded ml-2"
            , Page.href (cfg.detailPage item)
            , title texts.gotoDetail
            ]
            [ i [ class "fa fa-edit" ] []
            ]
        , div
            [ classList [ ( "hidden", attachCount > 1 && not (fieldHidden Data.Fields.PreviewImage) ) ]
            , class "ml-2"
            ]
            [ div [ class "px-2 rounded border border-gray-300 dark:border-slate-600 py-1" ]
                [ text (String.fromInt pageCount)
                , text "p."
                ]
            ]
        , div
            [ class "flex flex-row items-center ml-2"
            , classList [ ( "hidden", attachCount <= 1 || fieldHidden Data.Fields.PreviewImage ) ]
            ]
            [ a
                [ class S.secondaryBasicButtonPlain
                , class "px-2 py-1 border rounded-l block"
                , title texts.cycleAttachments
                , href "#"
                , onClick (CyclePreview item)
                ]
                [ i [ class "fa fa-arrow-right" ] []
                ]
            , div [ class "px-2 rounded-r border-t border-r border-b border-gray-500 dark:border-slate-500 py-1" ]
                [ currentPosition model item
                    |> String.fromInt
                    |> text
                , text "/"
                , text (attachCount |> String.fromInt)
                , text ", "
                , text (String.fromInt pageCount)
                , text "p."
                ]
            ]
        , div [ class "flex-grow" ] []
        , div [ class "flex flex-row items-center justify-end" ]
            [ dueDateLabel
            ]
        ]


renderHighlightEntry2 : HighlightEntry -> Html Msg
renderHighlightEntry2 entry =
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
    div [ class "content" ]
        (div [ class "font-semibold" ]
            [ i [ class "fa fa-file font-thin mr-1 " ] []
            , text (entry.name ++ ":")
            ]
            :: List.map
                (\str ->
                    Markdown.toHtml [ class "opacity-80 " ] <|
                        (stripWhitespace str ++ "…")
                )
                entry.lines
        )



--- Helpers


isSelected : ViewConfig -> String -> Bool
isSelected cfg id =
    case cfg.selection of
        Data.ItemSelection.Active ids ->
            Set.member id ids

        Data.ItemSelection.Inactive ->
            False


isMultiSelectMode : ViewConfig -> Bool
isMultiSelectMode cfg =
    case cfg.selection of
        Data.ItemSelection.Active _ ->
            True

        Data.ItemSelection.Inactive ->
            False
