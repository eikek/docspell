module Page.Home.View2 exposing (viewContent, viewSidebar)

import Comp.Basic as B
import Comp.ConfirmModal
import Comp.ItemCardList
import Comp.MenuBar as MB
import Comp.PowerSearchInput
import Comp.SearchMenu
import Comp.SearchStatsView
import Data.Flags exposing (Flags)
import Data.ItemSelection
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Messages.Page.Home exposing (Texts)
import Page exposing (Page(..))
import Page.Home.Data exposing (..)
import Page.Home.SideMenu
import Set
import Styles as S
import Util.Html


viewSidebar : Texts -> Bool -> Flags -> UiSettings -> Model -> Html Msg
viewSidebar texts visible flags settings model =
    div
        [ id "sidebar"
        , class S.sidebar
        , class S.sidebarBg
        , classList [ ( "hidden", not visible ) ]
        ]
        [ Page.Home.SideMenu.view texts.sideMenu flags settings model
        ]


viewContent : Texts -> Flags -> UiSettings -> Model -> Html Msg
viewContent texts flags settings model =
    div
        [ id "item-card-list" -- this id is used in scroll-to-card
        , class S.content
        ]
        (searchStats texts flags settings model
            ++ itemsBar texts flags settings model
            ++ itemCardList texts flags settings model
            ++ confirmModal texts model
        )



--- Helpers


confirmModal : Texts -> Model -> List (Html Msg)
confirmModal texts model =
    let
        settings modalValue =
            case modalValue of
                ConfirmReprocessItems ->
                    Comp.ConfirmModal.defaultSettings
                        ReprocessSelectedConfirmed
                        CloseConfirmModal
                        texts.basics.yes
                        texts.basics.no
                        texts.reallyReprocessQuestion

                ConfirmDelete ->
                    Comp.ConfirmModal.defaultSettings
                        DeleteSelectedConfirmed
                        CloseConfirmModal
                        texts.basics.yes
                        texts.basics.no
                        texts.reallyDeleteQuestion
    in
    case model.viewMode of
        SelectView svm ->
            case svm.confirmModal of
                Just confirm ->
                    [ Comp.ConfirmModal.view (settings confirm)
                    ]

                Nothing ->
                    []

        _ ->
            []


itemsBar : Texts -> Flags -> UiSettings -> Model -> List (Html Msg)
itemsBar texts flags settings model =
    case model.viewMode of
        SimpleView ->
            [ defaultMenuBar texts flags settings model ]

        SearchView ->
            [ defaultMenuBar texts flags settings model ]

        SelectView svm ->
            [ editMenuBar texts model svm ]


defaultMenuBar : Texts -> Flags -> UiSettings -> Model -> Html Msg
defaultMenuBar texts _ settings model =
    let
        btnStyle =
            S.secondaryBasicButton ++ " text-sm"

        searchInput =
            Comp.SearchMenu.textSearchString
                model.searchMenuModel.textSearchModel

        simpleSearchBar =
            div
                [ class "relative flex flex-row" ]
                [ input
                    [ type_ "text"
                    , placeholder
                        (case model.searchTypeDropdownValue of
                            ContentOnlySearch ->
                                texts.contentSearch

                            BasicSearch ->
                                texts.searchInNames
                        )
                    , onInput SetBasicSearch
                    , Util.Html.onKeyUpCode KeyUpSearchbarMsg
                    , Maybe.map value searchInput
                        |> Maybe.withDefault (value "")
                    , class (String.replace "rounded" "" S.textInput)
                    , class "py-1 text-sm border-r-0 rounded-l"
                    ]
                    []
                , a
                    [ class S.secondaryBasicButtonPlain
                    , class "text-sm px-4 py-2 border rounded-r"
                    , href "#"
                    , onClick ToggleSearchType
                    ]
                    [ i [ class "fa fa-exchange-alt" ] []
                    ]
                ]

        powerSearchBar =
            div
                [ class "relative flex flex-grow flex-row" ]
                [ Html.map PowerSearchMsg
                    (Comp.PowerSearchInput.viewInput
                        { placeholder = texts.powerSearchPlaceholder
                        , extraAttrs = []
                        }
                        model.powerSearchInput
                    )
                , Html.map PowerSearchMsg
                    (Comp.PowerSearchInput.viewResult [] model.powerSearchInput)
                ]
    in
    MB.view
        { end =
            [ MB.CustomElement <|
                B.secondaryBasicButton
                    { label = ""
                    , icon =
                        if model.searchInProgress then
                            "fa fa-sync animate-spin"

                        else
                            "fa fa-sync"
                    , disabled = model.searchInProgress
                    , handler = onClick ResetSearch
                    , attrs = [ href "#" ]
                    }
            , MB.CustomButton
                { tagger = ToggleSelectView
                , label = ""
                , icon = Just "fa fa-tasks"
                , title = texts.selectModeTitle
                , inputClass =
                    [ ( btnStyle, True )
                    , ( "bg-gray-200 dark:bg-bluegray-600", selectActive model )
                    ]
                }
            ]
        , start =
            [ MB.CustomElement <|
                if settings.powerSearchEnabled then
                    powerSearchBar

                else
                    simpleSearchBar
            , MB.CustomButton
                { tagger = TogglePreviewFullWidth
                , label = ""
                , icon = Just "fa fa-expand"
                , title =
                    if settings.cardPreviewFullWidth then
                        texts.fullHeightPreviewTitle

                    else
                        texts.fullWidthPreviewTitle
                , inputClass =
                    [ ( btnStyle, True )
                    , ( "hidden sm:inline-block", False )
                    , ( "bg-gray-200 dark:bg-bluegray-600", settings.cardPreviewFullWidth )
                    ]
                }
            ]
        , rootClasses = "mb-2 pt-1 dark:bg-bluegray-700 items-center text-sm"
        }


