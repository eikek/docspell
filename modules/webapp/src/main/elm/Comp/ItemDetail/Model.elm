module Comp.ItemDetail.Model exposing
    ( AttachmentRename
    , Model
    , Msg(..)
    , NotesField(..)
    , SaveNameState(..)
    , emptyModel
    , isEditNotes
    )

import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.EquipmentList exposing (EquipmentList)
import Api.Model.FolderItem exposing (FolderItem)
import Api.Model.FolderList exposing (FolderList)
import Api.Model.IdName exposing (IdName)
import Api.Model.ItemDetail exposing (ItemDetail)
import Api.Model.ItemProposals exposing (ItemProposals)
import Api.Model.ReferenceList exposing (ReferenceList)
import Api.Model.SentMails exposing (SentMails)
import Api.Model.Tag exposing (Tag)
import Api.Model.TagList exposing (TagList)
import Comp.AttachmentMeta
import Comp.DatePicker
import Comp.DetailEdit
import Comp.Dropdown
import Comp.Dropzone
import Comp.ItemMail
import Comp.KeyInput
import Comp.LinkTarget exposing (LinkTarget)
import Comp.MarkdownInput
import Comp.SentMails
import Comp.YesNoDimmer
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
    , tagModel : Comp.Dropdown.Model Tag
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
    , deleteItemConfirm : Comp.YesNoDimmer.Model
    , itemDatePicker : DatePicker
    , itemDate : Maybe Int
    , itemProposals : ItemProposals
    , dueDate : Maybe Int
    , dueDatePicker : DatePicker
    , itemMail : Comp.ItemMail.Model
    , mailOpen : Bool
    , mailSending : Bool
    , mailSendResult : Maybe BasicResult
    , sentMails : Comp.SentMails.Model
    , sentMailsOpen : Bool
    , attachMeta : Dict String Comp.AttachmentMeta.Model
    , attachMetaOpen : Bool
    , pdfNativeView : Maybe Bool
    , deleteAttachConfirm : Comp.YesNoDimmer.Model
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
    }


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
    , tagModel =
        Util.Tag.makeDropdownModel
    , directionModel =
        Comp.Dropdown.makeSingleList
            { makeOption =
                \entry ->
                    { value = Data.Direction.toString entry
                    , text = Data.Direction.toString entry
                    , additional = ""
                    }
            , options = Data.Direction.all
            , placeholder = "Choose a direction…"
            , selected = Nothing
            }
    , corrOrgModel =
        Comp.Dropdown.makeSingle
            { makeOption = \e -> { value = e.id, text = e.name, additional = "" }
            , placeholder = ""
            }
    , corrPersonModel =
        Comp.Dropdown.makeSingle
            { makeOption = \e -> { value = e.id, text = e.name, additional = "" }
            , placeholder = ""
            }
    , concPersonModel =
        Comp.Dropdown.makeSingle
            { makeOption = \e -> { value = e.id, text = e.name, additional = "" }
            , placeholder = ""
            }
    , concEquipModel =
        Comp.Dropdown.makeSingle
            { makeOption = \e -> { value = e.id, text = e.name, additional = "" }
            , placeholder = ""
            }
    , folderModel =
        Comp.Dropdown.makeSingle
            { makeOption = \e -> { value = e.id, text = e.name, additional = "" }
            , placeholder = ""
            }
    , allFolders = []
    , nameModel = ""
    , nameState = SaveSuccess
    , nameSaveThrottle = Throttle.create 1
    , notesModel = Nothing
    , notesField = ViewNotes
    , deleteItemConfirm = Comp.YesNoDimmer.emptyModel
    , itemDatePicker = Comp.DatePicker.emptyModel
    , itemDate = Nothing
    , itemProposals = Api.Model.ItemProposals.empty
    , dueDate = Nothing
    , dueDatePicker = Comp.DatePicker.emptyModel
    , itemMail = Comp.ItemMail.emptyModel
    , mailOpen = False
    , mailSending = False
    , mailSendResult = Nothing
    , sentMails = Comp.SentMails.init
    , sentMailsOpen = False
    , attachMeta = Dict.empty
    , attachMetaOpen = False
    , pdfNativeView = Nothing
    , deleteAttachConfirm = Comp.YesNoDimmer.emptyModel
    , addFilesOpen = False
    , addFilesModel = Comp.Dropzone.init Comp.Dropzone.defaultSettings
    , selectedFiles = []
    , completed = Set.empty
    , errored = Set.empty
    , loading = Dict.empty
    , attachDD = DD.init
    , modalEdit = Nothing
    , attachRename = Nothing
    , keyInputModel = Comp.KeyInput.init
    }


type Msg
    = ToggleMenu
    | ReloadItem
    | Init
    | SetItem ItemDetail
    | SetActiveAttachment Int
    | TagDropdownMsg (Comp.Dropdown.Msg Tag)
    | DirDropdownMsg (Comp.Dropdown.Msg Direction)
    | OrgDropdownMsg (Comp.Dropdown.Msg IdName)
    | CorrPersonMsg (Comp.Dropdown.Msg IdName)
    | ConcPersonMsg (Comp.Dropdown.Msg IdName)
    | ConcEquipMsg (Comp.Dropdown.Msg IdName)
    | GetTagsResp (Result Http.Error TagList)
    | GetOrgResp (Result Http.Error ReferenceList)
    | GetPersonResp (Result Http.Error ReferenceList)
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
    | DeleteItemConfirm Comp.YesNoDimmer.Msg
    | RequestDelete
    | SaveResp (Result Http.Error BasicResult)
    | DeleteResp (Result Http.Error BasicResult)
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
    | TogglePdfNativeView Bool
    | RequestDeleteAttachment String
    | DeleteAttachConfirm String Comp.YesNoDimmer.Msg
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


type SaveNameState
    = Saving
    | SaveSuccess
    | SaveFailed
