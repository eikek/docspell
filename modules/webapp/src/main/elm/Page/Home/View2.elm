{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Home.View2 exposing (viewContent, viewSidebar)

import Api
import Comp.Basic as B
import Comp.BookmarkQueryManage
import Comp.ConfirmModal
import Comp.ItemCardList
import Comp.ItemMerge
import Comp.MenuBar as MB
import Comp.PowerSearchInput
import Comp.PublishItems
import Comp.SearchMenu
import Comp.SearchStatsView
import Data.Flags exposing (Flags)
import Data.Icons as Icons
import Data.ItemArrange
import Data.ItemSelection
import Data.SearchMode
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
            ++ mainView texts flags settings model
            ++ confirmModal texts model
        )



--- Helpers


mainView : Texts -> Flags -> UiSettings -> Model -> List (Html Msg)
mainView texts flags settings model =
    let
        otherView =
            case model.viewMode of
                SelectView svm ->
                    case svm.action of
                        MergeSelected ->
                            Just
                                [ div [ class "sm:relative mb-2" ]
                                    (itemMergeView texts flags settings svm)
                                ]

                        PublishSelected ->
                            Just
                                [ div [ class "sm:relative mb-2" ]
                                    (itemPublishView texts settings flags svm)
                                ]

                        _ ->
                            Nothing

                PublishView pm ->
                    Just
                        [ div [ class "sm:relative mb-2" ]
                            (publishResults texts settings flags model pm)
                        ]

                SimpleView ->
                    Nothing

                SearchView ->
                    Nothing
    in
    case otherView of
        Just body ->
            body

        Nothing ->
            bookmarkQueryWidget texts settings flags model
                ++ itemCardList texts flags settings model


bookmarkQueryWidget : Texts -> UiSettings -> Flags -> Model -> List (Html Msg)
bookmarkQueryWidget texts settings flags model =
    case model.topWidgetModel of
        BookmarkQuery m ->
            [ div [ class "px-2 mb-4 border-l border-r border-b dark:border-slate-600" ]
                [ Html.map BookmarkQueryMsg (Comp.BookmarkQueryManage.view texts.bookmarkManage m)
                ]
            ]

        TopWidgetHidden ->
            []


itemPublishView : Texts -> UiSettings -> Flags -> SelectViewModel -> List (Html Msg)
itemPublishView texts settings flags svm =
    [ Html.map PublishItemsMsg
        (Comp.PublishItems.view texts.publishItems settings flags svm.publishModel)
    ]


itemMergeView : Texts -> Flags -> UiSettings -> SelectViewModel -> List (Html Msg)
itemMergeView texts flags settings svm =
    [ Html.map MergeItemsMsg
        (Comp.ItemMerge.view texts.itemMerge flags settings svm.mergeModel)
    ]


publishResults : Texts -> UiSettings -> Flags -> Model -> Comp.PublishItems.Model -> List (Html Msg)
publishResults texts settings flags _ pm =
    [ Html.map PublishViewMsg
        (Comp.PublishItems.view texts.publishItems settings flags pm)
    ]


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

                ConfirmRestore ->
                    Comp.ConfirmModal.defaultSettings
                        RestoreSelectedConfirmed
                        CloseConfirmModal
                        texts.basics.yes
                        texts.basics.no
                        texts.reallyRestoreQuestion
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

        PublishView _ ->
            [ defaultMenuBar texts flags settings model ]