editMenuBar : Texts -> Model -> SelectViewModel -> Html Msg
editMenuBar texts model svm =
    let
        selectCount =
            Set.size svm.ids

        btnStyle =
            S.secondaryBasicButton ++ " text-sm"
    in
    MB.view
        { start =
            [ MB.CustomButton
                { tagger = EditSelectedItems
                , label = ""
                , icon = Just "fa fa-edit"
                , title = texts.editSelectedItems selectCount
                , inputClass =
                    [ ( btnStyle, True )
                    , ( "bg-gray-200 dark:bg-bluegray-600", svm.action == EditSelected )
                    ]
                }
            , MB.CustomButton
                { tagger = RequestReprocessSelected
                , label = ""
                , icon = Just "fa fa-redo"
                , title = texts.reprocessSelectedItems selectCount
                , inputClass =
                    [ ( btnStyle, True )
                    , ( "bg-gray-200 dark:bg-bluegray-600", svm.action == ReprocessSelected )
                    ]
                }
            , MB.CustomButton
                { tagger = RequestDeleteSelected
                , label = ""
                , icon = Just "fa fa-trash"
                , title = texts.deleteSelectedItems selectCount
                , inputClass =
                    [ ( btnStyle, True )
                    , ( "bg-gray-200 dark:bg-bluegray-600", svm.action == DeleteSelected )
                    ]
                }
            ]
        , end =
            [ MB.CustomButton
                { tagger = SelectAllItems
                , label = ""
                , icon = Just "fa fa-check-square font-thin"
                , title = texts.selectAllVisible
                , inputClass =
                    [ ( btnStyle, True )
                    ]
                }
            , MB.CustomButton
                { tagger = SelectNoItems
                , label = ""
                , icon = Just "fa fa-square font-thin"
                , title = texts.selectNone
                , inputClass =
                    [ ( btnStyle, True )
                    ]
                }
            , MB.TextLabel
                { icon = ""
                , label = String.fromInt selectCount
                , class = "px-4 py-2 w-10 rounded-full font-bold bg-blue-100 dark:bg-lightblue-600 "
                }
            , MB.CustomButton
                { tagger = ResetSearch
                , label = ""
                , icon = Just "fa fa-sync"
                , title = texts.resetSearchForm
                , inputClass =
                    [ ( btnStyle, True )
                    , ( "hidden sm:block", True )
                    ]
                }
            , MB.CustomButton
                { tagger = ToggleSelectView
                , label = ""
                , icon = Just "fa fa-tasks"
                , title = texts.exitSelectMode
                , inputClass =
                    [ ( btnStyle, True )
                    , ( "bg-gray-200 dark:bg-bluegray-600", selectActive model )
                    ]
                }
            ]
        , rootClasses = "mb-2 pt-2 sticky top-0 text-sm"
        }


searchStats : Texts -> Flags -> UiSettings -> Model -> List (Html Msg)
searchStats texts _ settings model =
    if settings.searchStatsVisible then
        [ Comp.SearchStatsView.view2 texts.searchStatsView "my-2" model.searchStats
        ]

    else
        []


itemCardList : Texts -> Flags -> UiSettings -> Model -> List (Html Msg)
itemCardList texts _ settings model =
    let
        itemViewCfg =
            case model.viewMode of
                SelectView svm ->
                    Comp.ItemCardList.ViewConfig
                        model.scrollToCard
                        (Data.ItemSelection.Active svm.ids)

                _ ->
                    Comp.ItemCardList.ViewConfig
                        model.scrollToCard
                        Data.ItemSelection.Inactive
    in
    [ Html.map ItemCardListMsg
        (Comp.ItemCardList.view2 texts.itemCardList
            itemViewCfg
            settings
            model.itemListModel
        )
    , loadMore settings model
    ]


loadMore : UiSettings -> Model -> Html Msg
loadMore settings model =
    let
        inactive =
            not model.moreAvailable || model.moreInProgress || model.searchInProgress
    in
    div
        [ class "h-40 flex flex-col items-center justify-center w-full"
        , classList [ ( "hidden", resultsBelowLimit settings model ) ]
        ]
        [ B.secondaryBasicButton
            { label =
                if model.moreAvailable then
                    "Load more…"

                else
                    "That's all"
            , icon =
                if model.moreInProgress then
                    "fa fa-circle-notch animate-spin"

                else
                    "fa fa-angle-double-down"
            , handler = onClick LoadMore
            , disabled = inactive
            , attrs = []
            }
        ]
