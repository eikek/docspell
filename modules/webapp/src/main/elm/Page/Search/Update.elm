{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Search.Update exposing
    ( UpdateResult
    , update
    )

import Api
import Api.Model.ItemLightList exposing (ItemLightList)
import Comp.BookmarkQueryManage
import Comp.DownloadAll
import Comp.ItemCardList
import Comp.ItemDetail.FormChange exposing (FormChange(..))
import Comp.ItemDetail.MultiEditMenu exposing (SaveNameState(..))
import Comp.ItemMerge
import Comp.LinkTarget exposing (LinkTarget)
import Comp.PowerSearchInput
import Comp.PublishItems
import Comp.SearchMenu
import Data.AppEvent exposing (AppEvent(..))
import Data.Environment as Env
import Data.Flags exposing (Flags)
import Data.ItemArrange
import Data.ItemIds exposing (ItemIds)
import Data.ItemQuery as Q
import Data.Items
import Data.SearchMode exposing (SearchMode)
import Messages.Page.Search exposing (Texts)
import Page exposing (Page(..))
import Page.Search.Data exposing (..)
import Process
import Scroll
import Set
import Task
import Util.Html exposing (KeyCode(..))
import Util.ItemDragDrop as DD
import Util.Update


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    , appEvent : AppEvent
    , selectedItems : ItemIds
    }


