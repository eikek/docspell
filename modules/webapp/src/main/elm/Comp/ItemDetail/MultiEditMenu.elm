module Comp.ItemDetail.MultiEditMenu exposing
    ( Model
    , Msg
    , SaveNameState(..)
    , defaultViewConfig
    , init
    , loadModel
    , update
    , view2
    )

import Api
import Api.Model.EquipmentList exposing (EquipmentList)
import Api.Model.FolderItem exposing (FolderItem)
import Api.Model.FolderList exposing (FolderList)
import Api.Model.IdName exposing (IdName)
import Api.Model.PersonList exposing (PersonList)
import Api.Model.ReferenceList exposing (ReferenceList)
import Api.Model.Tag exposing (Tag)
import Api.Model.TagList exposing (TagList)
import Comp.CustomFieldMultiInput
import Comp.DatePicker
import Comp.DetailEdit
import Comp.Dropdown exposing (isDropdownChangeMsg)
import Comp.ItemDetail.FieldTabState as FTabState
import Comp.ItemDetail.FormChange exposing (FormChange(..))
import Comp.Tabs as TB
import Data.CustomFieldChange exposing (CustomFieldChange(..))
import Data.Direction exposing (Direction)
import Data.DropdownStyle
import Data.Fields
import Data.Flags exposing (Flags)
import Data.Icons as Icons
import Data.PersonUse
import Data.UiSettings exposing (UiSettings)
import DatePicker exposing (DatePicker)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Markdown
import Page exposing (Page(..))
import Set exposing (Set)
import Styles as S
import Task
import Throttle exposing (Throttle)
import Time
import Util.Folder exposing (mkFolderOption)
import Util.List
import Util.Maybe
import Util.Tag



--- Model


type SaveNameState
    = Saving
    | SaveSuccess
    | SaveFailed


type TagEditMode
    = AddTags
    | RemoveTags
    | ReplaceTags


type alias Model =
    { tagModel : Comp.Dropdown.Model Tag
    , nameModel : String
    , nameSaveThrottle : Throttle Msg
    , folderModel : Comp.Dropdown.Model IdName
    , allFolders : List FolderItem
    , directionModel : Comp.Dropdown.Model Direction
    , itemDatePicker : DatePicker
    , itemDate : Maybe Int
    , dueDate : Maybe Int
    , dueDatePicker : DatePicker
    , corrOrgModel : Comp.Dropdown.Model IdName
    , corrPersonModel : Comp.Dropdown.Model IdName
    , concPersonModel : Comp.Dropdown.Model IdName
    , concEquipModel : Comp.Dropdown.Model IdName
    , modalEdit : Maybe Comp.DetailEdit.Model
    , tagEditMode : TagEditMode
    , customFieldModel : Comp.CustomFieldMultiInput.Model
    , openTabs : Set String
    }


type Msg
    = ItemDatePickerMsg Comp.DatePicker.Msg
    | DueDatePickerMsg Comp.DatePicker.Msg
    | SetName String
    | SaveName
    | UpdateThrottle
    | RemoveDueDate
    | RemoveDate
    | ConfirmMsg Bool
    | ToggleTagEditMode
    | FolderDropdownMsg (Comp.Dropdown.Msg IdName)
    | TagDropdownMsg (Comp.Dropdown.Msg Tag)
    | DirDropdownMsg (Comp.Dropdown.Msg Direction)
    | OrgDropdownMsg (Comp.Dropdown.Msg IdName)
    | CorrPersonMsg (Comp.Dropdown.Msg IdName)
    | ConcPersonMsg (Comp.Dropdown.Msg IdName)
    | ConcEquipMsg (Comp.Dropdown.Msg IdName)
    | GetTagsResp (Result Http.Error TagList)
    | GetOrgResp (Result Http.Error ReferenceList)
    | GetPersonResp (Result Http.Error PersonList)
    | GetEquipResp (Result Http.Error EquipmentList)
    | GetFolderResp (Result Http.Error FolderList)
    | CustomFieldMsg Comp.CustomFieldMultiInput.Msg
    | ToggleAkkordionTab String


