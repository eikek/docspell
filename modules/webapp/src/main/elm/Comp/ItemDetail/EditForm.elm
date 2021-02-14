module Comp.ItemDetail.EditForm exposing (formTabs, view2)

import Comp.CustomFieldMultiInput
import Comp.DatePicker
import Comp.Dropdown
import Comp.ItemDetail.FieldTabState as FTabState
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
import Data.DropdownStyle
import Data.Fields
import Data.Icons as Icons
import Data.UiSettings exposing (UiSettings)
import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Markdown
import Page exposing (Page(..))
import Set exposing (Set)
import Styles as S
import Util.Folder
import Util.Time


view2 : UiSettings -> Model -> Html Msg
view2 settings model =
    let
        keyAttr =
            if settings.itemDetailShortcuts then
                Comp.KeyInput.eventsM KeyInputMsg

            else
                []

        tabStyle =
            TB.searchMenuStyle

        tabs =
            formTabs settings model

        allTabNames =
            List.map .title tabs
                |> Set.fromList
    in
    div (class "flex flex-col relative" :: keyAttr)
        [ TB.akkordion tabStyle
            (tabState settings allTabNames model)
            tabs
        ]


formTabs : UiSettings -> Model -> List (TB.Tab Msg)
formTabs settings model =
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
            Comp.CustomFieldMultiInput.ViewSettings
                True
                "field"
                (\f -> Dict.get f.id model.customFieldSavingIcon)

        optional fields html =
            if
                List.map fieldVisible fields
                    |> List.foldl (||) False
            then
                html

            else
                span [ class "invisible hidden" ] []
    in
    [ { title = "Name"
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
    , { title = "Date"
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
                , renderItemDateSuggestions model
                ]
            ]
      }
    , { title = "Tags"
      , info = Nothing
      , body =
            [ div [ class "mb-4" ]
                [ Html.map TagDropdownMsg (Comp.Dropdown.view2 dds settings model.tagModel)
                ]
            ]
      }
    , { title = "Folder"
      , info = Nothing
      , body =
            [ div [ class "mb-4" ]
                [ Html.map FolderDropdownMsg
                    (Comp.Dropdown.view2
                        dds
                        settings
                        model.folderModel
                    )
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
            ]
      }
    , { title = "Custom Fields"
      , info = Nothing
      , body =
            [ div [ class "mb-4" ]
                [ Html.map CustomFieldMsg
                    (Comp.CustomFieldMultiInput.view2
                        dds
                        customFieldSettings
                        model.customFieldsModel
                    )
                ]
            ]
      }
    , { title = "Due Date"
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
                , renderDueDateSuggestions model
                ]
            ]
      }
    , { title = "Correspondent"
      , info = Nothing
      , body =
            [ optional [ Data.Fields.CorrOrg ] <|
                div [ class "mb-4" ]
                    [ label [ class S.inputLabel ]
                        [ Icons.organizationIcon2 "mr-2"
                        , text "Organization"
                        , addIconLink "Add new organization" StartCorrOrgModal
                        , editIconLink "Edit organization" model.corrOrgModel StartEditCorrOrgModal
                        ]
                    , Html.map OrgDropdownMsg (Comp.Dropdown.view2 dds settings model.corrOrgModel)
                    , renderOrgSuggestions model
                    ]
            , optional [ Data.Fields.CorrPerson ] <|
                div [ class "mb-4" ]
                    [ label [ class S.inputLabel ]
                        [ Icons.personIcon2 "mr-2"
                        , text "Person"
                        , addIconLink "Add new correspondent person" StartCorrPersonModal
                        , editIconLink "Edit person"
                            model.corrPersonModel
                            (StartEditPersonModal model.corrPersonModel)
                        ]
                    , Html.map CorrPersonMsg (Comp.Dropdown.view2 dds settings model.corrPersonModel)
                    , renderCorrPersonSuggestions model
                    , div
                        [ classList
                            [ ( "hidden", personMatchesOrg model )
                            ]
                        , class S.message
                        , class "my-2"
                        ]
                        [ i [ class "fa fa-info mr-2 " ] []
                        , text "The selected person doesn't belong to the selected organization."
                        ]
                    ]
            ]
      }
    , { title = "Concerning"
      , info = Nothing
      , body =
            [ optional [ Data.Fields.ConcPerson ] <|
                div [ class "mb-4" ]
                    [ label [ class S.inputLabel ]
                        [ Icons.personIcon2 "mr-2"
                        , text "Person"
                        , addIconLink "Add new concerning person" StartConcPersonModal
                        , editIconLink "Edit person"
                            model.concPersonModel
                            (StartEditPersonModal model.concPersonModel)
                        ]
                    , Html.map ConcPersonMsg
                        (Comp.Dropdown.view2
                            dds
                            settings
                            model.concPersonModel
                        )
                    , renderConcPersonSuggestions model
                    ]
            , optional [ Data.Fields.ConcEquip ] <|
                div [ class "mb-4" ]
                    [ label [ class S.inputLabel ]
                        [ Icons.equipmentIcon2 "mr-2"
                        , text "Equipment"
                        , addIconLink "Add new equipment" StartEquipModal
                        , editIconLink "Edit equipment"
                            model.concEquipModel
                            StartEditEquipModal
                        ]
                    , Html.map ConcEquipMsg
                        (Comp.Dropdown.view2
                            dds
                            settings
                            model.concEquipModel
                        )
                    , renderConcEquipSuggestions model
                    ]
            ]
      }
    , { title = "Direction"
      , info = Nothing
      , body =
            [ div [ class "mb-4" ]
                [ Html.map DirDropdownMsg
                    (Comp.Dropdown.view2
                        dds
                        settings
                        model.directionModel
                    )
                ]
            ]
      }
    ]


renderSuggestions : Model -> (a -> String) -> List a -> (a -> Msg) -> Html Msg
renderSuggestions model mkName idnames tagger =
    div
        [ classList
            [ ( "hidden", model.item.state /= "created" )
            ]
        , class "flex flex-col text-sm"
        ]
        [ div [ class "font-bold my-1" ]
            [ text "Suggestions"
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


renderOrgSuggestions : Model -> Html Msg
renderOrgSuggestions model =
    renderSuggestions model
        .name
        (List.take 6 model.itemProposals.corrOrg)
        SetCorrOrgSuggestion


renderCorrPersonSuggestions : Model -> Html Msg
renderCorrPersonSuggestions model =
    renderSuggestions model
        .name
        (List.take 6 model.itemProposals.corrPerson)
        SetCorrPersonSuggestion


renderConcPersonSuggestions : Model -> Html Msg
renderConcPersonSuggestions model =
    renderSuggestions model
        .name
        (List.take 6 model.itemProposals.concPerson)
        SetConcPersonSuggestion


renderConcEquipSuggestions : Model -> Html Msg
renderConcEquipSuggestions model =
    renderSuggestions model
        .name
        (List.take 6 model.itemProposals.concEquipment)
        SetConcEquipSuggestion


renderItemDateSuggestions : Model -> Html Msg
renderItemDateSuggestions model =
    renderSuggestions model
        Util.Time.formatDate
        (List.take 6 model.itemProposals.itemDate)
        SetItemDateSuggestion


renderDueDateSuggestions : Model -> Html Msg
renderDueDateSuggestions model =
    renderSuggestions model
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
        (.title >> ToggleAkkordionTab)
