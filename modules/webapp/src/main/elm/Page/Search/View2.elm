{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Search.View2 exposing (viewContent, viewSidebar)

import Api
import Comp.Basic as B
import Comp.BookmarkQueryManage
import Comp.ConfirmModal
import Comp.DownloadAll
import Comp.ItemCardList
import Comp.ItemMerge
import Comp.MenuBar as MB
import Comp.PowerSearchInput
import Comp.PublishItems
import Comp.SearchMenu
import Comp.SearchStatsView
import Data.Environment as Env
import Data.Flags exposing (Flags)
import Data.Icons as Icons
import Data.ItemArrange
import Data.ItemIds exposing (ItemIds)
import Data.ItemSelection
import Data.SearchMode
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Messages.Page.Search exposing (Texts)
import Page exposing (Page(..))
import Page.Search.Data exposing (..)
import Page.Search.SideMenu
import Set
import Styles as S
import Util.Html


viewSidebar : Texts -> Env.View -> Model -> Html Msg
viewSidebar texts env model =
    div
        [ id "sidebar"
        , class S.sidebar
        , class S.sidebarBg
        , classList [ ( "hidden", not env.sidebarVisible ) ]
        ]
        [ Page.Search.SideMenu.view texts.sideMenu env model
        ]


viewContent : Texts -> Env.View -> Model -> Html Msg
viewContent texts env model =
    div
        [ id "item-card-list" -- this id is used in scroll-to-card
        , class S.content
        ]
        (searchStats texts env.flags env.settings model
            ++ itemsBar texts env model
            ++ mainView texts env model
            ++ confirmModal texts model
        )



--- Helpers


mainView : Texts -> Env.View -> Model -> List (Html Msg)
mainView texts env model =
    let
        otherView =
            case model.viewMode of
                SelectView svm ->
                    case svm.action of
                        MergeSelected ->
                            Just
                                [ div [ class "sm:relative mb-2" ]
                                    (itemMergeView texts env.settings svm)
                                ]

                        PublishSelected ->
                            Just
                                [ div [ class "sm:relative mb-2" ]
                                    (itemPublishView texts env.settings env.flags svm)
                                ]

                        _ ->
                            Nothing

                PublishView pm ->
                    Just
                        [ div [ class "sm:relative mb-2" ]
                            (publishResults texts env.settings env.flags model pm)
                        ]

                SearchView ->
                    Nothing
    in
    case otherView of
        Just body ->
            body

        Nothing ->
            bookmarkQueryWidget texts env.settings env.flags model
                ++ itemCardList texts env model


bookmarkQueryWidget : Texts -> UiSettings -> Flags -> Model -> List (Html Msg)
bookmarkQueryWidget texts _ flags model =
    case model.topWidgetModel of
        BookmarkQuery m ->
            [ div [ class "px-2 mb-4 border-l border-r border-b dark:border-slate-600" ]
                [ Html.map BookmarkQueryMsg (Comp.BookmarkQueryManage.view texts.bookmarkManage m)
                ]
            ]

        DownloadAll m ->
            [ div [ class "mb-4 border-l border-r border-b dark:border-slate-600" ]
                [ Html.map DownloadAllMsg (Comp.DownloadAll.view flags texts.downloadAllComp m)
                ]
            ]

        TopWidgetHidden ->
            []


itemPublishView : Texts -> UiSettings -> Flags -> SelectViewModel -> List (Html Msg)
itemPublishView texts settings flags svm =
    [ Html.map PublishItemsMsg
        (Comp.PublishItems.view texts.publishItems settings flags svm.publishModel)
    ]


itemMergeView : Texts -> UiSettings -> SelectViewModel -> List (Html Msg)
itemMergeView texts settings svm =
    let
        cfgMerge =
            { infoMessage = texts.mergeInfoText
            , warnMessage = texts.mergeDeleteWarn
            , actionButton = texts.submitMerge
            , actionTitle = texts.submitMergeTitle
            , cancelTitle = texts.cancelMergeTitle
            , actionSuccessful = texts.mergeSuccessful
            , actionInProcess = texts.mergeInProcess
            , title = texts.mergeHeader
            , actionIcon = "fa fa-less-than"
            }

        cfgLink =
            { infoMessage = ""
            , warnMessage = texts.linkItemsMessage
            , actionButton = texts.submitLinkItems
            , actionTitle = texts.submitLinkItemsTitle
            , cancelTitle = texts.cancelLinkItemsTitle
            , actionSuccessful = texts.linkItemsSuccessful
            , actionInProcess = texts.linkItemsInProcess
            , title = texts.linkItemsHeader
            , actionIcon = "fa fa-link"
            }

        ( mergeModel, cfg ) =
            case svm.mergeModel of
                MergeItems a ->
                    ( a, cfgMerge )

                LinkItems a ->
                    ( a, cfgLink )
    in
    [ Html.map MergeItemsMsg
        (Comp.ItemMerge.view texts.itemMerge cfg settings mergeModel)
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


itemsBar : Texts -> Env.View -> Model -> List (Html Msg)
itemsBar texts env model =
    case model.viewMode of
        SearchView ->
            [ defaultMenuBar texts env model ]

        SelectView svm ->
            [ editMenuBar texts model env.selectedItems svm ]

        PublishView _ ->
            [ defaultMenuBar texts env model ]


defaultMenuBar : Texts -> Env.View -> Model -> Html Msg
defaultMenuBar texts env model =
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
                    , if env.flags.config.fullTextSearchEnabled then
                        class " border-r-0 rounded-l"

                      else
                        class "border rounded"
                    ]
                    []
                , a
                    [ class S.secondaryBasicButtonPlain
                    , class "text-sm px-4 py-2 border rounded-r"
                    , classList
                        [ ( "hidden", not env.flags.config.fullTextSearchEnabled )
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
                        }
                        model.powerSearchInput
                    )
                , Html.map PowerSearchMsg
                    (Comp.PowerSearchInput.viewResult [] model.powerSearchInput)
                ]

        isCardView =
            env.settings.itemSearchArrange == Data.ItemArrange.Cards

        isListView =
            env.settings.itemSearchArrange == Data.ItemArrange.List

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
                if env.settings.powerSearchEnabled then
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
                            if env.settings.itemSearchShowGroups then
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
                      , disabled = createQuery env.selectedItems model == Nothing
                      , attrs =
                            [ title <|
                                if createQuery env.selectedItems model == Nothing then
                                    texts.nothingSelectedToShare

                                else
                                    texts.publishCurrentQueryTitle
                            , href "#"
                            , if createQuery env.selectedItems model == Nothing then
                                class ""

                              else
                                onClick TogglePublishCurrentQueryView
                            ]
                      }
                    , { label = texts.bookmarkQuery
                      , icon = i [ class "fa fa-bookmark" ] []
                      , disabled = createQuery env.selectedItems model == Nothing
                      , attrs =
                            [ title <|
                                if createQuery env.selectedItems model == Nothing then
                                    texts.nothingToBookmark

                                else
                                    texts.bookmarkQuery
                            , href "#"
                            , if createQuery env.selectedItems model == Nothing then
                                class ""

                              else
                                onClick ToggleBookmarkCurrentQueryView
                            ]
                      }
                    , { label = texts.downloadAll
                      , icon = i [ class "fa fa-download" ] []
                      , disabled = createQuery env.selectedItems model == Nothing
                      , attrs =
                            [ title <|
                                if createQuery env.selectedItems model == Nothing then
                                    texts.downloadAllQueryNeeded

                                else
                                    texts.downloadAll
                            , href "#"
                            , if createQuery env.selectedItems model == Nothing then
                                class ""

                              else
                                onClick ToggleDownloadAllView
                            ]
                      }
                    , { label =
                            if env.settings.cardPreviewFullWidth then
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
                                , ( "bg-gray-200 dark:bg-slate-600", env.settings.cardPreviewFullWidth )
                                ]
                            ]
                      }
                    ]
                }
            ]
        , rootClasses = "mb-2 pt-1 dark:bg-slate-700 items-center text-sm"
        , sticky = True
        }