defaultMenuBar : Texts -> Flags -> UiSettings -> Model -> Html Msg
defaultMenuBar texts flags settings model =
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
                    , class "py-2 text-sm"
                    , if flags.config.fullTextSearchEnabled then
                        class " border-r-0 rounded-l"

                      else
                        class "border rounded"
                    ]
                    []
                , a
                    [ class S.secondaryBasicButtonPlain
                    , class "text-sm px-4 py-2 border rounded-r"
                    , classList
                        [ ( "hidden", not flags.config.fullTextSearchEnabled )
                        ]
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

        isCardView =
            settings.itemSearchArrange == Data.ItemArrange.Cards

        isListView =
            settings.itemSearchArrange == Data.ItemArrange.List

        menuSep =
            { icon = i [] []
            , label = "separator"
            , disabled = False
            , attrs =
                []
            }
    in
    MB.view
        { start =
            [ MB.CustomElement <|
                if settings.powerSearchEnabled then
                    powerSearchBar

                else
                    simpleSearchBar
            ]
        , end =
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
                    , ( "bg-gray-200 dark:bg-slate-600", selectActive model )
                    ]
                }
            , MB.Dropdown
                { linkIcon = "fa fa-bars"
                , label = ""
                , linkClass =
                    [ ( S.secondaryBasicButton, True )
                    ]
                , toggleMenu = ToggleViewMenu
                , menuOpen = model.viewMenuOpen
                , items =
                    [ { icon =
                            if settings.itemSearchShowGroups then
                                i [ class "fa fa-check-square font-thin" ] []

                            else
                                i [ class "fa fa-square font-thin" ] []
                      , disabled = List.length model.itemListModel.results.groups <= 1
                      , label = texts.showItemGroups
                      , attrs =
                            [ href "#"
                            , if List.length model.itemListModel.results.groups <= 1 then
                                class ""

                              else
                                onClick ToggleShowGroups
                            ]
                      }
                    , { icon =
                            if isListView then
                                i [ class "fa fa-check" ] []

                            else
                                i [ class "fa fa-list" ] []
                      , disabled = False
                      , label = texts.listView
                      , attrs =
                            [ href "#"
                            , onClick (ToggleArrange Data.ItemArrange.List)
                            ]
                      }
                    , { icon =
                            if isCardView then
                                i [ class "fa fa-check" ] []

                            else
                                i [ class "fa fa-th-large" ] []
                      , disabled = False
                      , label = texts.tileView
                      , attrs =
                            [ href "#"
                            , onClick (ToggleArrange Data.ItemArrange.Cards)
                            ]
                      }
                    , { icon = i [ class "fa fa-compress" ] []
                      , label = texts.expandCollapseRows
                      , disabled = False
                      , attrs =
                            [ href "#"
                            , classList [ ( "hidden", not isListView ) ]
                            , onClick ToggleExpandCollapseRows
                            ]
                      }
                    , menuSep
                    , { label = texts.shareResults
                      , icon = Icons.shareIcon ""
                      , disabled = createQuery model == Nothing
                      , attrs =
                            [ title <|
                                if createQuery model == Nothing then
                                    texts.nothingSelectedToShare

                                else
                                    texts.publishCurrentQueryTitle
                            , href "#"
                            , if createQuery model == Nothing then
                                class ""

                              else
                                onClick TogglePublishCurrentQueryView
                            ]
                      }
                    , { label = texts.bookmarkQuery
                      , icon = i [ class "fa fa-bookmark" ] []
                      , disabled = createQuery model == Nothing
                      , attrs =
                            [ title <|
                                if createQuery model == Nothing then
                                    texts.nothingToBookmark

                                else
                                    texts.bookmarkQuery
                            , href "#"
                            , if createQuery model == Nothing then
                                class ""

                              else
                                onClick ToggleBookmarkCurrentQueryView
                            ]
                      }
                    , { label =
                            if settings.cardPreviewFullWidth then
                                texts.fullHeightPreviewTitle

                            else
                                texts.fullWidthPreviewTitle
                      , icon = i [ class "fa fa-expand" ] []
                      , disabled = False
                      , attrs =
                            [ href "#"
                            , onClick TogglePreviewFullWidth
                            , classList
                                [ ( "hidden sm:inline-block", False )
                                , ( "bg-gray-200 dark:bg-slate-600", settings.cardPreviewFullWidth )
                                ]
                            ]
                      }
                    ]
                }
            ]
        , rootClasses = "mb-2 pt-1 dark:bg-slate-700 items-center text-sm"
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
                    , ( "bg-gray-200 dark:bg-slate-600", svm.action == EditSelected )
                    , ( "hidden", model.searchMenuModel.searchMode == Data.SearchMode.Trashed )
                    ]
                }
            , MB.CustomButton
                { tagger = RequestReprocessSelected
                , label = ""
                , icon = Just "fa fa-redo"
                , title = texts.reprocessSelectedItems selectCount
                , inputClass =
                    [ ( btnStyle, True )
                    , ( "bg-gray-200 dark:bg-slate-600", svm.action == ReprocessSelected )
                    , ( "hidden", model.searchMenuModel.searchMode == Data.SearchMode.Trashed )
                    ]
                }
            , MB.CustomButton
                { tagger = RequestDeleteSelected
                , label = ""
                , icon = Just "fa fa-trash"
                , title = texts.deleteSelectedItems selectCount
                , inputClass =
                    [ ( btnStyle, True )
                    , ( "bg-gray-200 dark:bg-slate-600", svm.action == DeleteSelected )
                    , ( "hidden", model.searchMenuModel.searchMode == Data.SearchMode.Trashed )
                    ]
                }
            , MB.CustomButton
                { tagger = RequestRestoreSelected
                , label = ""
                , icon = Just "fa fa-trash-restore"
                , title = texts.undeleteSelectedItems selectCount
                , inputClass =
                    [ ( btnStyle, True )
                    , ( "bg-gray-200 dark:bg-slate-600", svm.action == RestoreSelected )
                    , ( "hidden", model.searchMenuModel.searchMode == Data.SearchMode.Normal )
                    ]
                }
            , MB.CustomButton
                { tagger = MergeSelectedItems
                , label = ""
                , icon = Just "fa fa-less-than"
                , title = texts.mergeItemsTitle selectCount
                , inputClass =
                    [ ( btnStyle, True )
                    , ( "bg-gray-200 dark:bg-slate-600", svm.action == MergeSelected )
                    , ( "hidden", model.searchMenuModel.searchMode == Data.SearchMode.Trashed )
                    ]
                }
            , MB.CustomButton
                { tagger = PublishSelectedItems
                , label = ""
                , icon = Just Icons.share
                , title = texts.publishItemsTitle selectCount
                , inputClass =
                    [ ( btnStyle, True )
                    , ( "bg-gray-200 dark:bg-slate-600", svm.action == PublishSelected )
                    , ( "hidden", model.searchMenuModel.searchMode == Data.SearchMode.Trashed )
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
                , class = "px-4 py-2 w-10 rounded-full font-bold bg-blue-100 dark:bg-sky-600 "
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
                    , ( "bg-gray-200 dark:bg-slate-600", selectActive model )
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
itemCardList texts flags settings model =
    let
        previewUrl attach =
            Api.attachmentPreviewURL flags attach.id

        previewUrlFallback item =
            Api.itemBasePreviewURL flags item.id

        viewCfg sel =
            { current = model.scrollToCard
            , selection = sel
            , previewUrl = previewUrl
            , previewUrlFallback = previewUrlFallback
            , attachUrl = .id >> Api.fileURL flags
            , detailPage = .id >> ItemDetailPage
            , arrange = settings.itemSearchArrange
            , showGroups = settings.itemSearchShowGroups
            , rowOpen = \id -> Set.member "all" model.itemRowsOpen || Set.member id model.itemRowsOpen
            }

        itemViewCfg =
            case model.viewMode of
                SelectView svm ->
                    viewCfg (Data.ItemSelection.Active svm.ids)

                _ ->
                    viewCfg Data.ItemSelection.Inactive
    in
    [ Html.map ItemCardListMsg
        (Comp.ItemCardList.view texts.itemCardList
            itemViewCfg
            settings
            flags
            model.itemListModel
        )
    , loadMore texts settings model
    ]


loadMore : Texts -> UiSettings -> Model -> Html Msg
loadMore texts settings model =
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
                    texts.loadMore

                else
                    texts.thatsAll
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