update : Texts -> Maybe String -> Maybe String -> Env.Update -> Msg -> Model -> UpdateResult
update texts bookmarkId lastViewedItemId env msg model =
    case msg of
        Init ->
            let
                searchParam =
                    { flags = env.flags
                    , searchType = model.lastSearchType
                    , pageSize = env.settings.itemSearchPageSize
                    , offset = 0
                    , scroll = True
                    , selectedItems = env.selectedItems
                    }

                setBookmark =
                    Maybe.map (\bmId -> SearchMenuMsg <| Comp.SearchMenu.SetBookmark bmId) bookmarkId
                        |> Maybe.withDefault DoNothing
            in
            makeResult env.selectedItems <|
                Util.Update.andThen3
                    [ update texts bookmarkId lastViewedItemId env (SearchMenuMsg Comp.SearchMenu.Init)
                    , update texts bookmarkId lastViewedItemId env setBookmark
                    , doSearch env.selectedItems searchParam
                    ]
                    model

        DoNothing ->
            UpdateResult model Cmd.none Sub.none AppNothing env.selectedItems

        ResetSearch ->
            let
                nm =
                    { model | searchOffset = 0, powerSearchInput = Comp.PowerSearchInput.init }
            in
            update texts bookmarkId lastViewedItemId env (SearchMenuMsg Comp.SearchMenu.ResetForm) nm

        SearchMenuMsg m ->
            let
                nextState =
                    Comp.SearchMenu.updateDrop
                        model.dragDropData.model
                        env.flags
                        env.settings
                        m
                        model.searchMenuModel

                dropCmd =
                    DD.makeUpdateCmd env.flags (\_ -> DoSearch model.lastSearchType) nextState.dragDrop.dropped

                newModel =
                    { model
                        | searchMenuModel = nextState.model
                        , dragDropData = nextState.dragDrop
                        , searchTypeDropdownValue =
                            if Comp.SearchMenu.isFulltextSearch nextState.model then
                                ContentOnlySearch

                            else
                                BasicSearch
                    }

                newSelection =
                    Data.ItemIds.apply env.selectedItems nextState.selectionChange

                searchParam =
                    { flags = env.flags
                    , searchType = BasicSearch
                    , pageSize = env.settings.itemSearchPageSize
                    , offset = 0
                    , scroll = False
                    , selectedItems = newSelection
                    }

                result =
                    if nextState.stateChange && not model.searchInProgress then
                        doSearch env.selectedItems searchParam newModel

                    else
                        resultModelCmd env.selectedItems ( newModel, Cmd.none )
            in
            { result
                | cmd =
                    Cmd.batch
                        [ result.cmd
                        , Cmd.map SearchMenuMsg nextState.cmd
                        , dropCmd
                        ]
                , sub = Sub.map SearchMenuMsg nextState.sub
                , selectedItems = newSelection
            }

        SetLinkTarget lt ->
            case linkTargetMsg lt of
                Just m ->
                    update texts bookmarkId lastViewedItemId env m model

                Nothing ->
                    makeResult env.selectedItems ( model, Cmd.none, Sub.none )

        ItemCardListMsg m ->
            let
                result =
                    Comp.ItemCardList.updateDrag model.dragDropData.model
                        env.flags
                        m
                        model.itemListModel

                searchMsg =
                    Maybe.map Util.Update.cmdUnit (linkTargetMsg result.linkTarget)
                        |> Maybe.withDefault Cmd.none

                itemIds =
                    Data.ItemIds.apply env.selectedItems result.selection

                itemRows =
                    case result.toggleOpenRow of
                        Just rid ->
                            if Set.member rid model.itemRowsOpen then
                                Set.remove rid model.itemRowsOpen

                            else
                                Set.insert rid model.itemRowsOpen

                        Nothing ->
                            model.itemRowsOpen
            in
            { model =
                { model
                    | itemListModel = result.model
                    , itemRowsOpen = itemRows
                    , dragDropData = DD.DragDropData result.dragModel Nothing
                }
            , cmd = Cmd.batch [ Cmd.map ItemCardListMsg result.cmd, searchMsg ]
            , sub = Sub.none
            , appEvent = AppNothing
            , selectedItems = itemIds
            }

        ToggleExpandCollapseRows ->
            let
                itemRows =
                    if Set.isEmpty model.itemRowsOpen then
                        Set.singleton "all"

                    else
                        Set.empty
            in
            resultModelCmd env.selectedItems ( { model | itemRowsOpen = itemRows, viewMenuOpen = False }, Cmd.none )

        ItemSearchResp scroll (Ok list) ->
            let
                noff =
                    env.settings.itemSearchPageSize

                m =
                    { model
                        | searchInProgress = False
                        , searchOffset = noff
                        , moreAvailable = Data.Items.nonEmpty list
                    }
            in
            makeResult env.selectedItems <|
                Util.Update.andThen3
                    [ update texts bookmarkId lastViewedItemId env (ItemCardListMsg (Comp.ItemCardList.SetResults list))
                    , if scroll then
                        scrollToCard env.selectedItems lastViewedItemId

                      else
                        \next -> makeResult env.selectedItems ( next, Cmd.none, Sub.none )
                    ]
                    m

        ItemSearchAddResp (Ok list) ->
            let
                noff =
                    model.searchOffset + env.settings.itemSearchPageSize

                m =
                    { model
                        | searchInProgress = False
                        , moreInProgress = False
                        , searchOffset = noff
                        , moreAvailable = Data.Items.nonEmpty list
                    }
            in
            update texts bookmarkId lastViewedItemId env (ItemCardListMsg (Comp.ItemCardList.AddResults list)) m

        ItemSearchAddResp (Err _) ->
            resultModelCmd env.selectedItems
                ( { model
                    | moreInProgress = False
                  }
                , Cmd.none
                )

        ItemSearchResp _ (Err _) ->
            resultModelCmd env.selectedItems
                ( { model
                    | searchInProgress = False
                  }
                , Cmd.none
                )

        DoSearch stype ->
            let
                nm =
                    { model | searchOffset = 0 }

                param =
                    { flags = env.flags
                    , searchType = stype
                    , pageSize = env.settings.itemSearchPageSize
                    , offset = 0
                    , scroll = False
                    , selectedItems = env.selectedItems
                    }
            in
            if model.searchInProgress then
                resultModelCmd env.selectedItems ( model, Cmd.none )

            else
                doSearch env.selectedItems param nm

        RefreshView ->
            let
                param =
                    { flags = env.flags
                    , searchType = model.lastSearchType
                    , pageSize = env.settings.itemSearchPageSize
                    , offset = model.searchOffset
                    , scroll = False
                    , selectedItems = env.selectedItems
                    }
            in
            if model.searchInProgress then
                resultModelCmd env.selectedItems ( model, Cmd.none )

            else
                doSearch env.selectedItems param model

        ToggleSelectView ->
            let
                ( nextView, cmd ) =
                    case model.viewMode of
                        SearchView ->
                            ( SelectView <| initSelectViewModel env.flags, loadEditModel env.flags )

                        SelectView _ ->
                            ( SearchView, Cmd.none )

                        PublishView q ->
                            ( PublishView q, Cmd.none )
            in
            resultModelCmd env.selectedItems ( { model | viewMode = nextView }, cmd )

        LoadMore ->
            if model.moreAvailable then
                doSearchMore env model |> resultModelCmd env.selectedItems

            else
                resultModelCmd env.selectedItems ( model, Cmd.none )

        SetBasicSearch str ->
            let
                smMsg =
                    SearchMenuMsg (Comp.SearchMenu.SetTextSearch str)
            in
            update texts bookmarkId lastViewedItemId env smMsg model

        ToggleSearchType ->
            case model.searchTypeDropdownValue of
                BasicSearch ->
                    update texts bookmarkId lastViewedItemId env (SearchMenuMsg Comp.SearchMenu.SetFulltextSearch) model

                ContentOnlySearch ->
                    update texts bookmarkId lastViewedItemId env (SearchMenuMsg Comp.SearchMenu.SetNamesSearch) model

        KeyUpSearchbarMsg (Just Enter) ->
            update texts bookmarkId lastViewedItemId env (DoSearch model.searchTypeDropdownValue) model

        KeyUpSearchbarMsg _ ->
            resultModelCmd env.selectedItems ( model, Cmd.none )

        ScrollResult _ ->
            let
                cmd =
                    Process.sleep 800 |> Task.perform (always ClearItemDetailId)
            in
            resultModelCmd env.selectedItems ( model, cmd )

        ClearItemDetailId ->
            resultModelCmd env.selectedItems ( { model | scrollToCard = Nothing }, Cmd.none )

        SelectAllItems ->
            let
                visible =
                    Data.Items.idSet model.itemListModel.results

                itemIds =
                    Data.ItemIds.apply env.selectedItems (Data.ItemIds.selectAll visible)

                res_ =
                    resultModelCmd env.selectedItems ( model, Cmd.none )
            in
            { res_ | selectedItems = itemIds }

        SelectNoItems ->
            resultModelCmd Data.ItemIds.empty ( model, Cmd.none )

        DeleteSelectedConfirmed ->
            case model.viewMode of
                SelectView svm ->
                    let
                        cmd =
                            Api.deleteAllItems env.flags (Data.ItemIds.toList env.selectedItems) DeleteAllResp
                    in
                    resultModelCmd env.selectedItems
                        ( { model
                            | viewMode =
                                SelectView
                                    { svm
                                        | confirmModal = Nothing
                                        , action = DeleteSelected
                                    }
                          }
                        , cmd
                        )

                _ ->
                    resultModelCmd env.selectedItems ( model, Cmd.none )

        RestoreSelectedConfirmed ->
            case model.viewMode of
                SelectView svm ->
                    let
                        cmd =
                            Api.restoreAllItems env.flags (Data.ItemIds.toList env.selectedItems) DeleteAllResp
                    in
                    resultModelCmd env.selectedItems
                        ( { model
                            | viewMode =
                                SelectView
                                    { svm
                                        | confirmModal = Nothing
                                        , action = RestoreSelected
                                    }
                          }
                        , cmd
                        )

                _ ->
                    resultModelCmd env.selectedItems ( model, Cmd.none )

        DeleteAllResp (Ok res) ->
            if res.success then
                let
                    nm =
                        { model | viewMode = SearchView }

                    param =
                        { flags = env.flags
                        , searchType = model.lastSearchType
                        , pageSize = env.settings.itemSearchPageSize
                        , offset = 0
                        , scroll = False
                        , selectedItems = env.selectedItems
                        }
                in
                doSearch env.selectedItems param nm

            else
                resultModelCmd env.selectedItems ( model, Cmd.none )

        DeleteAllResp (Err _) ->
            resultModelCmd env.selectedItems ( model, Cmd.none )

        RequestReprocessSelected ->
            case model.viewMode of
                SelectView svm ->
                    if Data.ItemIds.isEmpty env.selectedItems then
                        resultModelCmd env.selectedItems ( model, Cmd.none )

                    else
                        let
                            model_ =
                                { model
                                    | viewMode =
                                        SelectView
                                            { svm
                                                | action = ReprocessSelected
                                                , confirmModal = Just ConfirmReprocessItems
                                            }
                                }
                        in
                        resultModelCmd env.selectedItems ( model_, Cmd.none )

                _ ->
                    resultModelCmd env.selectedItems ( model, Cmd.none )

        CloseConfirmModal ->
            case model.viewMode of
                SelectView svm ->
                    resultModelCmd env.selectedItems
                        ( { model
                            | viewMode = SelectView { svm | confirmModal = Nothing, action = NoneAction }
                          }
                        , Cmd.none
                        )

                _ ->
                    resultModelCmd env.selectedItems ( model, Cmd.none )

        ReprocessSelectedConfirmed ->
            case model.viewMode of
                SelectView svm ->
                    if Data.ItemIds.isEmpty env.selectedItems then
                        resultModelCmd env.selectedItems ( model, Cmd.none )

                    else
                        let
                            cmd =
                                Api.reprocessMultiple env.flags (Data.ItemIds.toList env.selectedItems) DeleteAllResp
                        in
                        resultModelCmd env.selectedItems
                            ( { model
                                | viewMode =
                                    SelectView
                                        { svm
                                            | confirmModal = Nothing
                                            , action = ReprocessSelected
                                        }
                              }
                            , cmd
                            )

                _ ->
                    resultModelCmd env.selectedItems ( model, Cmd.none )

        RequestDeleteSelected ->
            case model.viewMode of
                SelectView svm ->
                    if Data.ItemIds.isEmpty env.selectedItems then
                        resultModelCmd env.selectedItems ( model, Cmd.none )

                    else
                        let
                            model_ =
                                { model
                                    | viewMode =
                                        SelectView
                                            { svm
                                                | action = DeleteSelected
                                                , confirmModal = Just ConfirmDelete
                                            }
                                }
                        in
                        resultModelCmd env.selectedItems ( model_, Cmd.none )

                _ ->
                    resultModelCmd env.selectedItems ( model, Cmd.none )

        RequestRestoreSelected ->
            case model.viewMode of
                SelectView svm ->
                    if Data.ItemIds.isEmpty env.selectedItems then
                        resultModelCmd env.selectedItems ( model, Cmd.none )

                    else
                        let
                            model_ =
                                { model
                                    | viewMode =
                                        SelectView
                                            { svm
                                                | action = RestoreSelected
                                                , confirmModal = Just ConfirmRestore
                                            }
                                }
                        in
                        resultModelCmd env.selectedItems ( model_, Cmd.none )

                _ ->
                    resultModelCmd env.selectedItems ( model, Cmd.none )

        EditSelectedItems ->
            case model.viewMode of
                SelectView svm ->
                    if svm.action == EditSelected then
                        resultModelCmd env.selectedItems
                            ( { model | viewMode = SelectView { svm | action = NoneAction } }
                            , Cmd.none
                            )

                    else if Data.ItemIds.isEmpty env.selectedItems then
                        resultModelCmd env.selectedItems ( model, Cmd.none )

                    else
                        resultModelCmd env.selectedItems
                            ( { model | viewMode = SelectView { svm | action = EditSelected } }
                            , Cmd.none
                            )

                _ ->
                    resultModelCmd env.selectedItems ( model, Cmd.none )

        MergeSelectedItems createModel ->
            case model.viewMode of
                SelectView svm ->
                    if svm.action == MergeSelected then
                        resultModelCmd env.selectedItems
                            ( { model
                                | viewMode =
                                    SelectView
                                        { svm
                                            | action = NoneAction
                                            , mergeModel = createModel <| Comp.ItemMerge.init []
                                        }
                              }
                            , Cmd.none
                            )

                    else
                        case Data.ItemIds.toQuery env.selectedItems of
                            Just q ->
                                let
                                    ( mm, mc ) =
                                        Comp.ItemMerge.initQuery env.flags model.searchMenuModel.searchMode q
                                in
                                resultModelCmd env.selectedItems
                                    ( { model
                                        | viewMode =
                                            SelectView
                                                { svm
                                                    | action = MergeSelected
                                                    , mergeModel = createModel mm
                                                }
                                      }
                                    , Cmd.map MergeItemsMsg mc
                                    )

                            Nothing ->
                                resultModelCmd env.selectedItems ( model, Cmd.none )

                _ ->
                    resultModelCmd env.selectedItems ( model, Cmd.none )

        MergeItemsMsg lmsg ->
            case model.viewMode of
                SelectView svm ->
                    let
                        ( mergeModel, createModel, action ) =
                            case svm.mergeModel of
                                MergeItems a ->
                                    ( a, MergeItems, Api.mergeItemsTask env.flags )

                                LinkItems a ->
                                    ( a, LinkItems, Api.addRelatedItemsTask env.flags )

                        result =
                            Comp.ItemMerge.update env.flags action lmsg mergeModel

                        nextView =
                            case result.outcome of
                                Comp.ItemMerge.OutcomeCancel ->
                                    SelectView { svm | action = NoneAction }

                                Comp.ItemMerge.OutcomeNotYet ->
                                    SelectView { svm | mergeModel = createModel result.model }

                                Comp.ItemMerge.OutcomeActionDone ->
                                    SearchView

                        model_ =
                            { model | viewMode = nextView }
                    in
                    if result.outcome == Comp.ItemMerge.OutcomeActionDone then
                        update texts
                            bookmarkId
                            lastViewedItemId
                            env
                            (DoSearch model.searchTypeDropdownValue)
                            model_

                    else
                        resultModelCmd env.selectedItems
                            ( model_
                            , Cmd.map MergeItemsMsg result.cmd
                            )

                _ ->
                    resultModelCmd env.selectedItems ( model, Cmd.none )

        PublishSelectedItems ->
            case model.viewMode of
                SelectView svm ->
                    if svm.action == PublishSelected then
                        let
                            ( mm, mc ) =
                                Comp.PublishItems.init env.flags
                        in
                        resultModelCmd env.selectedItems
                            ( { model
                                | viewMode =
                                    SelectView
                                        { svm
                                            | action = NoneAction
                                            , publishModel = mm
                                        }
                              }
                            , Cmd.map PublishItemsMsg mc
                            )

                    else
                        case Data.ItemIds.toQuery env.selectedItems of
                            Just q ->
                                let
                                    ( mm, mc ) =
                                        Comp.PublishItems.initQuery env.flags q
                                in
                                resultModelCmd env.selectedItems
                                    ( { model
                                        | viewMode =
                                            SelectView
                                                { svm
                                                    | action = PublishSelected
                                                    , publishModel = mm
                                                }
                                      }
                                    , Cmd.map PublishItemsMsg mc
                                    )

                            Nothing ->
                                resultModelCmd env.selectedItems ( model, Cmd.none )

                _ ->
                    resultModelCmd env.selectedItems ( model, Cmd.none )

        PublishItemsMsg lmsg ->
            case model.viewMode of
                SelectView svm ->
                    let
                        result =
                            Comp.PublishItems.update texts.publishItems env.flags lmsg svm.publishModel

                        nextView =
                            case result.outcome of
                                Comp.PublishItems.OutcomeDone ->
                                    SelectView { svm | action = NoneAction }

                                Comp.PublishItems.OutcomeInProgress ->
                                    SelectView { svm | publishModel = result.model }

                        model_ =
                            { model | viewMode = nextView }
                    in
                    if result.outcome == Comp.PublishItems.OutcomeDone then
                        update texts
                            bookmarkId
                            lastViewedItemId
                            env
                            (DoSearch model.searchTypeDropdownValue)
                            model_

                    else
                        resultModelCmd env.selectedItems
                            ( model_
                            , Cmd.map PublishItemsMsg result.cmd
                            )

                _ ->
                    resultModelCmd env.selectedItems ( model, Cmd.none )

        EditMenuMsg lmsg ->
            case model.viewMode of
                SelectView svm ->
                    let
                        res =
                            Comp.ItemDetail.MultiEditMenu.update env.flags lmsg svm.editModel

                        svm_ =
                            { svm
                                | editModel = res.model
                                , saveNameState =
                                    case res.change of
                                        NameChange _ ->
                                            Saving

                                        _ ->
                                            svm.saveNameState
                                , saveCustomFieldState =
                                    case res.change of
                                        CustomValueChange field _ ->
                                            Set.insert field.id svm.saveCustomFieldState

                                        RemoveCustomValue field ->
                                            Set.insert field.id svm.saveCustomFieldState

                                        _ ->
                                            svm.saveCustomFieldState
                            }

                        cmd_ =
                            Cmd.map EditMenuMsg res.cmd

                        sub_ =
                            Sub.map EditMenuMsg res.sub

                        upCmd =
                            Comp.ItemDetail.FormChange.multiUpdate env.flags
                                env.selectedItems
                                res.change
                                (MultiUpdateResp res.change)
                    in
                    makeResult env.selectedItems
                        ( { model | viewMode = SelectView svm_ }
                        , Cmd.batch [ cmd_, upCmd ]
                        , sub_
                        )

                _ ->
                    resultModelCmd env.selectedItems ( model, Cmd.none )

        MultiUpdateResp change (Ok res) ->
            let
                nm =
                    updateSelectViewNameState res.success model change
            in
            if res.success then
                -- replace changed items in the view
                resultModelCmd env.selectedItems ( nm, loadChangedItems env.flags model.searchMenuModel.searchMode env.selectedItems )

            else
                resultModelCmd env.selectedItems ( nm, Cmd.none )

        MultiUpdateResp change (Err _) ->
            makeResult env.selectedItems
                ( updateSelectViewNameState False model change
                , Cmd.none
                , Sub.none
                )

        ReplaceChangedItemsResp (Ok items) ->
            resultModelCmd env.selectedItems ( replaceItems model items, Cmd.none )

        ReplaceChangedItemsResp (Err _) ->
            resultModelCmd env.selectedItems ( model, Cmd.none )

        UiSettingsUpdated ->
            let
                defaultViewMode =
                    SearchView

                viewMode =
                    case model.viewMode of
                        SearchView ->
                            defaultViewMode

                        sv ->
                            sv

                model_ =
                    { model | viewMode = viewMode }
            in
            update texts bookmarkId lastViewedItemId env (DoSearch model.lastSearchType) model_

        SearchStatsResp result ->
            let
                lm =
                    SearchMenuMsg (Comp.SearchMenu.GetStatsResp result)

                stats =
                    Result.withDefault model.searchStats result
            in
            update texts bookmarkId lastViewedItemId env lm { model | searchStats = stats }

        TogglePreviewFullWidth ->
            let
                newSettings s =
                    { s | cardPreviewFullWidth = Just (not env.settings.cardPreviewFullWidth) }

                cmd =
                    Api.saveUserClientSettingsBy env.flags newSettings ClientSettingsSaveResp
            in
            resultModelCmd env.selectedItems ( { model | viewMenuOpen = False }, cmd )

        ClientSettingsSaveResp (Ok res) ->
            if res.success then
                { model = model
                , cmd = Cmd.none
                , sub = Sub.none
                , appEvent = AppReloadUiSettings
                , selectedItems = env.selectedItems
                }

            else
                resultModelCmd env.selectedItems ( model, Cmd.none )

        ClientSettingsSaveResp (Err _) ->
            resultModelCmd env.selectedItems ( model, Cmd.none )

        PowerSearchMsg lm ->
            let
                result =
                    Comp.PowerSearchInput.update lm model.powerSearchInput

                cmd_ =
                    Cmd.map PowerSearchMsg result.cmd

                model_ =
                    { model | powerSearchInput = result.model }
            in
            case result.action of
                Comp.PowerSearchInput.NoAction ->
                    makeResult env.selectedItems ( model_, cmd_, Sub.map PowerSearchMsg result.subs )

                Comp.PowerSearchInput.SubmitSearch ->
                    update texts bookmarkId lastViewedItemId env (DoSearch model_.searchTypeDropdownValue) model_

        KeyUpPowerSearchbarMsg (Just Enter) ->
            update texts bookmarkId lastViewedItemId env (DoSearch model.searchTypeDropdownValue) model

        KeyUpPowerSearchbarMsg _ ->
            resultModelCmd env.selectedItems ( model, Cmd.none )

        RemoveItem id ->
            update texts bookmarkId lastViewedItemId env (ItemCardListMsg (Comp.ItemCardList.RemoveItem id)) model

        TogglePublishCurrentQueryView ->
            case createQuery env.selectedItems model of
                Just q ->
                    let
                        ( pm, pc ) =
                            Comp.PublishItems.initQuery env.flags q
                    in
                    resultModelCmd env.selectedItems
                        ( { model | viewMode = PublishView pm, viewMenuOpen = False }
                        , Cmd.map PublishViewMsg pc
                        )

                Nothing ->
                    resultModelCmd env.selectedItems ( model, Cmd.none )

        ToggleDownloadAllView ->
            case createQuery env.selectedItems model of
                Just q ->
                    case model.topWidgetModel of
                        DownloadAll _ ->
                            resultModelCmd env.selectedItems
                                ( { model
                                    | topWidgetModel = TopWidgetHidden
                                    , viewMenuOpen = False
                                  }
                                , Cmd.none
                                )

                        _ ->
                            let
                                ( qm, qc ) =
                                    Comp.DownloadAll.init Comp.DownloadAll.AccessUser env.flags (Q.render q)
                            in
                            resultModelCmd env.selectedItems
                                ( { model | topWidgetModel = DownloadAll qm, viewMenuOpen = False }
                                , Cmd.map DownloadAllMsg qc
                                )

                Nothing ->
                    resultModelCmd env.selectedItems ( model, Cmd.none )

        ToggleBookmarkCurrentQueryView ->
            case createQuery env.selectedItems model of
                Just q ->
                    case model.topWidgetModel of
                        BookmarkQuery _ ->
                            resultModelCmd env.selectedItems
                                ( { model
                                    | topWidgetModel = TopWidgetHidden
                                    , viewMenuOpen = False
                                  }
                                , Cmd.none
                                )

                        _ ->
                            let
                                ( qm, qc ) =
                                    Comp.BookmarkQueryManage.init (Q.render q)
                            in
                            resultModelCmd env.selectedItems
                                ( { model | topWidgetModel = BookmarkQuery qm, viewMenuOpen = False }
                                , Cmd.map BookmarkQueryMsg qc
                                )

                Nothing ->
                    resultModelCmd env.selectedItems ( model, Cmd.none )

        BookmarkQueryMsg lm ->
            case model.topWidgetModel of
                BookmarkQuery bm ->
                    let
                        res =
                            Comp.BookmarkQueryManage.update env.flags lm bm

                        nextModel =
                            if
                                res.outcome
                                    == Comp.BookmarkQueryManage.Cancelled
                                    || res.outcome
                                    == Comp.BookmarkQueryManage.Done
                            then
                                TopWidgetHidden

                            else
                                BookmarkQuery res.model

                        refreshCmd =
                            if res.outcome == Comp.BookmarkQueryManage.Done then
                                Cmd.map SearchMenuMsg (Comp.SearchMenu.refreshBookmarks env.flags)

                            else
                                Cmd.none
                    in
                    makeResult env.selectedItems
                        ( { model | topWidgetModel = nextModel }
                        , Cmd.batch
                            [ Cmd.map BookmarkQueryMsg res.cmd
                            , refreshCmd
                            ]
                        , Sub.map BookmarkQueryMsg res.sub
                        )

                _ ->
                    resultModelCmd env.selectedItems ( model, Cmd.none )

        DownloadAllMsg lm ->
            case model.topWidgetModel of
                DownloadAll bm ->
                    let
                        res =
                            Comp.DownloadAll.update env.flags lm bm

                        nextModel =
                            if res.closed then
                                TopWidgetHidden

                            else
                                DownloadAll res.model
                    in
                    makeResult env.selectedItems
                        ( { model | topWidgetModel = nextModel }
                        , Cmd.map DownloadAllMsg res.cmd
                        , Sub.none
                        )

                _ ->
                    resultModelCmd env.selectedItems ( model, Cmd.none )

        PublishViewMsg lmsg ->
            case model.viewMode of
                PublishView inPM ->
                    let
                        result =
                            Comp.PublishItems.update texts.publishItems env.flags lmsg inPM
                    in
                    case result.outcome of
                        Comp.PublishItems.OutcomeInProgress ->
                            resultModelCmd env.selectedItems
                                ( { model | viewMode = PublishView result.model }
                                , Cmd.map PublishViewMsg result.cmd
                                )

                        Comp.PublishItems.OutcomeDone ->
                            resultModelCmd env.selectedItems
                                ( { model | viewMode = SearchView }
                                , Cmd.map SearchMenuMsg (Comp.SearchMenu.refreshBookmarks env.flags)
                                )

                _ ->
                    resultModelCmd env.selectedItems ( model, Cmd.none )

        ToggleViewMenu ->
            resultModelCmd env.selectedItems ( { model | viewMenuOpen = not model.viewMenuOpen }, Cmd.none )

        ToggleShowGroups ->
            let
                newSettings s =
                    { s | itemSearchShowGroups = Just (not env.settings.itemSearchShowGroups) }

                cmd =
                    Api.saveUserClientSettingsBy env.flags newSettings ClientSettingsSaveResp
            in
            resultModelCmd env.selectedItems ( { model | viewMenuOpen = False }, cmd )

        ToggleArrange am ->
            let
                newSettings s =
                    { s | itemSearchArrange = Data.ItemArrange.asString am |> Just }

                cmd =
                    Api.saveUserClientSettingsBy env.flags newSettings ClientSettingsSaveResp
            in
            resultModelCmd env.selectedItems ( { model | viewMenuOpen = False }, cmd )

        ItemSelectionChanged ->
            if Data.ItemIds.isEmpty env.selectedItems then
                update texts
                    bookmarkId
                    lastViewedItemId
                    env
                    (SearchMenuMsg <| Comp.SearchMenu.setIncludeSelection False)
                    model

            else
                resultModelCmd env.selectedItems ( model, Cmd.none )