init : Model
init =
    { tagModel =
        Util.Tag.makeDropdownModel2
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
    , nameSaveThrottle = Throttle.create 1
    , itemDatePicker = Comp.DatePicker.emptyModel
    , itemDate = Nothing
    , dueDate = Nothing
    , dueDatePicker = Comp.DatePicker.emptyModel
    , modalEdit = Nothing
    , tagEditMode = AddTags
    , customFieldModel = Comp.CustomFieldMultiInput.initWith []
    , openTabs = Set.empty
    }


loadModel : Flags -> Cmd Msg
loadModel flags =
    let
        ( _, dpc ) =
            Comp.DatePicker.init
    in
    Cmd.batch
        [ Api.getTags flags "" GetTagsResp
        , Api.getOrgLight flags GetOrgResp
        , Api.getPersons flags "" GetPersonResp
        , Api.getEquipments flags "" GetEquipResp
        , Api.getFolders flags "" False GetFolderResp
        , Cmd.map CustomFieldMsg (Comp.CustomFieldMultiInput.initCmd flags)
        , Cmd.map ItemDatePickerMsg dpc
        , Cmd.map DueDatePickerMsg dpc
        ]


isFolderMember : Model -> Bool
isFolderMember model =
    let
        selected =
            Comp.Dropdown.getSelected model.folderModel
                |> List.head
                |> Maybe.map .id
    in
    Util.Folder.isFolderMember model.allFolders selected



--- Update


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    , change : FormChange
    }


resultNoCmd : FormChange -> Model -> UpdateResult
resultNoCmd change model =
    UpdateResult model Cmd.none Sub.none change


resultNone : Model -> UpdateResult
resultNone model =
    resultNoCmd NoFormChange model


