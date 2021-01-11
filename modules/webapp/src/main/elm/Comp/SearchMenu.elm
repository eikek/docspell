module Comp.SearchMenu exposing
    ( Model
    , Msg(..)
    , NextState
    , TextSearchModel
    , getItemSearch
    , init
    , isFulltextSearch
    , isNamesSearch
    , textSearchString
    , update
    , updateDrop
    , view
    , viewDrop
    )

import Api
import Api.Model.Equipment exposing (Equipment)
import Api.Model.EquipmentList exposing (EquipmentList)
import Api.Model.FolderStats exposing (FolderStats)
import Api.Model.IdName exposing (IdName)
import Api.Model.ItemFieldValue exposing (ItemFieldValue)
import Api.Model.ItemSearch exposing (ItemSearch)
import Api.Model.PersonList exposing (PersonList)
import Api.Model.ReferenceList exposing (ReferenceList)
import Api.Model.SearchStats exposing (SearchStats)
import Api.Model.TagList exposing (TagList)
import Comp.CustomFieldMultiInput
import Comp.DatePicker
import Comp.Dropdown exposing (isDropdownChangeMsg)
import Comp.FolderSelect
import Comp.TagSelect
import Data.CustomFieldChange exposing (CustomFieldValueCollect)
import Data.Direction exposing (Direction)
import Data.Fields
import Data.Flags exposing (Flags)
import Data.Icons as Icons
import Data.UiSettings exposing (UiSettings)
import DatePicker exposing (DatePicker)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
import Http
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
    }


type TextSearchModel
    = Fulltext (Maybe String)
    | Names (Maybe String)