editMenuBar : Texts -> Model -> ItemIds -> SelectViewModel -> Html Msg
editMenuBar texts model selectedItems svm =
    let
        selectCount =
            Data.ItemIds.size selectedItems

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
                { tagger = MergeSelectedItems MergeItems
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
            , MB.CustomButton
                { tagger = MergeSelectedItems LinkItems
                , label = ""
                , icon = Just Icons.linkItems
                , title = texts.linkItemsTitle selectCount
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
        , sticky = True
        }


searchStats : Texts -> Flags -> UiSettings -> Model -> List (Html Msg)
searchStats texts _ settings model =
    if settings.searchStatsVisible then
        [ Comp.SearchStatsView.view texts.searchStatsView "my-2" model.searchStats
        ]

    else
        []


itemCardList : Texts -> Env.View -> Model -> List (Html Msg)
itemCardList texts env model =
    let
        previewUrl attach =
            Api.attachmentPreviewURL attach.id

        previewUrlFallback item =
            Api.itemBasePreviewURL item.id

        viewCfg sel =
            { current = model.scrollToCard
            , selection = sel
            , previewUrl = previewUrl
            , previewUrlFallback = previewUrlFallback
            , attachUrl = .id >> Api.fileURL
            , detailPage = .id >> ItemDetailPage
            , arrange = env.settings.itemSearchArrange
            , showGroups = env.settings.itemSearchShowGroups
            , rowOpen = \id -> Set.member "all" model.itemRowsOpen || Set.member id model.itemRowsOpen
            }

        itemViewCfg =
            case model.viewMode of
                SelectView _ ->
                    viewCfg (Data.ItemSelection.Active env.selectedItems)

                _ ->
                    viewCfg Data.ItemSelection.Inactive
    in
    [ Html.map ItemCardListMsg
        (Comp.ItemCardList.view texts.itemCardList
            itemViewCfg
            env.settings
            env.flags
            model.itemListModel
        )
    , loadMore texts env.settings model
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