update : Flags -> Msg -> Model -> UpdateResult
update flags msg model =
    case msg of
        ConfirmMsg flag ->
            resultNoCmd (ConfirmChange flag) model

        TagDropdownMsg m ->
            let
                ( m2, _ ) =
                    Comp.Dropdown.update m model.tagModel

                newModel =
                    { model | tagModel = m2 }

                mkChange list =
                    case model.tagEditMode of
                        AddTags ->
                            AddTagChange list

                        RemoveTags ->
                            RemoveTagChange list

                        ReplaceTags ->
                            ReplaceTagChange list

                change =
                    if isDropdownChangeMsg m then
                        Comp.Dropdown.getSelected newModel.tagModel
                            |> Util.List.distinct
                            |> List.map (\t -> IdName t.id t.name)
                            |> ReferenceList
                            |> mkChange

                    else
                        NoFormChange
            in
            resultNoCmd change newModel

        ToggleTagEditMode ->
            let
                ( m2, _ ) =
                    Comp.Dropdown.update (Comp.Dropdown.SetSelection []) model.tagModel

                newModel =
                    { model | tagModel = m2 }
            in
            case model.tagEditMode of
                AddTags ->
                    resultNone { newModel | tagEditMode = RemoveTags }

                RemoveTags ->
                    resultNone { newModel | tagEditMode = ReplaceTags }

                ReplaceTags ->
                    resultNone { newModel | tagEditMode = AddTags }

        GetTagsResp (Ok tags) ->
            let
                tagList =
                    Comp.Dropdown.SetOptions tags.items
            in
            update flags (TagDropdownMsg tagList) model

        GetTagsResp (Err _) ->
            resultNone model

        FolderDropdownMsg m ->
            let
                ( m2, _ ) =
                    Comp.Dropdown.update m model.folderModel

                newModel =
                    { model | folderModel = m2 }

                idref =
                    Comp.Dropdown.getSelected m2 |> List.head

                change =
                    if isDropdownChangeMsg m then
                        FolderChange idref

                    else
                        NoFormChange
            in
            resultNoCmd change newModel

        GetFolderResp (Ok fs) ->
            let
                model_ =
                    { model
                        | allFolders = fs.items
                        , folderModel =
                            Comp.Dropdown.setMkOption
                                (mkFolderOption flags fs.items)
                                model.folderModel
                    }

                mkIdName fitem =
                    IdName fitem.id fitem.name

                opts =
                    fs.items
                        |> List.map mkIdName
                        |> Comp.Dropdown.SetOptions
            in
            update flags (FolderDropdownMsg opts) model_

        GetFolderResp (Err _) ->
            resultNone model

        DirDropdownMsg m ->
            let
                ( m2, _ ) =
                    Comp.Dropdown.update m model.directionModel

                newModel =
                    { model | directionModel = m2 }

                change =
                    if isDropdownChangeMsg m then
                        let
                            dir =
                                Comp.Dropdown.getSelected m2 |> List.head
                        in
                        case dir of
                            Just d ->
                                DirectionChange d

                            Nothing ->
                                NoFormChange

                    else
                        NoFormChange
            in
            resultNoCmd change newModel

        OrgDropdownMsg m ->
            let
                ( m2, _ ) =
                    Comp.Dropdown.update m model.corrOrgModel

                newModel =
                    { model | corrOrgModel = m2 }

                idref =
                    Comp.Dropdown.getSelected m2 |> List.head

                change =
                    if isDropdownChangeMsg m then
                        OrgChange idref

                    else
                        NoFormChange
            in
            resultNoCmd change newModel

        GetOrgResp (Ok orgs) ->
            let
                opts =
                    Comp.Dropdown.SetOptions orgs.items
            in
            update flags (OrgDropdownMsg opts) model

        GetOrgResp (Err _) ->
            resultNone model

        CorrPersonMsg m ->
            let
                ( m2, _ ) =
                    Comp.Dropdown.update m model.corrPersonModel

                newModel =
                    { model | corrPersonModel = m2 }

                idref =
                    Comp.Dropdown.getSelected m2 |> List.head

                change =
                    if isDropdownChangeMsg m then
                        CorrPersonChange idref

                    else
                        NoFormChange
            in
            resultNoCmd change newModel

        ConcPersonMsg m ->
            let
                ( m2, _ ) =
                    Comp.Dropdown.update m model.concPersonModel

                newModel =
                    { model | concPersonModel = m2 }

                idref =
                    Comp.Dropdown.getSelected m2 |> List.head

                change =
                    if isDropdownChangeMsg m then
                        ConcPersonChange idref

                    else
                        NoFormChange
            in
            resultNoCmd change newModel

        GetPersonResp (Ok ps) ->
            let
                { concerning, correspondent } =
                    Data.PersonUse.spanPersonList ps.items

                concRefs =
                    List.map (\e -> IdName e.id e.name) concerning

                corrRefs =
                    List.map (\e -> IdName e.id e.name) correspondent

                res1 =
                    update flags (CorrPersonMsg (Comp.Dropdown.SetOptions corrRefs)) model

                res2 =
                    update flags (ConcPersonMsg (Comp.Dropdown.SetOptions concRefs)) res1.model
            in
            res2

        GetPersonResp (Err _) ->
            resultNone model

        ConcEquipMsg m ->
            let
                ( m2, _ ) =
                    Comp.Dropdown.update m model.concEquipModel

                newModel =
                    { model | concEquipModel = m2 }

                idref =
                    Comp.Dropdown.getSelected m2 |> List.head

                change =
                    if isDropdownChangeMsg m then
                        EquipChange idref

                    else
                        NoFormChange
            in
            resultNoCmd change newModel

        GetEquipResp (Ok equips) ->
            let
                opts =
                    Comp.Dropdown.SetOptions
                        (List.map (\e -> IdName e.id e.name)
                            equips.items
                        )
            in
            update flags (ConcEquipMsg opts) model

        GetEquipResp (Err _) ->
            resultNone model

        ItemDatePickerMsg m ->
            let
                ( dp, event ) =
                    Comp.DatePicker.updateDefault m model.itemDatePicker
            in
            case event of
                DatePicker.Picked date ->
                    let
                        newModel =
                            { model | itemDatePicker = dp, itemDate = Just (Comp.DatePicker.midOfDay date) }
                    in
                    resultNoCmd (ItemDateChange newModel.itemDate) newModel

                _ ->
                    resultNone { model | itemDatePicker = dp }

        RemoveDate ->
            resultNoCmd (ItemDateChange Nothing) { model | itemDate = Nothing }

        DueDatePickerMsg m ->
            let
                ( dp, event ) =
                    Comp.DatePicker.updateDefault m model.dueDatePicker
            in
            case event of
                DatePicker.Picked date ->
                    let
                        newModel =
                            { model | dueDatePicker = dp, dueDate = Just (Comp.DatePicker.midOfDay date) }
                    in
                    resultNoCmd (DueDateChange newModel.dueDate) newModel

                _ ->
                    resultNone { model | dueDatePicker = dp }

        RemoveDueDate ->
            resultNoCmd (DueDateChange Nothing) { model | dueDate = Nothing }

        SetName str ->
            case Util.Maybe.fromString str of
                Just newName ->
                    let
                        cmd_ =
                            Task.succeed ()
                                |> Task.perform (\_ -> SaveName)

                        ( newThrottle, cmd ) =
                            Throttle.try cmd_ model.nameSaveThrottle

                        newModel =
                            { model
                                | nameSaveThrottle = newThrottle
                                , nameModel = newName
                            }

                        sub =
                            nameThrottleSub newModel
                    in
                    UpdateResult newModel cmd sub NoFormChange

                Nothing ->
                    resultNone { model | nameModel = str }

        SaveName ->
            case Util.Maybe.fromString model.nameModel of
                Just n ->
                    resultNoCmd (NameChange n) model

                Nothing ->
                    resultNone model

        UpdateThrottle ->
            let
                ( newThrottle, cmd ) =
                    Throttle.update model.nameSaveThrottle

                newModel =
                    { model | nameSaveThrottle = newThrottle }

                sub =
                    nameThrottleSub newModel
            in
            UpdateResult newModel cmd sub NoFormChange

        CustomFieldMsg lm ->
            let
                res =
                    Comp.CustomFieldMultiInput.update flags lm model.customFieldModel

                model_ =
                    { model | customFieldModel = res.model }

                cmd_ =
                    Cmd.map CustomFieldMsg res.cmd

                change =
                    case res.result of
                        NoFieldChange ->
                            NoFormChange

                        FieldValueRemove cf ->
                            RemoveCustomValue cf

                        FieldValueChange cf value ->
                            CustomValueChange cf value

                        FieldCreateNew ->
                            NoFormChange
            in
            UpdateResult model_ cmd_ Sub.none change

        ToggleAkkordionTab title ->
            let
                tabs =
                    if Set.member title model.openTabs then
                        Set.remove title model.openTabs

                    else
                        Set.insert title model.openTabs
            in
            UpdateResult { model | openTabs = tabs } Cmd.none Sub.none NoFormChange