--- Helpers


updateSelectViewNameState : Bool -> Model -> FormChange -> Model
updateSelectViewNameState success model change =
    let
        removeCustomField field svm =
            { model
                | viewMode =
                    SelectView
                        { svm
                            | saveCustomFieldState = Set.remove field.id svm.saveCustomFieldState
                        }
            }
    in
    case model.viewMode of
        SelectView svm ->
            case change of
                NameChange _ ->
                    let
                        svm_ =
                            { svm
                                | saveNameState =
                                    if success then
                                        SaveSuccess

                                    else
                                        SaveFailed
                            }
                    in
                    { model | viewMode = SelectView svm_ }

                RemoveCustomValue field ->
                    removeCustomField field svm

                CustomValueChange field _ ->
                    removeCustomField field svm

                _ ->
                    model

        _ ->
            model


replaceItems : Model -> ItemLightList -> Model
replaceItems model newItems =
    let
        listModel =
            model.itemListModel

        changed =
            Data.Items.replaceIn listModel.results newItems

        newList =
            { listModel | results = changed }
    in
    { model | itemListModel = newList }


loadChangedItems : Flags -> SearchMode -> ItemIds -> Cmd Msg
loadChangedItems flags smode ids =
    if Data.ItemIds.isEmpty ids then
        Cmd.none

    else
        let
            idList =
                Data.ItemIds.toList ids

            searchInit =
                Q.request smode (Just <| Q.ItemIdIn idList)

            search =
                { searchInit
                    | limit = Just <| Data.ItemIds.size ids
                }
        in
        Api.itemSearch flags search ReplaceChangedItemsResp


