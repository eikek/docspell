{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.ItemDetail.Model exposing
    ( AttachmentRename
    , ConfirmModalValue(..)
    , MailSendResult(..)
    , Model
    , Msg(..)
    , NotesField(..)
    , SaveNameState(..)
    , SelectActionMode(..)
    , UpdateResult
    , ViewMode(..)
    , emptyModel
    , initSelectViewModel
    , initShowQrModel
    , isEditNotes
    , isShowQrAttach
    , isShowQrItem
    , personMatchesOrg
    , resultModel
    , resultModelCmd
    , resultModelCmdSub
    )

import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.CustomField exposing (CustomField)
import Api.Model.EquipmentList exposing (EquipmentList)
import Api.Model.FolderItem exposing (FolderItem)
import Api.Model.FolderList exposing (FolderList)
import Api.Model.IdName exposing (IdName)
import Api.Model.ItemDetail exposing (ItemDetail)
import Api.Model.ItemProposals exposing (ItemProposals)
import Api.Model.Person exposing (Person)
import Api.Model.PersonList exposing (PersonList)
import Api.Model.ReferenceList exposing (ReferenceList)
import Api.Model.SentMails exposing (SentMails)
import Api.Model.Tag exposing (Tag)
import Api.Model.TagList exposing (TagList)
import Comp.AttachmentMeta
import Comp.CustomFieldMultiInput
import Comp.DatePicker
import Comp.DetailEdit
import Comp.Dropdown
import Comp.Dropzone
import Comp.ItemMail
import Comp.KeyInput
import Comp.LinkTarget exposing (LinkTarget)
import Comp.MarkdownInput
import Comp.SentMails
import Comp.TagDropdown
import Data.Direction exposing (Direction)
import Data.Fields exposing (Field)
import DatePicker exposing (DatePicker)
import Dict exposing (Dict)
import File exposing (File)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html5.DragDrop as DD
import Http
import Page exposing (Page(..))
import Set exposing (Set)
import Throttle exposing (Throttle)
import Util.Tag


type alias Model =
    { item : ItemDetail
    , visibleAttach : Int
    , attachMenuOpen : Bool
    , menuOpen : Bool
    , tagModel : Comp.TagDropdown.Model
    , directionModel : Comp.Dropdown.Model Direction
    , corrOrgModel : Comp.Dropdown.Model IdName
    , corrPersonModel : Comp.Dropdown.Model IdName
    , concPersonModel : Comp.Dropdown.Model IdName
    , concEquipModel : Comp.Dropdown.Model IdName
    , folderModel : Comp.Dropdown.Model IdName
    , allFolders : List FolderItem
    , nameModel : String
    , nameState : SaveNameState
    , nameSaveThrottle : Throttle Msg
    , notesModel : Maybe String
    , notesField : NotesField
    , itemModal : Maybe ConfirmModalValue
    , itemDatePicker : DatePicker
    , itemDate : Maybe Int
    , itemProposals : ItemProposals
    , dueDate : Maybe Int
    , dueDatePicker : DatePicker
    , itemMail : Comp.ItemMail.Model
    , mailOpen : Bool
    , mailSending : Bool
    , mailSendResult : MailSendResult
    , sentMails : Comp.SentMails.Model
    , sentMailsOpen : Bool
    , attachMeta : Dict String Comp.AttachmentMeta.Model
    , attachMetaOpen : Bool
    , attachModal : Maybe ConfirmModalValue
    , addFilesOpen : Bool
    , addFilesModel : Comp.Dropzone.Model
    , selectedFiles : List File
    , completed : Set String
    , errored : Set String
    , loading : Dict String Int
    , attachDD : DD.Model String String
    , modalEdit : Maybe Comp.DetailEdit.Model
    , attachRename : Maybe AttachmentRename
    , keyInputModel : Comp.KeyInput.Model
    , customFieldsModel : Comp.CustomFieldMultiInput.Model
    , customFieldSavingIcon : Dict String String
    , customFieldThrottle : Throttle Msg
    , allTags : List Tag
    , allPersons : Dict String Person
    , attachmentDropdownOpen : Bool
    , editMenuTabsOpen : Set String
    , viewMode : ViewMode
    , showQrModel : ShowQrModel
    }


type alias ShowQrModel =
    { item : Bool
    , attach : Bool
    }


initShowQrModel : ShowQrModel
initShowQrModel =
    { item = False
    , attach = False
    }


isShowQrItem : ShowQrModel -> Bool
isShowQrItem model =
    model.item


isShowQrAttach : ShowQrModel -> Bool
isShowQrAttach model =
    model.attach


type ConfirmModalValue
    = ConfirmModalReprocessItem Msg
    | ConfirmModalReprocessFile Msg
    | ConfirmModalDeleteItem Msg
    | ConfirmModalDeleteFile Msg
    | ConfirmModalDeleteAllFiles Msg


type ViewMode
    = SimpleView
    | SelectView SelectViewModel


type alias SelectViewModel =
    { ids : Set String
    , action : SelectActionMode
    }


type SelectActionMode
    = NoneAction
    | DeleteSelected


type MailSendResult
    = MailSendSuccessful
    | MailSendHttpError Http.Error
    | MailSendFailed String
    | MailSendResultInitial


type NotesField
    = ViewNotes
    | EditNotes Comp.MarkdownInput.Model


type alias AttachmentRename =
    { id : String
    , newName : String
    }


isEditNotes : NotesField -> Bool
isEditNotes field =
    case field of
        EditNotes _ ->
            True

        ViewNotes ->
            False


emptyModel : Model
emptyModel =
    { item = Api.Model.ItemDetail.empty
    , visibleAttach = 0
    , attachMenuOpen = False
    , menuOpen = False
    , tagModel = Comp.TagDropdown.emptyModel
    , directionModel =
        Comp.Dropdown.makeSingleList
            { options = Data.Direction.all
            , selected = Nothing
            }
    , corrOrgModel = Comp.Dropdown.makeSingle
    , corrPersonModel = Comp.Dropdown.makeSingle
    , concPersonModel = Comp.Dropdown.makeSingle
    , concEquipModel = Comp.Dropdown.makeSingle
    , folderModel = Comp.Dropdown.makeSingle
    , allFolders = []
    , nameModel = ""
    , nameState = SaveSuccess
    , nameSaveThrottle = Throttle.create 1
    , notesModel = Nothing
    , notesField = ViewNotes
    , itemModal = Nothing
    , itemDatePicker = Comp.DatePicker.emptyModel
    , itemDate = Nothing
    , itemProposals = Api.Model.ItemProposals.empty
    , dueDate = Nothing
    , dueDatePicker = Comp.DatePicker.emptyModel
    , itemMail = Comp.ItemMail.emptyModel
    , mailOpen = False
    , mailSending = False
    , mailSendResult = MailSendResultInitial
    , sentMails = Comp.SentMails.init
    , sentMailsOpen = False
    , attachMeta = Dict.empty
    , attachMetaOpen = False
    , attachModal = Nothing
    , addFilesOpen = False
    , addFilesModel = Comp.Dropzone.init []
    , selectedFiles = []
    , completed = Set.empty
    , errored = Set.empty
    , loading = Dict.empty
    , attachDD = DD.init
    , modalEdit = Nothing
    , attachRename = Nothing
    , keyInputModel = Comp.KeyInput.init
    , customFieldsModel = Comp.CustomFieldMultiInput.initWith []
    , customFieldSavingIcon = Dict.empty
    , customFieldThrottle = Throttle.create 1
    , allTags = []
    , allPersons = Dict.empty
    , attachmentDropdownOpen = False
    , editMenuTabsOpen = Set.empty
    , viewMode = SimpleView
    , showQrModel = initShowQrModel
    }


initSelectViewModel : SelectViewModel
initSelectViewModel =
    { ids = Set.empty
    , action = NoneAction
    }


type Msg
    = ToggleMenu
    | ReloadItem
    | Init
    | SetItem ItemDetail
    | SetActiveAttachment Int
    | ToggleAttachment String
    | TagDropdownMsg Comp.TagDropdown.Msg
    | DirDropdownMsg (Comp.Dropdown.Msg Direction)
    | OrgDropdownMsg (Comp.Dropdown.Msg IdName)
    | CorrPersonMsg (Comp.Dropdown.Msg IdName)
    | ConcPersonMsg (Comp.Dropdown.Msg IdName)
    | ConcEquipMsg (Comp.Dropdown.Msg IdName)
    | GetTagsResp (Result Http.Error TagList)
    | GetOrgResp (Result Http.Error ReferenceList)
    | GetPersonResp (Result Http.Error PersonList)
    | GetEquipResp (Result Http.Error EquipmentList)
    | SetName String
    | SetNotes String
    | ToggleEditNotes
    | NotesEditMsg Comp.MarkdownInput.Msg
    | SaveNotes
    | ConfirmItem
    | UnconfirmItem
    | SetCorrOrgSuggestion IdName
    | SetCorrPersonSuggestion IdName
    | SetConcPersonSuggestion IdName
    | SetConcEquipSuggestion IdName
    | SetItemDateSuggestion Int
    | SetDueDateSuggestion Int
    | ItemDatePickerMsg Comp.DatePicker.Msg
    | DueDatePickerMsg Comp.DatePicker.Msg
    | DeleteItemConfirmed
    | ItemModalCancelled
    | RequestDelete
    | SaveResp (Result Http.Error BasicResult)
    | DeleteResp String (Result Http.Error BasicResult)
    | GetItemResp (Result Http.Error ItemDetail)
    | GetProposalResp (Result Http.Error ItemProposals)
    | RemoveDueDate
    | RemoveDate
    | ItemMailMsg Comp.ItemMail.Msg
    | ToggleMail
    | SendMailResp (Result Http.Error BasicResult)
    | SentMailsMsg Comp.SentMails.Msg
    | ToggleSentMails
    | SentMailsResp (Result Http.Error SentMails)
    | AttachMetaClick String
    | AttachMetaMsg String Comp.AttachmentMeta.Msg
    | RequestDeleteAttachment String
    | DeleteAttachConfirmed String
    | RequestDeleteSelected
    | DeleteSelectedConfirmed
    | AttachModalCancelled
    | DeleteAttachResp (Result Http.Error BasicResult)
    | AddFilesToggle
    | AddFilesMsg Comp.Dropzone.Msg
    | AddFilesSubmitUpload
    | AddFilesUploadResp String (Result Http.Error BasicResult)
    | AddFilesProgress String Http.Progress
    | AddFilesReset
    | AttachDDMsg (DD.Msg String String)
    | ModalEditMsg Comp.DetailEdit.Msg
    | StartTagModal
    | StartCorrOrgModal
    | StartCorrPersonModal
    | StartConcPersonModal
    | StartEquipModal
    | CloseModal
    | EditAttachNameStart String
    | EditAttachNameCancel
    | EditAttachNameSet String
    | EditAttachNameSubmit
    | EditAttachNameResp (Result Http.Error BasicResult)
    | GetFolderResp (Result Http.Error FolderList)
    | FolderDropdownMsg (Comp.Dropdown.Msg IdName)
    | StartEditCorrOrgModal
    | StartEditPersonModal (Comp.Dropdown.Model IdName)
    | StartEditEquipModal
    | ResetHiddenMsg Field (Result Http.Error BasicResult)
    | SaveNameResp (Result Http.Error BasicResult)
    | UpdateThrottle
    | KeyInputMsg Comp.KeyInput.Msg
    | ToggleAttachMenu
    | UiSettingsUpdated
    | SetLinkTarget LinkTarget
    | CustomFieldMsg Comp.CustomFieldMultiInput.Msg
    | CustomFieldSaveResp CustomField String (Result Http.Error BasicResult)
    | CustomFieldRemoveResp String (Result Http.Error BasicResult)
    | ToggleAttachmentDropdown
    | ToggleAkkordionTab String
    | ToggleOpenAllAkkordionTabs
    | RequestReprocessFile String
    | ReprocessFileConfirmed String
    | ReprocessFileResp (Result Http.Error BasicResult)
    | RequestReprocessItem
    | ReprocessItemConfirmed
    | ToggleSelectView
    | RestoreItem
    | ToggleShowQrItem String
    | ToggleShowQrAttach String
    | PrintElement String


type SaveNameState
    = Saving
    | SaveSuccess
    | SaveFailed


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    , linkTarget : LinkTarget
    , removedItem : Maybe String
    }


resultModel : Model -> UpdateResult
resultModel model =
    UpdateResult model Cmd.none Sub.none Comp.LinkTarget.LinkNone Nothing


resultModelCmd : ( Model, Cmd Msg ) -> UpdateResult
resultModelCmd ( model, cmd ) =
    UpdateResult model cmd Sub.none Comp.LinkTarget.LinkNone Nothing


resultModelCmdSub : ( Model, Cmd Msg, Sub Msg ) -> UpdateResult
resultModelCmdSub ( model, cmd, sub ) =
    UpdateResult model cmd sub Comp.LinkTarget.LinkNone Nothing


personMatchesOrg : Model -> Bool
personMatchesOrg model =
    let
        org =
            Comp.Dropdown.getSelected model.corrOrgModel
                |> List.head

        pers =
            Comp.Dropdown.getSelected model.corrPersonModel
                |> List.head

        persOrg =
            pers
                |> Maybe.andThen (\idref -> Dict.get idref.id model.allPersons)
                |> Maybe.andThen .organization
    in
    org == Nothing || pers == Nothing || org == persOrg