nameThrottleSub : Model -> Sub Msg
nameThrottleSub model =
    Throttle.ifNeeded
        (Time.every 400 (\_ -> UpdateThrottle))
        model.nameSaveThrottle



--- View


type alias ViewConfig =
    { menuClass : String
    , nameState : SaveNameState
    , customFieldState : String -> SaveNameState
    }


defaultViewConfig : ViewConfig
defaultViewConfig =
    { menuClass = ""
    , nameState = SaveSuccess
    , customFieldState = \_ -> SaveSuccess
    }



--- View2


view2 : ViewConfig -> UiSettings -> Model -> Html Msg
view2 =
    renderEditForm2


renderEditForm2 : ViewConfig -> UiSettings -> Model -> Html Msg
renderEditForm2 cfg settings model =
    let
        fieldVisible field =
            Data.UiSettings.fieldVisible settings field

        optional fields html =
            if
                List.map fieldVisible fields
                    |> List.foldl (||) False
            then
                html

            else
                span [ class "hidden" ] []

        tagModeIcon =
            case model.tagEditMode of
                AddTags ->
                    i [ class "fa fa-plus" ] []

                RemoveTags ->
                    i [ class "fa fa-eraser" ] []

                ReplaceTags ->
                    i [ class "fa fa-redo-alt" ] []

        tagModeMsg =
            case model.tagEditMode of
                AddTags ->
                    "Tags chosen here are *added* to all selected items."

                RemoveTags ->
                    "Tags chosen here are *removed* from all selected items."

                ReplaceTags ->
                    "Tags chosen here *replace* those on selected items."

        customFieldIcon field =
            case cfg.customFieldState field.id of
                SaveSuccess ->
                    Nothing

                SaveFailed ->
                    Just "text-red-500 fa fa-exclamation-triangle"

                Saving ->
                    Just "fa fa-sync-alt animate-spin"

        customFieldSettings =
            Comp.CustomFieldMultiInput.ViewSettings
                False
                "mb-4"
                customFieldIcon

        dds =
            Data.DropdownStyle.sidebarStyle

        tabStyle =
            TB.searchMenuStyle
    in
    div [ class cfg.menuClass, class "mt-2" ]
        [ TB.akkordion
            tabStyle
            (tabState settings model)
            [ { title = "Confirm/Unconfirm item metadata"
              , titleRight = []
              , info = Nothing
              , body =
                    [ div
                        [ class "flex flex-row space-x-4"
                        ]
                        [ button
                            [ class S.primaryButton
                            , class "flex-grow"
                            , onClick (ConfirmMsg True)
                            ]
                            [ text "Confirm"
                            ]
                        , button
                            [ class S.secondaryButton
                            , class "flex-grow"
                            , onClick (ConfirmMsg False)
                            ]
                            [ text "Unconfirm"
                            ]
                        ]
                    ]
              }
            , { title = "Tags"
              , titleRight = []
              , info = Nothing
              , body =
                    [ div [ class "field" ]
                        [ label [ class S.inputLabel ]
                            [ Icons.tagsIcon2 ""
                            , text "Tags"
                            , a
                                [ class "float-right"
                                , class S.link
                                , href "#"
                                , title "Change tag edit mode"
                                , onClick ToggleTagEditMode
                                ]
                                [ tagModeIcon
                                ]
                            ]
                        , Html.map TagDropdownMsg (Comp.Dropdown.view2 dds settings model.tagModel)
                        , Markdown.toHtml [ class "opacity-50 text-sm" ] tagModeMsg
                        ]
                    ]
              }
            , { title = "Folder"
              , titleRight = []
              , info = Nothing
              , body =
                    [ Html.map FolderDropdownMsg (Comp.Dropdown.view2 dds settings model.folderModel)
                    , div
                        [ classList
                            [ ( S.message, True )
                            , ( "hidden", isFolderMember model )
                            ]
                        ]
                        [ Markdown.toHtml [] """
You are **not a member** of this folder. This item will be **hidden**
from any search now. Use a folder where you are a member of to make this
item visible. This message will disappear then.
                      """
                        ]
                    ]
              }
            , { title = "Custom Fields"
              , titleRight = []
              , info = Nothing
              , body =
                    [ Html.map CustomFieldMsg
                        (Comp.CustomFieldMultiInput.view2 dds customFieldSettings model.customFieldModel)
                    ]
              }
            , { title = "Date"
              , titleRight = []
              , info = Nothing
              , body =
                    [ div [ class "relative" ]
                        [ Html.map ItemDatePickerMsg
                            (Comp.DatePicker.viewTime
                                model.itemDate
                                actionInputDatePicker2
                                model.itemDatePicker
                            )
                        , a
                            [ class S.inputLeftIconLinkSidebar
                            , href "#"
                            , onClick RemoveDate
                            ]
                            [ i [ class "fa fa-trash-alt font-thin" ] []
                            ]
                        , Icons.dateIcon2 S.dateInputIcon
                        ]
                    ]
              }
            , { title = "Due Date"
              , titleRight = []
              , info = Nothing
              , body =
                    [ div [ class "relative" ]
                        [ Html.map DueDatePickerMsg
                            (Comp.DatePicker.viewTime
                                model.dueDate
                                actionInputDatePicker2
                                model.dueDatePicker
                            )
                        , a
                            [ class S.inputLeftIconLinkSidebar
                            , href "#"
                            , onClick RemoveDueDate
                            ]
                            [ i [ class "fa fa-trash-alt font-thin" ] []
                            ]
                        , Icons.dueDateIcon2 S.dateInputIcon
                        ]
                    ]
              }
            , { title = "Correspondent"
              , titleRight = []
              , info = Nothing
              , body =
                    [ optional [ Data.Fields.CorrOrg ] <|
                        div [ class "mb-4" ]
                            [ label [ class S.inputLabel ]
                                [ Icons.organizationIcon2 ""
                                , span [ class "ml-2" ]
                                    [ text "Organization"
                                    ]
                                ]
                            , Html.map OrgDropdownMsg (Comp.Dropdown.view2 dds settings model.corrOrgModel)
                            ]
                    , optional [ Data.Fields.CorrPerson ] <|
                        div [ class "mb-4" ]
                            [ label [ class S.inputLabel ]
                                [ Icons.personIcon2 ""
                                , span [ class "ml-2" ]
                                    [ text "Person"
                                    ]
                                ]
                            , Html.map CorrPersonMsg (Comp.Dropdown.view2 dds settings model.corrPersonModel)
                            ]
                    ]
              }
            , { title = "Concerning"
              , titleRight = []
              , info = Nothing
              , body =
                    [ optional [ Data.Fields.ConcPerson ] <|
                        div [ class "mb-4" ]
                            [ label [ class S.inputLabel ]
                                [ Icons.personIcon2 ""
                                , span [ class "ml-2" ]
                                    [ text "Person" ]
                                ]
                            , Html.map ConcPersonMsg (Comp.Dropdown.view2 dds settings model.concPersonModel)
                            ]
                    , optional [ Data.Fields.ConcEquip ] <|
                        div [ class "mb-4" ]
                            [ label [ class S.inputLabel ]
                                [ Icons.equipmentIcon2 ""
                                , span [ class "ml-2" ]
                                    [ text "Equipment" ]
                                ]
                            , Html.map ConcEquipMsg (Comp.Dropdown.view2 dds settings model.concEquipModel)
                            ]
                    ]
              }
            , { title = "Direction"
              , titleRight = []
              , info = Nothing
              , body =
                    [ Html.map DirDropdownMsg (Comp.Dropdown.view2 dds settings model.directionModel)
                    ]
              }
            , { title = "Name"
              , titleRight = []
              , info = Nothing
              , body =
                    [ div [ class "relative" ]
                        [ input
                            [ type_ "text"
                            , value model.nameModel
                            , onInput SetName
                            , class S.textInputSidebar
                            ]
                            []
                        , span [ class S.inputLeftIconOnly ]
                            [ i
                                [ classList
                                    [ ( "text-green-500 fa fa-check", cfg.nameState == SaveSuccess )
                                    , ( "text-red-500 fa fa-exclamation-triangle", cfg.nameState == SaveFailed )
                                    , ( "sync fa fa-circle-notch animate-spin", cfg.nameState == Saving )
                                    ]
                                ]
                                []
                            ]
                        ]
                    ]
              }
            ]
        ]


tabState : UiSettings -> Model -> TB.Tab Msg -> ( TB.State, Msg )
tabState settings model tab =
    FTabState.tabState settings
        model.openTabs
        (Just model.customFieldModel)
        (.title >> ToggleAkkordionTab)
        tab


actionInputDatePicker2 : DatePicker.Settings
actionInputDatePicker2 =
    Comp.DatePicker.defaultSettings