scrollToCard : ItemIds -> Maybe String -> Model -> UpdateResult
scrollToCard selection lastViewedItemId model =
    let
        scroll id =
            Scroll.scrollElementY "item-card-list" id 0.5 0.5
    in
    makeResult selection <|
        case lastViewedItemId of
            Just id ->
                ( { model | scrollToCard = lastViewedItemId }
                , Task.attempt ScrollResult (scroll id)
                , Sub.none
                )

            Nothing ->
                ( model, Cmd.none, Sub.none )


loadEditModel : Flags -> Cmd Msg
loadEditModel flags =
    Cmd.map EditMenuMsg (Comp.ItemDetail.MultiEditMenu.loadModel flags)


doSearch : ItemIds -> SearchParam -> Model -> UpdateResult
doSearch selection param model =
    let
        param_ =
            { param | offset = 0 }

        searchCmd =
            doSearchCmd param_ model
    in
    resultModelCmd selection
        ( { model
            | searchInProgress = True
            , searchOffset = 0
            , lastSearchType = param.searchType
          }
        , searchCmd
        )


linkTargetMsg : LinkTarget -> Maybe Msg
linkTargetMsg linkTarget =
    Maybe.map SearchMenuMsg (Comp.SearchMenu.linkTargetMsg linkTarget)


doSearchMore : Env.Update -> Model -> ( Model, Cmd Msg )
doSearchMore env model =
    let
        param =
            { flags = env.flags
            , searchType = model.lastSearchType
            , pageSize = env.settings.itemSearchPageSize
            , offset = model.searchOffset
            , scroll = False
            , selectedItems = env.selectedItems
            }

        cmd =
            doSearchCmd param model
    in
    ( { model | moreInProgress = True }
    , cmd
    )


resultModelCmd : ItemIds -> ( Model, Cmd Msg ) -> UpdateResult
resultModelCmd selection ( m, c ) =
    makeResult selection ( m, c, Sub.none )


makeResult : ItemIds -> ( Model, Cmd Msg, Sub Msg ) -> UpdateResult
makeResult selection ( m, c, s ) =
    { model = m
    , cmd = c
    , sub = s
    , appEvent = AppNothing
    , selectedItems = selection
    }
