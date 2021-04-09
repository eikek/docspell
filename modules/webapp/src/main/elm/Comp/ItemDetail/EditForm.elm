module Comp.ItemDetail.EditForm exposing (formTabs, view2)

import Comp.CustomFieldMultiInput
import Comp.DatePicker
import Comp.Dropdown
import Comp.ItemDetail.FieldTabState as FTabState exposing (EditTab(..))
import Comp.ItemDetail.Model
    exposing
        ( Model
        , Msg(..)
        , NotesField(..)
        , SaveNameState(..)
        , personMatchesOrg
        )
import Comp.KeyInput
import Comp.Tabs as TB
import Data.Direction
import Data.DropdownStyle
import Data.Fields
import Data.Flags exposing (Flags)
import Data.Icons as Icons
import Data.UiSettings exposing (UiSettings)
import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Markdown
import Messages.Comp.ItemDetail.EditForm exposing (Texts)
import Page exposing (Page(..))
import Set exposing (Set)
import Styles as S
import Util.Folder
import Util.Person
import Util.Tag
import Util.Time


view2 : Texts -> Flags -> UiSettings -> Model -> Html Msg
view2 texts flags settings model =
    let
        keyAttr =
            if settings.itemDetailShortcuts then
                Comp.KeyInput.eventsM KeyInputMsg

            else
                []

        tabStyle =
            TB.searchMenuStyle

        tabs =
            formTabs texts flags settings model

        allTabNames =
            List.map .name tabs
                |> Set.fromList
    in
    div (class "flex flex-col relative" :: keyAttr)
        [ TB.akkordion tabStyle
            (tabState settings allTabNames model)
            tabs
        ]


