module Comp.ItemCard exposing
    ( Model
    , Msg
    , UpdateResult
    , ViewConfig
    , init
    , update
    , view2
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
import Messages.ItemCardComp exposing (Texts)
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



--- Update


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



--- View2


view2 : Texts -> ViewConfig -> UiSettings -> Model -> ItemLight -> Html Msg
view2 texts cfg settings model item =
    let
        isConfirmed =
            item.state /= "created"

        cardColor =
            if not isConfirmed then
                "text-blue-500 dark:text-lightblue-500"

            else
                ""

        fieldHidden f =
            Data.UiSettings.fieldHidden settings f

        cardAction =
            case cfg.selection of
                Data.ItemSelection.Inactive ->
                    [ Page.href (ItemDetailPage item.id)
                    ]

                Data.ItemSelection.Active ids ->
                    [ onClick (ToggleSelectItem ids item.id)
                    , href "#"
                    ]

        selectedDimmer =
            div
                [ classList
                    [ ( "hidden", not (isSelected cfg item.id) )
                    ]
                , class S.dimmerCard
                , class "rounded-lg"
                ]
                [ div [ class "text-9xl text-blue-400 hover:text-blue-500 dark:text-lightblue-300 dark:hover:text-lightblue-200" ]
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
            [ ( "border border-gray-400 dark:border-bluegray-600 dark:hover:border-bluegray-500", not (isMultiSelectMode cfg) )
            , ( "border-2 border-gray-800 border-dashed dark:border-lightblue-500", isMultiSelectMode cfg )
            ]
         , id item.id
         ]
            ++ DD.draggable ItemDDMsg item.id
        )
        ((if fieldHidden Data.Fields.PreviewImage then
            []

          else
            [ previewImage2 settings cardAction model item
            ]
         )
            ++ [ mainContent2 texts cardAction cardColor isConfirmed settings cfg item
               , metaDataContent2 texts settings item
               , notesContent2 settings item
               , fulltextResultsContent2 item
               , previewMenu2 settings model item (currentAttachment model item)
               , selectedDimmer
               ]
        )


fulltextResultsContent2 : ItemLight -> Html Msg
fulltextResultsContent2 item =
    div
        [ class "ds-card-search-hl flex flex-col text-sm px-2 bg-yellow-50 dark:bg-indigo-800 dark:bg-opacity-60 "
        , classList
            [ ( "hidden", item.highlighting == [] )
            ]
        ]
        (List.map renderHighlightEntry2 item.highlighting)


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
                , title texts.folder
                ]
                [ Icons.folderIcon2 "mr-2"
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
                    (IT.render IT.source item)
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
        , class "px-2 py-2 border-t  dark:border-bluegray-600 opacity-50 text-sm"
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
    -> UiSettings
    -> ViewConfig
    -> ItemLight
    -> Html Msg
mainContent2 texts cardAction cardColor isConfirmed settings _ item =
    let
        dirIcon =
            i
                [ class (Data.Direction.iconFromMaybe2 item.direction)
                , class "mr-2 w-4 text-center"
                , classList [ ( "hidden", fieldHidden Data.Fields.Direction ) ]
                , IT.render IT.direction item |> title
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
            , title "Correspondent"
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
            , title "Concerning"
            ]
            (Icons.concernedIcon2 "mr-2 w-4 text-center"
                :: Comp.LinkTarget.makeConcLink item [ ( "hover:opacity-75", True ) ] SetLinkTarget
            )
        , div
            [ class "font-bold py-1 text-lg"
            , classList [ ( "hidden", IT.render titlePattern item == "" ) ]
            ]
            [ IT.render titlePattern item |> text
            ]
        , div
            [ classList
                [ ( "absolute right-1 top-1 text-4xl", True )
                , ( cardColor, True )
                , ( "hidden", isConfirmed )
                ]
            , title "New"
            ]
            [ i [ class "ml-2 fa fa-exclamation-circle" ] []
            ]
        , div
            [ classList
                [ ( "opacity-75", True )
                , ( "hidden", IT.render subtitlePattern item == "" )
                ]
            ]
            [ dirIcon
            , IT.render subtitlePattern item |> text
            ]
        , div [ class "" ]
            [ mainTagsAndFields2 settings item
            ]
        ]


