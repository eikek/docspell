{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.SearchMenu exposing
    ( Model
    , Msg(..)
    , NextState
    , SearchTab(..)
    , TextSearchModel
    , getItemQuery
    , init
    , isFulltextSearch
    , isNamesSearch
    , linkTargetMsg
    , refreshBookmarks
    , setFromStats
    , textSearchString
    , update
    , updateDrop
    , viewDrop2
    )

import Api
import Api.Model.Equipment exposing (Equipment)
import Api.Model.EquipmentList exposing (EquipmentList)
import Api.Model.FolderStats exposing (FolderStats)
import Api.Model.IdName exposing (IdName)
import Api.Model.ItemFieldValue exposing (ItemFieldValue)
import Api.Model.ItemQuery exposing (ItemQuery)
import Api.Model.PersonList exposing (PersonList)
import Api.Model.ReferenceList exposing (ReferenceList)
import Api.Model.SearchStats exposing (SearchStats)
import Comp.BookmarkChooser
import Comp.CustomFieldMultiInput
import Comp.DatePicker
import Comp.Dropdown exposing (isDropdownChangeMsg)
import Comp.FolderSelect
import Comp.LinkTarget exposing (LinkTarget)
import Comp.MenuBar as MB
import Comp.Tabs
import Comp.TagSelect
import Data.BookmarkedQuery exposing (AllBookmarks)
import Data.CustomFieldChange exposing (CustomFieldValueCollect)
import Data.Direction exposing (Direction)
import Data.DropdownStyle as DS
import Data.EquipmentOrder
import Data.EquipmentUse
import Data.Fields
import Data.Flags exposing (Flags)
import Data.ItemQuery as Q exposing (ItemQuery)
import Data.PersonOrder
import Data.PersonUse
import Data.SearchMode exposing (SearchMode)
import Data.UiSettings exposing (UiSettings)
import DatePicker exposing (DatePicker)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Messages.Comp.SearchMenu exposing (Texts)
import Set exposing (Set)
import Styles as S
import Util.CustomField
import Util.Html exposing (KeyCode(..))
import Util.ItemDragDrop as DD
import Util.Maybe



-- Data Model


type alias Model =
    { tagSelectModel : Comp.TagSelect.Model
    , tagSelection : Comp.TagSelect.Selection
    , directionModel : Comp.Dropdown.Model Direction
    , orgModel : Comp.Dropdown.Model IdName
    , corrPersonModel : Comp.Dropdown.Model IdName
    , concPersonModel : Comp.Dropdown.Model IdName
    , concEquipmentModel : Comp.Dropdown.Model Equipment
    , folderList : Comp.FolderSelect.Model
    , selectedFolder : Maybe FolderStats
    , inboxCheckbox : Bool
    , fromDateModel : DatePicker
    , fromDate : Maybe Int
    , untilDateModel : DatePicker
    , untilDate : Maybe Int
    , fromDueDateModel : DatePicker
    , fromDueDate : Maybe Int
    , untilDueDateModel : DatePicker
    , untilDueDate : Maybe Int
    , nameModel : Maybe String
    , textSearchModel : TextSearchModel
    , datePickerInitialized : Bool
    , customFieldModel : Comp.CustomFieldMultiInput.Model
    , customValues : CustomFieldValueCollect
    , sourceModel : Maybe String
    , allBookmarks : Comp.BookmarkChooser.Model
    , selectedBookmarks : Comp.BookmarkChooser.Selection
    , openTabs : Set String
    , searchMode : SearchMode
    }


type TextSearchModel
    = Fulltext (Maybe String)
    | Names (Maybe String)


init : Flags -> Model
init flags =
    { tagSelectModel = Comp.TagSelect.init [] [] [] []
    , tagSelection = Comp.TagSelect.emptySelection
    , directionModel =
        Comp.Dropdown.makeSingleList
            { options = Data.Direction.all
            , selected = Nothing
            }
    , orgModel = Comp.Dropdown.makeSingle
    , corrPersonModel = Comp.Dropdown.makeSingle
    , concPersonModel = Comp.Dropdown.makeSingle
    , concEquipmentModel = Comp.Dropdown.makeSingle
    , folderList = Comp.FolderSelect.init Nothing []
    , selectedFolder = Nothing
    , inboxCheckbox = False
    , fromDateModel = Comp.DatePicker.emptyModel
    , fromDate = Nothing
    , untilDateModel = Comp.DatePicker.emptyModel
    , untilDate = Nothing
    , fromDueDateModel = Comp.DatePicker.emptyModel
    , fromDueDate = Nothing
    , untilDueDateModel = Comp.DatePicker.emptyModel
    , untilDueDate = Nothing
    , nameModel = Nothing
    , textSearchModel =
        if flags.config.fullTextSearchEnabled then
            Fulltext Nothing

        else
            Names Nothing
    , datePickerInitialized = False
    , customFieldModel = Comp.CustomFieldMultiInput.initWith []
    , customValues = Data.CustomFieldChange.emptyCollect
    , sourceModel = Nothing
    , allBookmarks = Comp.BookmarkChooser.init Data.BookmarkedQuery.allBookmarksEmpty
    , selectedBookmarks = Comp.BookmarkChooser.emptySelection
    , openTabs = Set.fromList [ "Tags", "Inbox" ]
    , searchMode = Data.SearchMode.Normal
    }


updateTextSearch : String -> TextSearchModel -> TextSearchModel
updateTextSearch str model =
    let
        next =
            Util.Maybe.fromString str
    in
    case model of
        Fulltext _ ->
            Fulltext next

        Names _ ->
            Names next


swapTextSearch : TextSearchModel -> TextSearchModel
swapTextSearch model =
    case model of
        Fulltext s ->
            Names s

        Names s ->
            Fulltext s


textSearchValue : TextSearchModel -> { nameSearch : Maybe String, fullText : Maybe String }
textSearchValue model =
    case model of
        Fulltext s ->
            { nameSearch = Nothing
            , fullText = s
            }

        Names s ->
            { nameSearch = s
            , fullText = Nothing
            }


textSearchString : TextSearchModel -> Maybe String
textSearchString model =
    case model of
        Fulltext s ->
            s

        Names s ->
            s


isFulltextSearch : Model -> Bool
isFulltextSearch model =
    case model.textSearchModel of
        Fulltext _ ->
            True

        Names _ ->
            False


isNamesSearch : Model -> Bool
isNamesSearch model =
    case model.textSearchModel of
        Fulltext _ ->
            False

        Names _ ->
            True


getItemQuery : Model -> Maybe ItemQuery
getItemQuery model =
    let
        when flag body =
            if flag then
                Just body

            else
                Nothing

        whenNot flag body =
            when (not flag) body

        whenNotEmpty list f =
            whenNot (List.isEmpty list) (f list)

        amendWildcards s =
            if String.startsWith "\"" s && String.endsWith "\"" s then
                String.dropLeft 1 s
                    |> String.dropRight 1

            else if String.contains "*" s then
                s

            else
                "*" ++ s ++ "*"

        textSearch =
            textSearchValue model.textSearchModel

        bookmarks =
            List.map .query (Comp.BookmarkChooser.getQueries model.allBookmarks model.selectedBookmarks)
                |> List.map Q.Fragment
    in
    Q.and
        [ when model.inboxCheckbox (Q.Inbox True)
        , whenNotEmpty (model.tagSelection.includeTags |> List.map (.tag >> .id))
            (Q.TagIds Q.AllMatch)
        , whenNotEmpty (model.tagSelection.excludeTags |> List.map (.tag >> .id))
            (\ids -> Q.Not (Q.TagIds Q.AnyMatch ids))
        , whenNotEmpty (model.tagSelection.includeCats |> List.map .name)
            (Q.CatNames Q.AllMatch)
        , whenNotEmpty (model.tagSelection.excludeCats |> List.map .name)
            (\ids -> Q.Not <| Q.CatNames Q.AnyMatch ids)
        , model.selectedFolder |> Maybe.map .id |> Maybe.map (Q.FolderId Q.Eq)
        , Comp.Dropdown.getSelected model.orgModel
            |> List.map .id
            |> List.head
            |> Maybe.map (Q.CorrOrgId Q.Eq)
        , Comp.Dropdown.getSelected model.corrPersonModel
            |> List.map .id
            |> List.head
            |> Maybe.map (Q.CorrPersId Q.Eq)
        , Comp.Dropdown.getSelected model.concPersonModel
            |> List.map .id
            |> List.head
            |> Maybe.map (Q.ConcPersId Q.Eq)
        , Comp.Dropdown.getSelected model.concEquipmentModel
            |> List.map .id
            |> List.head
            |> Maybe.map (Q.ConcEquipId Q.Eq)
        , whenNotEmpty (Data.CustomFieldChange.toFieldValues model.customValues)
            (List.map (Q.CustomFieldId Q.Like) >> Q.And)
        , Maybe.map (Q.DateMs Q.Gte) model.fromDate
        , Maybe.map (Q.DateMs Q.Lte) model.untilDate
        , Maybe.map (Q.DueDateMs Q.Gte) model.fromDueDate
        , Maybe.map (Q.DueDateMs Q.Lte) model.untilDueDate
        , Maybe.map (Q.Source Q.Like) model.sourceModel
        , model.nameModel
            |> Maybe.map amendWildcards
            |> Maybe.map (Q.ItemName Q.Like)
        , textSearch.nameSearch
            |> Maybe.map amendWildcards
            |> Maybe.map Q.AllNames
        , Comp.Dropdown.getSelected model.directionModel
            |> List.head
            |> Maybe.map Q.Dir
        , textSearch.fullText
            |> Maybe.map Q.Contents
        , whenNotEmpty bookmarks Q.And
        ]


resetModel : Model -> Model
resetModel model =
    let
        emptyDropdown dm =
            Comp.Dropdown.update (Comp.Dropdown.SetSelection []) dm
                |> Tuple.first

        emptyFolder fm =
            Comp.FolderSelect.deselect fm
                |> Maybe.map (\msg -> Comp.FolderSelect.update msg fm)
                |> Maybe.map Tuple.first
                |> Maybe.withDefault fm
    in
    { model
        | tagSelection = Comp.TagSelect.emptySelection
        , tagSelectModel = Comp.TagSelect.reset model.tagSelectModel
        , directionModel = emptyDropdown model.directionModel
        , orgModel = emptyDropdown model.orgModel
        , corrPersonModel = emptyDropdown model.corrPersonModel
        , concPersonModel = emptyDropdown model.concPersonModel
        , concEquipmentModel = emptyDropdown model.concEquipmentModel
        , folderList = emptyFolder model.folderList
        , selectedFolder = Nothing
        , inboxCheckbox = False
        , fromDate = Nothing
        , untilDate = Nothing
        , fromDueDate = Nothing
        , untilDueDate = Nothing
        , nameModel = Nothing
        , textSearchModel =
            case model.textSearchModel of
                Fulltext _ ->
                    Fulltext Nothing

                Names _ ->
                    Names Nothing
        , customFieldModel =
            Comp.CustomFieldMultiInput.reset
                model.customFieldModel
        , customValues = Data.CustomFieldChange.emptyCollect
        , sourceModel = Nothing
        , selectedBookmarks = Comp.BookmarkChooser.emptySelection
        , searchMode = Data.SearchMode.Normal
    }



-- Update


type Msg
    = Init
    | TagSelectMsg Comp.TagSelect.Msg
    | DirectionMsg (Comp.Dropdown.Msg Direction)
    | OrgMsg (Comp.Dropdown.Msg IdName)
    | CorrPersonMsg (Comp.Dropdown.Msg IdName)
    | ConcPersonMsg (Comp.Dropdown.Msg IdName)
    | ConcEquipmentMsg (Comp.Dropdown.Msg Equipment)
    | FromDateMsg Comp.DatePicker.Msg
    | UntilDateMsg Comp.DatePicker.Msg
    | FromDueDateMsg Comp.DatePicker.Msg
    | UntilDueDateMsg Comp.DatePicker.Msg
    | ToggleInbox
    | ToggleSearchMode
    | GetOrgResp (Result Http.Error ReferenceList)
    | GetEquipResp (Result Http.Error EquipmentList)
    | GetPersonResp (Result Http.Error PersonList)
    | SetName String
    | SetTextSearch String
    | SwapTextSearch
    | SetFulltextSearch
    | SetNamesSearch
    | ResetForm
    | KeyUpMsg (Maybe KeyCode)
    | FolderSelectMsg Comp.FolderSelect.Msg
    | SetCorrOrg IdName
    | SetCorrPerson IdName
    | SetConcPerson IdName
    | SetConcEquip IdName
    | SetFolder IdName
    | SetTag String
    | SetCustomField ItemFieldValue
    | CustomFieldMsg Comp.CustomFieldMultiInput.Msg
    | SetSource String
    | ResetToSource String
    | GetStatsResp (Result Http.Error SearchStats)
    | GetAllTagsResp (Result Http.Error SearchStats)
    | ToggleAkkordionTab String
    | ToggleOpenAllAkkordionTabs
    | AllBookmarksResp (Result Http.Error AllBookmarks)
    | SelectBookmarkMsg Comp.BookmarkChooser.Msg


setFromStats : SearchStats -> Msg
setFromStats stats =
    GetStatsResp (Ok stats)


linkTargetMsg : LinkTarget -> Maybe Msg
linkTargetMsg linkTarget =
    case linkTarget of
        Comp.LinkTarget.LinkNone ->
            Nothing

        Comp.LinkTarget.LinkCorrOrg id ->
            Just <| SetCorrOrg id

        Comp.LinkTarget.LinkCorrPerson id ->
            Just <| SetCorrPerson id

        Comp.LinkTarget.LinkConcPerson id ->
            Just <| SetConcPerson id

        Comp.LinkTarget.LinkConcEquip id ->
            Just <| SetConcEquip id

        Comp.LinkTarget.LinkFolder id ->
            Just <| SetFolder id

        Comp.LinkTarget.LinkTag id ->
            Just <| SetTag id.id

        Comp.LinkTarget.LinkCustomField id ->
            Just <| SetCustomField id

        Comp.LinkTarget.LinkSource str ->
            Just <| ResetToSource str


type alias NextState =
    { model : Model
    , cmd : Cmd Msg
    , stateChange : Bool
    , dragDrop : DD.DragDropData
    }


refreshBookmarks : Flags -> Cmd Msg
refreshBookmarks flags =
    Api.getBookmarks flags AllBookmarksResp


update : Flags -> UiSettings -> Msg -> Model -> NextState
update =
    updateDrop DD.init


updateDrop : DD.Model -> Flags -> UiSettings -> Msg -> Model -> NextState
updateDrop ddm flags settings msg model =
    let
        resetAndSet : Msg -> NextState
        resetAndSet m =
            let
                reset =
                    resetModel model

                set =
                    updateDrop ddm
                        flags
                        settings
                        m
                        reset
            in
            { model = set.model
            , cmd = set.cmd
            , stateChange = True
            , dragDrop = set.dragDrop
            }
    in
    case msg of
        Init ->
            let
                ( dp, dpc ) =
                    Comp.DatePicker.init

                ( mdp, cdp ) =
                    if model.datePickerInitialized then
                        ( model, Cmd.none )

                    else
                        ( { model
                            | untilDateModel = dp
                            , fromDateModel = dp
                            , untilDueDateModel = dp
                            , fromDueDateModel = dp
                            , datePickerInitialized = True
                          }
                        , Cmd.batch
                            [ Cmd.map UntilDateMsg dpc
                            , Cmd.map FromDateMsg dpc
                            , Cmd.map UntilDueDateMsg dpc
                            , Cmd.map FromDueDateMsg dpc
                            ]
                        )
            in
            { model = mdp
            , cmd =
                Cmd.batch
                    [ Api.itemSearchStats flags Api.Model.ItemQuery.empty GetAllTagsResp
                    , Api.getOrgLight flags GetOrgResp
                    , Api.getEquipments flags "" Data.EquipmentOrder.NameAsc GetEquipResp
                    , Api.getPersons flags "" Data.PersonOrder.NameAsc GetPersonResp
                    , Cmd.map CustomFieldMsg (Comp.CustomFieldMultiInput.initCmd flags)
                    , cdp
                    , Api.getBookmarks flags AllBookmarksResp
                    ]
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        ResetForm ->
            { model = resetModel model
            , cmd = Api.itemSearchStats flags Api.Model.ItemQuery.empty GetAllTagsResp
            , stateChange = True
            , dragDrop = DD.DragDropData ddm Nothing
            }

        SetCorrOrg id ->
            resetAndSet (OrgMsg (Comp.Dropdown.SetSelection [ id ]))

        SetCorrPerson id ->
            resetAndSet (CorrPersonMsg (Comp.Dropdown.SetSelection [ id ]))

        SetConcPerson id ->
            resetAndSet (ConcPersonMsg (Comp.Dropdown.SetSelection [ id ]))

        SetFolder id ->
            case Comp.FolderSelect.setSelected id.id model.folderList of
                Just lm ->
                    resetAndSet (FolderSelectMsg lm)

                Nothing ->
                    { model = model
                    , cmd = Cmd.none
                    , stateChange = False
                    , dragDrop = DD.DragDropData ddm Nothing
                    }

        SetConcEquip id ->
            let
                equip =
                    Equipment id.id
                        id.name
                        0
                        Nothing
                        (Data.EquipmentUse.asString Data.EquipmentUse.Concerning)
            in
            resetAndSet (ConcEquipmentMsg (Comp.Dropdown.SetSelection [ equip ]))

        SetTag id ->
            resetAndSet (TagSelectMsg (Comp.TagSelect.toggleTag id))

        GetAllTagsResp (Ok stats) ->
            let
                tagSel =
                    Comp.TagSelect.modifyAll stats.tagCloud.items
                        stats.tagCategoryCloud.items
                        model.tagSelectModel
            in
            { model = { model | tagSelectModel = tagSel }
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        GetAllTagsResp (Err _) ->
            { model = model
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        GetStatsResp (Ok stats) ->
            let
                tagCount =
                    List.sortBy .count stats.tagCloud.items

                catCount =
                    List.sortBy .count stats.tagCategoryCloud.items

                selectModel =
                    Comp.TagSelect.modifyCountKeepExisting model.tagSelectModel tagCount catCount

                orgOpts =
                    Comp.Dropdown.update (Comp.Dropdown.SetOptions (List.map .ref stats.corrOrgStats))
                        model.orgModel
                        |> Tuple.first

                corrPersOpts =
                    Comp.Dropdown.update (Comp.Dropdown.SetOptions (List.map .ref stats.corrPersStats))
                        model.corrPersonModel
                        |> Tuple.first

                concPersOpts =
                    Comp.Dropdown.update (Comp.Dropdown.SetOptions (List.map .ref stats.concPersStats))
                        model.concPersonModel
                        |> Tuple.first

                concEquipOpts =
                    let
                        mkEquip ref =
                            Equipment ref.id ref.name 0 Nothing ""
                    in
                    Comp.Dropdown.update
                        (Comp.Dropdown.SetOptions
                            (List.map (.ref >> mkEquip) stats.concEquipStats)
                        )
                        model.concEquipmentModel
                        |> Tuple.first

                fields =
                    Util.CustomField.statsToFields stats

                fieldOpts =
                    Comp.CustomFieldMultiInput.update flags
                        (Comp.CustomFieldMultiInput.setOptions fields)
                        model.customFieldModel
                        |> .model

                model_ =
                    { model
                        | tagSelectModel = selectModel
                        , folderList =
                            Comp.FolderSelect.modify model.selectedFolder
                                model.folderList
                                stats.folderStats
                        , orgModel = orgOpts
                        , corrPersonModel = corrPersOpts
                        , concPersonModel = concPersOpts
                        , concEquipmentModel = concEquipOpts
                        , customFieldModel = fieldOpts
                    }
            in
            { model = model_
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        GetStatsResp (Err _) ->
            { model = model
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        GetEquipResp (Ok equips) ->
            let
                opts =
                    Comp.Dropdown.SetOptions equips.items
            in
            update flags settings (ConcEquipmentMsg opts) model

        GetEquipResp (Err _) ->
            { model = model
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        GetOrgResp (Ok orgs) ->
            let
                opts =
                    Comp.Dropdown.SetOptions orgs.items
            in
            update flags settings (OrgMsg opts) model

        GetOrgResp (Err _) ->
            { model = model
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        GetPersonResp (Ok ps) ->
            let
                { concerning, correspondent } =
                    Data.PersonUse.spanPersonList ps.items

                concRefs =
                    List.map (\e -> IdName e.id e.name) concerning

                corrRefs =
                    List.map (\e -> IdName e.id e.name) correspondent

                next1 =
                    updateDrop ddm
                        flags
                        settings
                        (CorrPersonMsg (Comp.Dropdown.SetOptions corrRefs))
                        model

                next2 =
                    updateDrop next1.dragDrop.model
                        flags
                        settings
                        (ConcPersonMsg (Comp.Dropdown.SetOptions concRefs))
                        next1.model
            in
            next2

        GetPersonResp (Err _) ->
            { model = model
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        TagSelectMsg m ->
            let
                ( m_, sel, ddd ) =
                    Comp.TagSelect.updateDrop ddm model.tagSelection m model.tagSelectModel
            in
            { model =
                { model
                    | tagSelectModel = m_
                    , tagSelection = sel
                }
            , cmd = Cmd.none
            , stateChange = sel /= model.tagSelection
            , dragDrop = ddd
            }

        DirectionMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.directionModel
            in
            { model = { model | directionModel = m2 }
            , cmd = Cmd.map DirectionMsg c2
            , stateChange = isDropdownChangeMsg m
            , dragDrop = DD.DragDropData ddm Nothing
            }

        OrgMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.orgModel
            in
            { model = { model | orgModel = m2 }
            , cmd = Cmd.map OrgMsg c2
            , stateChange = isDropdownChangeMsg m
            , dragDrop = DD.DragDropData ddm Nothing
            }

        CorrPersonMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.corrPersonModel
            in
            { model = { model | corrPersonModel = m2 }
            , cmd = Cmd.map CorrPersonMsg c2
            , stateChange = isDropdownChangeMsg m
            , dragDrop = DD.DragDropData ddm Nothing
            }

        ConcPersonMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.concPersonModel
            in
            { model = { model | concPersonModel = m2 }
            , cmd = Cmd.map ConcPersonMsg c2
            , stateChange = isDropdownChangeMsg m
            , dragDrop = DD.DragDropData ddm Nothing
            }

        ConcEquipmentMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.concEquipmentModel
            in
            { model = { model | concEquipmentModel = m2 }
            , cmd = Cmd.map ConcEquipmentMsg c2
            , stateChange = isDropdownChangeMsg m
            , dragDrop = DD.DragDropData ddm Nothing
            }

        ToggleInbox ->
            let
                current =
                    model.inboxCheckbox
            in
            { model = { model | inboxCheckbox = not current }
            , cmd = Cmd.none
            , stateChange = True
            , dragDrop = DD.DragDropData ddm Nothing
            }

        ToggleSearchMode ->
            let
                current =
                    model.searchMode

                next =
                    if current == Data.SearchMode.Normal then
                        Data.SearchMode.Trashed

                    else
                        Data.SearchMode.Normal
            in
            { model = { model | searchMode = next }
            , cmd = Cmd.none
            , stateChange = True
            , dragDrop = DD.DragDropData ddm Nothing
            }

        FromDateMsg m ->
            let
                ( dp, event ) =
                    Comp.DatePicker.updateDefault m model.fromDateModel

                nextDate =
                    case event of
                        DatePicker.Picked date ->
                            Just (Comp.DatePicker.startOfDay date)

                        _ ->
                            Nothing
            in
            { model = { model | fromDateModel = dp, fromDate = nextDate }
            , cmd = Cmd.none
            , stateChange = model.fromDate /= nextDate
            , dragDrop = DD.DragDropData ddm Nothing
            }

        UntilDateMsg m ->
            let
                ( dp, event ) =
                    Comp.DatePicker.updateDefault m model.untilDateModel

                nextDate =
                    case event of
                        DatePicker.Picked date ->
                            Just (Comp.DatePicker.endOfDay date)

                        _ ->
                            Nothing
            in
            { model = { model | untilDateModel = dp, untilDate = nextDate }
            , cmd = Cmd.none
            , stateChange = model.untilDate /= nextDate
            , dragDrop = DD.DragDropData ddm Nothing
            }

        FromDueDateMsg m ->
            let
                ( dp, event ) =
                    Comp.DatePicker.updateDefault m model.fromDueDateModel

                nextDate =
                    case event of
                        DatePicker.Picked date ->
                            Just (Comp.DatePicker.startOfDay date)

                        _ ->
                            Nothing
            in
            { model = { model | fromDueDateModel = dp, fromDueDate = nextDate }
            , cmd = Cmd.none
            , stateChange = model.fromDueDate /= nextDate
            , dragDrop = DD.DragDropData ddm Nothing
            }

        UntilDueDateMsg m ->
            let
                ( dp, event ) =
                    Comp.DatePicker.updateDefault m model.untilDueDateModel

                nextDate =
                    case event of
                        DatePicker.Picked date ->
                            Just (Comp.DatePicker.endOfDay date)

                        _ ->
                            Nothing
            in
            { model = { model | untilDueDateModel = dp, untilDueDate = nextDate }
            , cmd = Cmd.none
            , stateChange = model.untilDueDate /= nextDate
            , dragDrop = DD.DragDropData ddm Nothing
            }

        SetName str ->
            let
                next =
                    Util.Maybe.fromString str
            in
            { model = { model | nameModel = next }
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        SetTextSearch str ->
            { model = { model | textSearchModel = updateTextSearch str model.textSearchModel }
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        SwapTextSearch ->
            if flags.config.fullTextSearchEnabled then
                { model = { model | textSearchModel = swapTextSearch model.textSearchModel }
                , cmd = Cmd.none
                , stateChange = False
                , dragDrop = DD.DragDropData ddm Nothing
                }

            else
                { model = model
                , cmd = Cmd.none
                , stateChange = False
                , dragDrop = DD.DragDropData ddm Nothing
                }

        SetFulltextSearch ->
            case model.textSearchModel of
                Fulltext _ ->
                    { model = model
                    , cmd = Cmd.none
                    , stateChange = False
                    , dragDrop = DD.DragDropData ddm Nothing
                    }

                Names s ->
                    { model = { model | textSearchModel = Fulltext s }
                    , cmd = Cmd.none
                    , stateChange = False
                    , dragDrop = DD.DragDropData ddm Nothing
                    }

        SetNamesSearch ->
            case model.textSearchModel of
                Fulltext s ->
                    { model = { model | textSearchModel = Names s }
                    , cmd = Cmd.none
                    , stateChange = False
                    , dragDrop = DD.DragDropData ddm Nothing
                    }

                Names _ ->
                    { model = model
                    , cmd = Cmd.none
                    , stateChange = False
                    , dragDrop = DD.DragDropData ddm Nothing
                    }

        KeyUpMsg (Just Enter) ->
            { model = model
            , cmd = Cmd.none
            , stateChange = True
            , dragDrop = DD.DragDropData ddm Nothing
            }

        KeyUpMsg _ ->
            { model = model
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        FolderSelectMsg lm ->
            let
                ( fsm, sel, ddd ) =
                    Comp.FolderSelect.updateDrop ddm lm model.folderList
            in
            { model =
                { model
                    | folderList = fsm
                    , selectedFolder = sel
                }
            , cmd = Cmd.none
            , stateChange = model.selectedFolder /= sel
            , dragDrop = ddd
            }

        CustomFieldMsg lm ->
            let
                res =
                    Comp.CustomFieldMultiInput.updateSearch flags lm model.customFieldModel
            in
            { model =
                { model
                    | customFieldModel = res.model
                    , customValues = Data.CustomFieldChange.collectValues res.result model.customValues
                }
            , cmd = Cmd.map CustomFieldMsg res.cmd
            , stateChange =
                Data.CustomFieldChange.isValueChange res.result
            , dragDrop = DD.DragDropData ddm Nothing
            }

        SetCustomField cv ->
            let
                lm =
                    Comp.CustomFieldMultiInput.setValues [ cv ]

                values =
                    Data.CustomFieldChange.fromItemValues [ cv ]

                next =
                    resetAndSet (CustomFieldMsg lm)

                m =
                    next.model
            in
            { next | model = { m | customValues = values } }

        SetSource str ->
            let
                next =
                    Util.Maybe.fromString str
            in
            { model = { model | sourceModel = next }
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        ResetToSource str ->
            resetAndSet (SetSource str)

        ToggleAkkordionTab title ->
            let
                tabs =
                    if Set.member title model.openTabs then
                        Set.remove title model.openTabs

                    else
                        Set.insert title model.openTabs
            in
            { model = { model | openTabs = tabs }
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        ToggleOpenAllAkkordionTabs ->
            let
                allNames =
                    List.map tabName allTabs
                        |> Set.fromList

                next =
                    if model.openTabs == allNames then
                        Set.empty

                    else
                        allNames
            in
            { model = { model | openTabs = next }
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        AllBookmarksResp (Ok bm) ->
            { model = { model | allBookmarks = Comp.BookmarkChooser.init bm }
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        AllBookmarksResp (Err err) ->
            { model = model
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        SelectBookmarkMsg lm ->
            let
                ( next, sel ) =
                    Comp.BookmarkChooser.update lm model.allBookmarks model.selectedBookmarks
            in
            { model = { model | allBookmarks = next, selectedBookmarks = sel }
            , cmd = Cmd.none
            , stateChange = sel /= model.selectedBookmarks
            , dragDrop = DD.DragDropData ddm Nothing
            }



--- View2


type alias ViewConfig =
    { overrideTabLook : SearchTab -> Comp.Tabs.Look -> Comp.Tabs.Look
    }


viewDrop2 : Texts -> DD.DragDropData -> Flags -> ViewConfig -> UiSettings -> Model -> Html Msg
viewDrop2 texts ddd flags cfg settings model =
    let
        akkordionStyle =
            Comp.Tabs.searchMenuStyle
    in
    Comp.Tabs.akkordion
        akkordionStyle
        (searchTabState settings cfg model)
        (searchTabs texts ddd flags settings model)


type SearchTab
    = TabInbox
    | TabBookmarks
    | TabTags
    | TabTagCategories
    | TabFolder
    | TabCorrespondent
    | TabConcerning
    | TabCustomFields
    | TabDate
    | TabDueDate
    | TabSource
    | TabDirection
    | TabTrashed


allTabs : List SearchTab
allTabs =
    [ TabInbox
    , TabBookmarks
    , TabTags
    , TabTagCategories
    , TabFolder
    , TabCorrespondent
    , TabConcerning
    , TabCustomFields
    , TabDate
    , TabDueDate
    , TabSource
    , TabDirection
    , TabTrashed
    ]


tabName : SearchTab -> String
tabName tab =
    case tab of
        TabInbox ->
            "inbox"

        TabBookmarks ->
            "bookmarks"

        TabTags ->
            "tags"

        TabTagCategories ->
            "categories"

        TabFolder ->
            "folder"

        TabCorrespondent ->
            "correspondent"

        TabConcerning ->
            "concerning"

        TabCustomFields ->
            "custom-fields"

        TabDate ->
            "date"

        TabDueDate ->
            "due-date"

        TabSource ->
            "source"

        TabDirection ->
            "direction"

        TabTrashed ->
            "trashed"


findTab : Comp.Tabs.Tab msg -> Maybe SearchTab
findTab tab =
    case tab.name of
        "inbox" ->
            Just TabInbox

        "bookmarks" ->
            Just TabBookmarks

        "tags" ->
            Just TabTags

        "categories" ->
            Just TabTagCategories

        "folder" ->
            Just TabFolder

        "correspondent" ->
            Just TabCorrespondent

        "concerning" ->
            Just TabConcerning

        "custom-fields" ->
            Just TabCustomFields

        "date" ->
            Just TabDate

        "due-date" ->
            Just TabDueDate

        "source" ->
            Just TabSource

        "direction" ->
            Just TabDirection

        "trashed" ->
            Just TabTrashed

        _ ->
            Nothing


tabLook : UiSettings -> Model -> SearchTab -> Comp.Tabs.Look
tabLook settings model tab =
    let
        isHidden f =
            Data.UiSettings.fieldHidden settings f

        hiddenOr fields default =
            if List.all isHidden fields then
                Comp.Tabs.Hidden

            else
                default

        activeWhen flag =
            if flag then
                Comp.Tabs.Active

            else
                Comp.Tabs.Normal

        activeWhenNotEmpty list1 list2 =
            if List.isEmpty list1 && List.isEmpty list2 then
                Comp.Tabs.Normal

            else
                Comp.Tabs.Active

        activeWhenJust mx =
            if mx == Nothing then
                Comp.Tabs.Normal

            else
                Comp.Tabs.Active
    in
    case tab of
        TabInbox ->
            activeWhen model.inboxCheckbox

        TabBookmarks ->
            if Comp.BookmarkChooser.isEmpty model.allBookmarks then
                Comp.Tabs.Hidden

            else if not <| Comp.BookmarkChooser.isEmptySelection model.selectedBookmarks then
                Comp.Tabs.Active

            else
                Comp.Tabs.Normal

        TabTags ->
            hiddenOr [ Data.Fields.Tag ]
                (activeWhenNotEmpty model.tagSelection.includeTags model.tagSelection.excludeTags)

        TabTagCategories ->
            hiddenOr [ Data.Fields.Tag ]
                (activeWhenNotEmpty model.tagSelection.includeCats model.tagSelection.excludeCats)

        TabFolder ->
            hiddenOr [ Data.Fields.Folder ]
                (activeWhenJust model.selectedFolder)

        TabCorrespondent ->
            hiddenOr [ Data.Fields.CorrOrg, Data.Fields.CorrPerson ] <|
                activeWhenNotEmpty (Comp.Dropdown.getSelected model.orgModel)
                    (Comp.Dropdown.getSelected model.corrPersonModel)

        TabConcerning ->
            hiddenOr [ Data.Fields.ConcPerson, Data.Fields.ConcEquip ] <|
                activeWhenNotEmpty (Comp.Dropdown.getSelected model.concPersonModel)
                    (Comp.Dropdown.getSelected model.concEquipmentModel)

        TabDate ->
            hiddenOr [ Data.Fields.Date ] <|
                activeWhenJust (Util.Maybe.or [ model.fromDate, model.untilDate ])

        TabDueDate ->
            hiddenOr [ Data.Fields.DueDate ] <|
                activeWhenJust (Util.Maybe.or [ model.fromDueDate, model.untilDueDate ])

        TabSource ->
            hiddenOr [ Data.Fields.SourceName ] <|
                activeWhenJust model.sourceModel

        TabDirection ->
            hiddenOr [ Data.Fields.Direction ] <|
                activeWhenNotEmpty (Comp.Dropdown.getSelected model.directionModel) []

        TabTrashed ->
            activeWhen (model.searchMode == Data.SearchMode.Trashed)

        _ ->
            Comp.Tabs.Normal


searchTabState : UiSettings -> ViewConfig -> Model -> Comp.Tabs.Tab Msg -> ( Comp.Tabs.State, Msg )
searchTabState settings cfg model tab =
    let
        searchTab =
            findTab tab

        folded =
            if Set.member tab.name model.openTabs then
                Comp.Tabs.Open

            else
                Comp.Tabs.Closed

        state =
            { folded = folded
            , look =
                Maybe.map (\t -> tabLook settings model t |> cfg.overrideTabLook t) searchTab
                    |> Maybe.withDefault Comp.Tabs.Normal
            }
    in
    ( state, ToggleAkkordionTab tab.name )


searchTabs : Texts -> DD.DragDropData -> Flags -> UiSettings -> Model -> List (Comp.Tabs.Tab Msg)
searchTabs texts ddd flags settings model =
    let
        isHidden f =
            Data.UiSettings.fieldHidden settings f

        tagSelectWM =
            Comp.TagSelect.makeWorkModel model.tagSelection model.tagSelectModel

        directionCfg =
            { makeOption =
                \entry ->
                    { text = texts.direction entry
                    , additional = ""
                    }
            , placeholder = texts.chooseDirection
            , labelColor = \_ -> \_ -> ""
            , style = DS.sidebarStyle
            }

        personCfg =
            { makeOption = \e -> { text = e.name, additional = "" }
            , placeholder = texts.choosePerson
            , labelColor = \_ -> \_ -> ""
            , style = DS.sidebarStyle
            }

        concEquipCfg =
            { makeOption = \e -> { text = e.name, additional = "" }
            , labelColor = \_ -> \_ -> ""
            , placeholder = texts.chooseEquipment
            , style = DS.sidebarStyle
            }
    in
    [ { name = tabName TabInbox
      , title = texts.inbox
      , info = Nothing
      , titleRight = []
      , body =
            [ MB.viewItem <|
                MB.Checkbox
                    { id = "search-inbox"
                    , value = model.inboxCheckbox
                    , label = texts.inbox
                    , tagger = \_ -> ToggleInbox
                    }
            ]
      }
    , { name = tabName TabBookmarks
      , title = texts.bookmarks
      , titleRight = []
      , info = Nothing
      , body =
            [ Html.map SelectBookmarkMsg
                (Comp.BookmarkChooser.view texts.bookmarkChooser model.allBookmarks model.selectedBookmarks)
            ]
      }
    , { name = tabName TabTags
      , title = texts.basics.tags
      , titleRight = []
      , info = Nothing
      , body =
            List.map (Html.map TagSelectMsg)
                (Comp.TagSelect.viewTagsDrop2
                    texts.tagSelect
                    ddd.model
                    tagSelectWM
                    settings
                    model.tagSelectModel
                )
      }
    , { name = tabName TabTagCategories
      , title = texts.tagCategoryTab
      , titleRight = []
      , info = Nothing
      , body =
            [ Html.map TagSelectMsg
                (Comp.TagSelect.viewCats2
                    texts.tagSelect
                    settings
                    tagSelectWM
                    model.tagSelectModel
                )
            ]
      }
    , { name = tabName TabFolder
      , title = texts.basics.folder
      , titleRight = []
      , info = Nothing
      , body =
            [ Html.map FolderSelectMsg
                (Comp.FolderSelect.viewDrop2 texts.folderSelect
                    ddd.model
                    settings.searchMenuFolderCount
                    model.folderList
                )
            ]
      }
    , { name = tabName TabCorrespondent
      , title = texts.basics.correspondent
      , titleRight = []
      , info = Nothing
      , body =
            [ div
                [ class "mb-4"
                , classList [ ( "hidden", isHidden Data.Fields.CorrOrg ) ]
                ]
                [ label [ class S.inputLabel ]
                    [ text texts.basics.organization ]
                , Html.map OrgMsg
                    (Comp.Dropdown.view2
                        (Comp.Dropdown.orgFormViewSettings texts.chooseOrganization DS.sidebarStyle)
                        settings
                        model.orgModel
                    )
                ]
            , div
                [ class "mb-4"
                , classList [ ( "hidden", isHidden Data.Fields.CorrPerson ) ]
                ]
                [ label [ class S.inputLabel ] [ text texts.basics.person ]
                , Html.map CorrPersonMsg
                    (Comp.Dropdown.view2
                        personCfg
                        settings
                        model.corrPersonModel
                    )
                ]
            ]
      }
    , { name = tabName TabConcerning
      , title = texts.basics.concerning
      , titleRight = []
      , info = Nothing
      , body =
            [ div
                [ class "mb-4"
                , classList [ ( "hidden", isHidden Data.Fields.ConcPerson ) ]
                ]
                [ label [ class S.inputLabel ] [ text texts.basics.person ]
                , Html.map ConcPersonMsg
                    (Comp.Dropdown.view2
                        personCfg
                        settings
                        model.concPersonModel
                    )
                ]
            , div
                [ class "mb-4"
                , classList [ ( "hidden", isHidden Data.Fields.ConcEquip ) ]
                ]
                [ label [ class S.inputLabel ] [ text texts.basics.equipment ]
                , Html.map ConcEquipmentMsg
                    (Comp.Dropdown.view2
                        concEquipCfg
                        settings
                        model.concEquipmentModel
                    )
                ]
            ]
      }
    , { name = tabName TabCustomFields
      , title = texts.basics.customFields
      , titleRight = []
      , info = Nothing
      , body =
            [ Html.map CustomFieldMsg
                (Comp.CustomFieldMultiInput.view2
                    texts.customFieldMultiInput
                    { showAddButton = False
                    , classes = ""
                    , fieldIcon = \_ -> Nothing
                    , style = DS.sidebarStyle
                    , createCustomFieldTitle = texts.createCustomFieldTitle
                    , selectPlaceholder = texts.basics.selectPlaceholder
                    }
                    model.customFieldModel
                )
            ]
      }
    , { name = tabName TabDate
      , title = texts.basics.date
      , titleRight = []
      , info = Nothing
      , body =
            [ div
                [ class "flex flex-col" ]
                [ div [ class "mb-2" ]
                    [ label [ class S.inputLabel ]
                        [ text texts.from
                        ]
                    , div [ class "relative" ]
                        [ Html.map FromDateMsg
                            (Comp.DatePicker.viewTimeDefault
                                model.fromDate
                                model.fromDateModel
                            )
                        , i
                            [ class S.dateInputIcon
                            , class "fa fa-calendar"
                            ]
                            []
                        ]
                    ]
                , div [ class "mb-2" ]
                    [ label [ class S.inputLabel ]
                        [ text texts.to
                        ]
                    , div [ class "relative" ]
                        [ Html.map UntilDateMsg
                            (Comp.DatePicker.viewTimeDefault
                                model.untilDate
                                model.untilDateModel
                            )
                        , i [ class S.dateInputIcon, class "fa fa-calendar" ] []
                        ]
                    ]
                ]
            ]
      }
    , { name = tabName TabDueDate
      , title = texts.dueDateTab
      , titleRight = []
      , info = Nothing
      , body =
            [ div
                [ class "flex flex-col" ]
                [ div [ class "mb-2" ]
                    [ label [ class S.inputLabel ]
                        [ text texts.dueFrom
                        ]
                    , div [ class "relative" ]
                        [ Html.map FromDueDateMsg
                            (Comp.DatePicker.viewTimeDefault
                                model.fromDueDate
                                model.fromDueDateModel
                            )
                        , i
                            [ class "fa fa-calendar"
                            , class S.dateInputIcon
                            ]
                            []
                        ]
                    ]
                , div [ class "mb-2" ]
                    [ label [ class S.inputLabel ]
                        [ text texts.dueTo
                        ]
                    , div [ class "relative" ]
                        [ Html.map UntilDueDateMsg
                            (Comp.DatePicker.viewTimeDefault
                                model.untilDueDate
                                model.untilDueDateModel
                            )
                        , i
                            [ class "fa fa-calendar"
                            , class S.dateInputIcon
                            ]
                            []
                        ]
                    ]
                ]
            ]
      }
    , { name = tabName TabSource
      , title = texts.sourceTab
      , titleRight = []
      , info = Nothing
      , body =
            [ div [ class "mb-4" ]
                [ input
                    [ type_ "text"
                    , onInput SetSource
                    , Util.Html.onKeyUpCode KeyUpMsg
                    , model.sourceModel |> Maybe.withDefault "" |> value
                    , placeholder texts.searchInItemSource
                    , class S.textInputSidebar
                    ]
                    []
                ]
            ]
      }
    , { name = tabName TabDirection
      , title = texts.basics.direction
      , titleRight = []
      , info = Nothing
      , body =
            [ Html.map DirectionMsg
                (Comp.Dropdown.view2
                    directionCfg
                    settings
                    model.directionModel
                )
            ]
      }
    , { name = tabName TabTrashed
      , title = texts.trashcan
      , titleRight = []
      , info = Nothing
      , body =
            [ MB.viewItem <|
                MB.Checkbox
                    { id = "trashed"
                    , value = model.searchMode == Data.SearchMode.Trashed
                    , label = texts.trashcan
                    , tagger = \_ -> ToggleSearchMode
                    }
            ]
      }
    ]