formTabs : Texts -> Flags -> UiSettings -> Model -> List (TB.Tab Msg)
formTabs texts flags settings model =
    let
        dds =
            Data.DropdownStyle.sidebarStyle

        addIconLink tip m =
            a
                [ class "float-right"
                , href "#"
                , title tip
                , onClick m
                , class S.link
                ]
                [ i [ class "fa fa-plus" ] []
                ]

        editIconLink tip dm m =
            a
                [ classList
                    [ ( "hidden", Comp.Dropdown.notSelected dm )
                    ]
                , href "#"
                , class "float-right mr-2"
                , class S.link
                , title tip
                , onClick m
                ]
                [ i [ class "fa fa-pencil-alt" ] []
                ]

        fieldVisible field =
            Data.UiSettings.fieldVisible settings field

        customFieldSettings =
            { showAddButton = True
            , classes = ""
            , fieldIcon = \f -> Dict.get f.id model.customFieldSavingIcon
            , style = dds
            , createCustomFieldTitle = texts.createNewCustomField
            }

        optional fields html =
            if
                List.map fieldVisible fields
                    |> List.foldl (||) False
            then
                html

            else
                span [ class "invisible hidden" ] []

        directionCfg =
            { makeOption =
                \entry ->
                    { text = Data.Direction.toString entry
                    , additional = ""
                    }
            , placeholder = texts.chooseDirection
            , labelColor = \_ -> \_ -> ""
            , style = dds
            }

        folderCfg =
            { makeOption = Util.Folder.mkFolderOption flags model.allFolders
            , placeholder = texts.selectPlaceholder
            , labelColor = \_ -> \_ -> ""
            , style = dds
            }

        idNameCfg =
            { makeOption = \e -> { text = e.name, additional = "" }
            , labelColor = \_ -> \_ -> ""
            , placeholder = texts.selectPlaceholder
            , style = dds
            }

        personCfg =
            { makeOption = \p -> Util.Person.mkPersonOption p model.allPersons
            , labelColor = \_ -> \_ -> ""
            , placeholder = texts.selectPlaceholder
            , style = dds
            }
    in
    [ { name = FTabState.tabName TabName
      , title = texts.nameTab
      , titleRight = []
      , info = Nothing
      , body =
            [ div [ class "relative mb-4" ]
                [ input
                    [ type_ "text"
                    , value model.nameModel
                    , onInput SetName
                    , class S.textInputSidebar
                    , class "pr-10"
                    ]
                    []
                , span [ class S.inputLeftIconOnly ]
                    [ i
                        [ classList
                            [ ( "text-green-500 fa fa-check", model.nameState == SaveSuccess )
                            , ( "text-red-500 fa fa-exclamation-triangle", model.nameState == SaveFailed )
                            , ( "sync fa fa-circle-notch animate-spin", model.nameState == Saving )
                            ]
                        ]
                        []
                    ]
                ]
            ]
      }
    , { name = FTabState.tabName TabDate
      , title = texts.dateTab
      , titleRight = []
      , info = Nothing
      , body =
            [ div [ class "mb-4" ]
                [ div [ class "relative" ]
                    [ Html.map ItemDatePickerMsg
                        (Comp.DatePicker.viewTimeDefault
                            model.itemDate
                            model.itemDatePicker
                        )
                    , a
                        [ class "ui icon button"
                        , href "#"
                        , class S.inputLeftIconLinkSidebar
                        , onClick RemoveDate
                        ]
                        [ i [ class "fa fa-trash-alt font-thin" ] []
                        ]
                    , Icons.dateIcon2 S.dateInputIcon
                    ]
                , renderItemDateSuggestions texts model
                ]
            ]
      }
    , { name = FTabState.tabName TabTags
      , title = texts.basics.tags
      , titleRight = []
      , info = Nothing
      , body =
            [ div [ class "mb-4 flex flex-col" ]
                [ Html.map TagDropdownMsg
                    (Comp.Dropdown.view2 (Util.Tag.tagSettings texts.basics.chooseTag dds)
                        settings
                        model.tagModel
                    )
                , div [ class "flex flex-row items-center justify-end" ]
                    [ a
                        [ class S.secondaryButton
                        , class "text-xs mt-2"
                        , href "#"
                        , onClick StartTagModal
                        ]
                        [ i [ class "fa fa-plus" ] []
                        ]
                    ]
                ]
            ]
      }
    , { name = FTabState.tabName TabFolder
      , title = texts.folderTab
      , titleRight = []
      , info = Nothing
      , body =
            [ div [ class "mb-4" ]
                [ Html.map FolderDropdownMsg
                    (Comp.Dropdown.view2
                        folderCfg
                        settings
                        model.folderModel
                    )
                , div
                    [ classList
                        [ ( S.message, True )
                        , ( "hidden", isFolderMember model )
                        ]
                    ]
                    [ Markdown.toHtml [] texts.folderNotOwnerWarning
                    ]
                ]
            ]
      }
    , { name = FTabState.tabName TabCustomFields
      , title = texts.customFieldsTab
      , titleRight = []
      , info = Nothing
      , body =
            [ div [ class "mb-4" ]
                [ Html.map CustomFieldMsg
                    (Comp.CustomFieldMultiInput.view2
                        texts.customFieldInput
                        customFieldSettings
                        model.customFieldsModel
                    )
                ]
            ]
      }
    , { name = FTabState.tabName TabDueDate
      , title = texts.dueDateTab
      , titleRight = []
      , info = Nothing
      , body =
            [ div [ class "mb-4" ]
                [ div [ class "relative" ]
                    [ Html.map DueDatePickerMsg
                        (Comp.DatePicker.viewTimeDefault
                            model.dueDate
                            model.dueDatePicker
                        )
                    , a
                        [ class "ui icon button"
                        , href "#"
                        , class S.inputLeftIconLinkSidebar
                        , onClick RemoveDueDate
                        ]
                        [ i [ class "fa fa-trash-alt font-thin" ] []
                        ]
                    , Icons.dueDateIcon2 S.dateInputIcon
                    ]
                , renderDueDateSuggestions texts model
                ]
            ]
      }
    , { name = FTabState.tabName TabCorrespondent
      , title = texts.correspondentTab
      , titleRight = []
      , info = Nothing
      , body =
            [ optional [ Data.Fields.CorrOrg ] <|
                div [ class "mb-4" ]
                    [ label [ class S.inputLabel ]
                        [ Icons.organizationIcon2 "mr-2"
                        , text texts.organization
                        , addIconLink texts.addNewOrg StartCorrOrgModal
                        , editIconLink texts.editOrg model.corrOrgModel StartEditCorrOrgModal
                        ]
                    , Html.map OrgDropdownMsg
                        (Comp.Dropdown.view2
                            (Comp.Dropdown.orgFormViewSettings texts.chooseOrg dds)
                            settings
                            model.corrOrgModel
                        )
                    , renderOrgSuggestions texts model
                    ]
            , optional [ Data.Fields.CorrPerson ] <|
                div [ class "mb-4" ]
                    [ label [ class S.inputLabel ]
                        [ Icons.personIcon2 "mr-2"
                        , text "Person"
                        , addIconLink texts.addNewCorrespondentPerson StartCorrPersonModal
                        , editIconLink texts.editPerson
                            model.corrPersonModel
                            (StartEditPersonModal model.corrPersonModel)
                        ]
                    , Html.map CorrPersonMsg
                        (Comp.Dropdown.view2 personCfg
                            settings
                            model.corrPersonModel
                        )
                    , renderCorrPersonSuggestions texts model
                    , div
                        [ classList
                            [ ( "hidden", personMatchesOrg model )
                            ]
                        , class S.message
                        , class "my-2"
                        ]
                        [ i [ class "fa fa-info mr-2 " ] []
                        , text texts.personOrgInfo
                        ]
                    ]
            ]
      }
    , { name = FTabState.tabName TabConcerning
      , title = texts.concerningTab
      , titleRight = []
      , info = Nothing
      , body =
            [ optional [ Data.Fields.ConcPerson ] <|
                div [ class "mb-4" ]
                    [ label [ class S.inputLabel ]
                        [ Icons.personIcon2 "mr-2"
                        , text "Person"
                        , addIconLink texts.addNewConcerningPerson StartConcPersonModal
                        , editIconLink texts.editPerson
                            model.concPersonModel
                            (StartEditPersonModal model.concPersonModel)
                        ]
                    , Html.map ConcPersonMsg
                        (Comp.Dropdown.view2
                            personCfg
                            settings
                            model.concPersonModel
                        )
                    , renderConcPersonSuggestions texts model
                    ]
            , optional [ Data.Fields.ConcEquip ] <|
                div [ class "mb-4" ]
                    [ label [ class S.inputLabel ]
                        [ Icons.equipmentIcon2 "mr-2"
                        , text "Equipment"
                        , addIconLink texts.addNewEquipment StartEquipModal
                        , editIconLink texts.editEquipment
                            model.concEquipModel
                            StartEditEquipModal
                        ]
                    , Html.map ConcEquipMsg
                        (Comp.Dropdown.view2
                            idNameCfg
                            settings
                            model.concEquipModel
                        )
                    , renderConcEquipSuggestions texts model
                    ]
            ]
      }
    , { name = FTabState.tabName TabDirection
      , title = texts.directionTab
      , titleRight = []
      , info = Nothing
      , body =
            [ div [ class "mb-4" ]
                [ Html.map DirDropdownMsg
                    (Comp.Dropdown.view2
                        directionCfg
                        settings
                        model.directionModel
                    )
                ]
            ]
      }
    ]