mainTagsAndFields2 : UiSettings -> ItemLight -> Html Msg
mainTagsAndFields2 settings item =
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
            [ ( "flex flex-row items-center flex-wrap justify-end text-xs font-medium my-1", True )
            , ( "hidden", hideTags && hideFields )
            ]
        ]
        (renderFields ++ renderTags)


previewImage2 : UiSettings -> List (Attribute Msg) -> Model -> ItemLight -> Html Msg
previewImage2 settings cardAction model item =
    let
        mainAttach =
            currentAttachment model item

        previewUrl =
            Maybe.map .id mainAttach
                |> Maybe.map Api.attachmentPreviewURL
                |> Maybe.withDefault (Api.itemBasePreviewURL item.id)
    in
    a
        ([ class "overflow-hidden block bg-gray-50 dark:bg-bluegray-700 dark:bg-opacity-40  border-gray-400 dark:hover:border-bluegray-500 rounded-t-lg"
         , class (Data.UiSettings.cardPreviewSize2 settings)
         ]
            ++ cardAction
        )
        [ img
            [ class "preview-image mx-auto pt-1"
            , classList
                [ ( "rounded-t-lg w-full -mt-1", settings.cardPreviewFullWidth )
                , ( Data.UiSettings.cardPreviewSize2 settings, not settings.cardPreviewFullWidth )
                ]
            , src previewUrl
            ]
            []
        ]


previewMenu2 : UiSettings -> Model -> ItemLight -> Maybe AttachmentLight -> Html Msg
previewMenu2 settings model item mainAttach =
    let
        pageCount =
            Maybe.andThen .pageCount mainAttach
                |> Maybe.withDefault 0

        attachCount =
            List.length item.attachments

        fieldHidden f =
            Data.UiSettings.fieldHidden settings f

        mkAttachUrl id =
            if settings.nativePdfPreview then
                Api.fileURL id

            else
                Api.fileURL id ++ "/view"

        attachUrl =
            Maybe.map .id mainAttach
                |> Maybe.map mkAttachUrl
                |> Maybe.withDefault "/api/v1/sec/attachment/none"

        dueDate =
            IT.render IT.dueDateShort item

        dueDateLabel =
            div
                [ classList
                    [ ( " hidden"
                      , item.dueDate
                            == Nothing
                            || fieldHidden Data.Fields.DueDate
                      )
                    ]
                , class "label font-semibold text-sm border-gray-300 dark:border-bluegray-600"
                , title ("Due on " ++ dueDate)
                ]
                [ Icons.dueDateIcon2 "mr-2"
                , text (" " ++ dueDate)
                ]
    in
    div [ class "px-2 py-1 flex flex-row flex-wrap bg-gray-50 dark:bg-bluegray-700 dark:bg-opacity-40 border-0 rounded-b-lg md:text-sm" ]
        [ a
            [ class S.secondaryBasicButtonPlain
            , class "px-2 py-1 border rounded "
            , href attachUrl
            , target "_self"
            , title "Open attachment file"
            ]
            [ i [ class "fa fa-eye" ] []
            ]
        , a
            [ class S.secondaryBasicButtonPlain
            , class "px-2 py-1 border rounded ml-2"
            , Page.href (ItemDetailPage item.id)
            , title "Go to detail view"
            ]
            [ i [ class "fa fa-edit" ] []
            ]
        , div
            [ classList [ ( "hidden", attachCount > 1 && not (fieldHidden Data.Fields.PreviewImage) ) ]
            , class "ml-2"
            ]
            [ div [ class "px-2 rounded border border-gray-300 dark:border-bluegray-600 py-1" ]
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
                , title "Cycle attachments"
                , href "#"
                , onClick (CyclePreview item)
                ]
                [ i [ class "fa fa-arrow-right" ] []
                ]
            , div [ class "px-2 rounded-r border-t border-r border-b border-gray-500 dark:border-bluegray-500 py-1" ]
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
            [ i [ class "fa fa-caret-right mr-1 " ] []
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