init : Flags -> Model
init flags =
    { tagSelectModel = Comp.TagSelect.init [] []
    , tagSelection = Comp.TagSelect.emptySelection
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
    , orgModel =
        Comp.Dropdown.orgDropdown
    , corrPersonModel =
        Comp.Dropdown.makeSingle
            { makeOption = \e -> { value = e.id, text = e.name, additional = "" }
            , placeholder = "Choose a person"
            }
    , concPersonModel =
        Comp.Dropdown.makeSingle
            { makeOption = \e -> { value = e.id, text = e.name, additional = "" }
            , placeholder = "Choose a person"
            }
    , concEquipmentModel =
        Comp.Dropdown.makeModel
            { multiple = False
            , searchable = \n -> n > 0
            , makeOption = \e -> { value = e.id, text = e.name, additional = "" }
            , labelColor = \_ -> \_ -> ""
            , placeholder = "Choose an equipment"
            }
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


getDirection : Model -> Maybe Direction
getDirection model =
    let
        selection =
            Comp.Dropdown.getSelected model.directionModel
    in
    case selection of
        [ d ] ->
            Just d

        _ ->
            Nothing


getItemSearch : Model -> ItemSearch
getItemSearch model =
    let
        e =
            Api.Model.ItemSearch.empty

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
    in
    { e
        | tagsInclude = model.tagSelection.includeTags |> List.map .tag |> List.map .id
        , tagsExclude = model.tagSelection.excludeTags |> List.map .tag |> List.map .id
        , corrPerson = Comp.Dropdown.getSelected model.corrPersonModel |> List.map .id |> List.head
        , corrOrg = Comp.Dropdown.getSelected model.orgModel |> List.map .id |> List.head
        , concPerson = Comp.Dropdown.getSelected model.concPersonModel |> List.map .id |> List.head
        , concEquip = Comp.Dropdown.getSelected model.concEquipmentModel |> List.map .id |> List.head
        , folder = model.selectedFolder |> Maybe.map .id
        , direction =
            Comp.Dropdown.getSelected model.directionModel
                |> List.head
                |> Maybe.map Data.Direction.toString
        , inbox = model.inboxCheckbox
        , dateFrom = model.fromDate
        , dateUntil = model.untilDate
        , dueDateFrom = model.fromDueDate
        , dueDateUntil = model.untilDueDate
        , name =
            model.nameModel
                |> Maybe.map amendWildcards
        , allNames =
            textSearch.nameSearch
                |> Maybe.map amendWildcards
        , fullText = textSearch.fullText
        , tagCategoriesInclude = model.tagSelection.includeCats |> List.map .name
        , tagCategoriesExclude = model.tagSelection.excludeCats |> List.map .name
        , customValues = Data.CustomFieldChange.toFieldValues model.customValues
        , source = model.sourceModel
    }


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


type alias NextState =
    { model : Model
    , cmd : Cmd Msg
    , stateChange : Bool
    , dragDrop : DD.DragDropData
    }


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
                    [ Api.itemSearchStats flags Api.Model.ItemSearch.empty GetAllTagsResp
                    , Api.getOrgLight flags GetOrgResp
                    , Api.getEquipments flags "" GetEquipResp
                    , Api.getPersons flags "" GetPersonResp
                    , Cmd.map CustomFieldMsg (Comp.CustomFieldMultiInput.initCmd flags)
                    , cdp
                    ]
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        ResetForm ->
            { model = resetModel model
            , cmd = Api.itemSearchStats flags Api.Model.ItemSearch.empty GetAllTagsResp
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
                    Equipment id.id id.name 0
            in
            resetAndSet (ConcEquipmentMsg (Comp.Dropdown.SetSelection [ equip ]))

        SetTag id ->
            resetAndSet (TagSelectMsg (Comp.TagSelect.toggleTag id))

        GetAllTagsResp (Ok stats) ->
            let
                tagSel =
                    Comp.TagSelect.modifyAll stats.tagCloud.items model.tagSelectModel
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
                selectModel =
                    List.sortBy .count stats.tagCloud.items
                        |> Comp.TagSelect.modifyCount model.tagSelectModel

                model_ =
                    { model
                        | tagSelectModel = selectModel
                        , folderList =
                            Comp.FolderSelect.modify model.selectedFolder
                                model.folderList
                                stats.folderStats
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
                ( conc, corr ) =
                    List.partition .concerning ps.items

                concRefs =
                    List.map (\e -> IdName e.id e.name) conc

                corrRefs =
                    List.map (\e -> IdName e.id e.name) corr

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
                    Comp.CustomFieldMultiInput.updateSearch lm model.customFieldModel
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



-- View


view : Flags -> UiSettings -> Model -> Html Msg
view =
    viewDrop (DD.DragDropData DD.init Nothing)


viewDrop : DD.DragDropData -> Flags -> UiSettings -> Model -> Html Msg
viewDrop ddd flags settings model =
    let
        formHeader icon headline =
            div [ class "ui tiny header" ]
                [ icon
                , div [ class "content" ]
                    [ text headline
                    ]
                ]

        segmentClass =
            "ui vertical segment"

        fieldVisible field =
            Data.UiSettings.fieldVisible settings field

        fieldHidden field =
            Data.UiSettings.fieldHidden settings field

        optional fields html =
            if
                List.map fieldVisible fields
                    |> List.foldl (||) False
            then
                html

            else
                span [ class "invisible hidden" ] []
    in
    div [ class "ui form" ]
        [ div [ class segmentClass ]
            [ div [ class "inline field" ]
                [ div [ class "ui checkbox" ]
                    [ input
                        [ type_ "checkbox"
                        , onCheck (\_ -> ToggleInbox)
                        , checked model.inboxCheckbox
                        ]
                        []
                    , label []
                        [ text "Only New"
                        ]
                    ]
                ]
            ]
        , div [ class segmentClass ]
            [ div
                [ class "field"
                ]
                [ label []
                    [ text
                        (case model.textSearchModel of
                            Fulltext _ ->
                                "Fulltext Search"

                            Names _ ->
                                "Search in names"
                        )
                    , a
                        [ classList
                            [ ( "right-float", True )
                            , ( "invisible hidden", not flags.config.fullTextSearchEnabled )
                            ]
                        , href "#"
                        , onClick SwapTextSearch
                        , title "Switch between text search modes"
                        ]
                        [ i [ class "small grey exchange alternate icon" ] []
                        ]
                    ]
                , input
                    [ type_ "text"
                    , onInput SetTextSearch
                    , Util.Html.onKeyUpCode KeyUpMsg
                    , textSearchString model.textSearchModel |> Maybe.withDefault "" |> value
                    , case model.textSearchModel of
                        Fulltext _ ->
                            placeholder "Content search…"

                        Names _ ->
                            placeholder "Search in various names…"
                    ]
                    []
                , span [ class "small-info" ]
                    [ case model.textSearchModel of
                        Fulltext _ ->
                            text "Fulltext search in document contents and notes."

                        Names _ ->
                            text "Looks in correspondents, concerned entities, item name and notes."
                    ]
                ]
            ]
        , div
            [ classList
                [ ( segmentClass, True )
                , ( "invisible hidden", fieldHidden Data.Fields.Tag && fieldHidden Data.Fields.Folder )
                ]
            ]
            ((if fieldVisible Data.Fields.Tag then
                List.map (Html.map TagSelectMsg)
                    (Comp.TagSelect.viewAll
                        ddd.model
                        settings
                        model.tagSelection
                        model.tagSelectModel
                    )

              else
                []
             )
                ++ [ optional [ Data.Fields.Folder ] <|
                        Html.map FolderSelectMsg
                            (Comp.FolderSelect.viewDrop ddd.model
                                settings.searchMenuFolderCount
                                model.folderList
                            )
                   ]
            )
        , div
            [ classList
                [ ( segmentClass, True )
                , ( "hidden invisible", fieldHidden Data.Fields.CorrOrg && fieldHidden Data.Fields.CorrPerson )
                ]
            ]
            [ optional
                [ Data.Fields.CorrOrg
                , Data.Fields.CorrPerson
                ]
              <|
                formHeader (Icons.correspondentIcon "")
                    (case getDirection model of
                        Just Data.Direction.Incoming ->
                            "Sender"

                        Just Data.Direction.Outgoing ->
                            "Recipient"

                        Nothing ->
                            "Correspondent"
                    )
            , optional [ Data.Fields.CorrOrg ] <|
                div [ class "field" ]
                    [ label [] [ text "Organization" ]
                    , Html.map OrgMsg (Comp.Dropdown.view settings model.orgModel)
                    ]
            , optional [ Data.Fields.CorrPerson ] <|
                div [ class "field" ]
                    [ label [] [ text "Person" ]
                    , Html.map CorrPersonMsg (Comp.Dropdown.view settings model.corrPersonModel)
                    ]
            , optional
                [ Data.Fields.ConcPerson
                , Data.Fields.ConcEquip
                ]
              <|
                formHeader Icons.concernedIcon "Concerned"
            , optional [ Data.Fields.ConcPerson ] <|
                div [ class "field" ]
                    [ label [] [ text "Person" ]
                    , Html.map ConcPersonMsg (Comp.Dropdown.view settings model.concPersonModel)
                    ]
            , optional [ Data.Fields.ConcEquip ] <|
                div [ class "field" ]
                    [ label [] [ text "Equipment" ]
                    , Html.map ConcEquipmentMsg (Comp.Dropdown.view settings model.concEquipmentModel)
                    ]
            ]
        , div
            [ classList
                [ ( segmentClass, True )
                , ( "hidden invisible"
                  , fieldHidden Data.Fields.CustomFields
                        || Comp.CustomFieldMultiInput.isEmpty model.customFieldModel
                  )
                ]
            ]
            [ formHeader (Icons.customFieldIcon "") "Custom Fields"
            , Html.map CustomFieldMsg
                (Comp.CustomFieldMultiInput.view
                    (Comp.CustomFieldMultiInput.ViewSettings False "field" (\_ -> Nothing))
                    model.customFieldModel
                )
            ]
        , div
            [ classList
                [ ( segmentClass, True )
                , ( "invisible hidden", fieldHidden Data.Fields.Date && fieldHidden Data.Fields.DueDate )
                ]
            ]
            [ optional [ Data.Fields.Date ] <|
                formHeader (Icons.dateIcon "") "Date"
            , optional [ Data.Fields.Date ] <|
                div [ class "fields" ]
                    [ div [ class "field" ]
                        [ label []
                            [ text "From"
                            ]
                        , Html.map FromDateMsg
                            (Comp.DatePicker.viewTimeDefault
                                model.fromDate
                                model.fromDateModel
                            )
                        ]
                    , div [ class "field" ]
                        [ label []
                            [ text "To"
                            ]
                        , Html.map UntilDateMsg
                            (Comp.DatePicker.viewTimeDefault
                                model.untilDate
                                model.untilDateModel
                            )
                        ]
                    ]
            , optional [ Data.Fields.DueDate ] <|
                formHeader (Icons.dueDateIcon "") "Due Date"
            , optional [ Data.Fields.DueDate ] <|
                div [ class "fields" ]
                    [ div [ class "field" ]
                        [ label []
                            [ text "Due From"
                            ]
                        , Html.map FromDueDateMsg
                            (Comp.DatePicker.viewTimeDefault
                                model.fromDueDate
                                model.fromDueDateModel
                            )
                        ]
                    , div [ class "field" ]
                        [ label []
                            [ text "Due To"
                            ]
                        , Html.map UntilDueDateMsg
                            (Comp.DatePicker.viewTimeDefault
                                model.untilDueDate
                                model.untilDueDateModel
                            )
                        ]
                    ]
            ]
        , div
            [ classList
                [ ( segmentClass, not (fieldHidden Data.Fields.SourceName) )
                , ( "invisible hidden", fieldHidden Data.Fields.SourceName )
                ]
            ]
            [ formHeader (Icons.sourceIcon "") "Source"
            , div [ class "field" ]
                [ input
                    [ type_ "text"
                    , onInput SetSource
                    , Util.Html.onKeyUpCode KeyUpMsg
                    , model.sourceModel |> Maybe.withDefault "" |> value
                    , placeholder "Search in item source…"
                    ]
                    []
                ]
            ]
        , div
            [ classList
                [ ( segmentClass, True )
                , ( "invisible hidden", fieldHidden Data.Fields.Direction )
                ]
            ]
            [ formHeader (Icons.directionIcon "") "Direction"
            , div [ class "field" ]
                [ Html.map DirectionMsg (Comp.Dropdown.view settings model.directionModel)
                ]
            ]
        ]