renderSuggestions : Texts -> Model -> (a -> String) -> List a -> (a -> Msg) -> Html Msg
renderSuggestions texts model mkName idnames tagger =
    div
        [ classList
            [ ( "hidden", model.item.state /= "created" )
            ]
        , class "flex flex-col text-sm"
        ]
        [ div [ class "font-bold my-1" ]
            [ text texts.suggestions
            ]
        , ul [ class "list-disc ml-6" ] <|
            (idnames
                |> List.map
                    (\p ->
                        li []
                            [ a
                                [ class S.link
                                , href "#"
                                , onClick (tagger p)
                                ]
                                [ text (mkName p) ]
                            ]
                    )
            )
        ]


renderOrgSuggestions : Texts -> Model -> Html Msg
renderOrgSuggestions texts model =
    renderSuggestions texts
        model
        .name
        (List.take 6 model.itemProposals.corrOrg)
        SetCorrOrgSuggestion


renderCorrPersonSuggestions : Texts -> Model -> Html Msg
renderCorrPersonSuggestions texts model =
    renderSuggestions texts
        model
        .name
        (List.take 6 model.itemProposals.corrPerson)
        SetCorrPersonSuggestion


renderConcPersonSuggestions : Texts -> Model -> Html Msg
renderConcPersonSuggestions texts model =
    renderSuggestions texts
        model
        .name
        (List.take 6 model.itemProposals.concPerson)
        SetConcPersonSuggestion


renderConcEquipSuggestions : Texts -> Model -> Html Msg
renderConcEquipSuggestions texts model =
    renderSuggestions texts
        model
        .name
        (List.take 6 model.itemProposals.concEquipment)
        SetConcEquipSuggestion


renderItemDateSuggestions : Texts -> Model -> Html Msg
renderItemDateSuggestions texts model =
    renderSuggestions texts
        model
        Util.Time.formatDate
        (List.take 6 model.itemProposals.itemDate)
        SetItemDateSuggestion


renderDueDateSuggestions : Texts -> Model -> Html Msg
renderDueDateSuggestions texts model =
    renderSuggestions texts
        model
        Util.Time.formatDate
        (List.take 6 model.itemProposals.dueDate)
        SetDueDateSuggestion



--- Helpers


isFolderMember : Model -> Bool
isFolderMember model =
    let
        selected =
            Comp.Dropdown.getSelected model.folderModel
                |> List.head
                |> Maybe.map .id
    in
    Util.Folder.isFolderMember model.allFolders selected


tabState : UiSettings -> Set String -> Model -> TB.Tab Msg -> ( TB.State, Msg )
tabState settings allNames model =
    let
        openTabs =
            if model.item.state == "created" then
                allNames

            else
                model.editMenuTabsOpen
    in
    FTabState.tabState settings
        openTabs
        Nothing
        (.name >> ToggleAkkordionTab)
