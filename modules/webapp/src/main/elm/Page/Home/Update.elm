{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Page.Home.Update exposing
    ( UpdateResult
    , update
    )

import Api
import Api.Model.ItemLightList exposing (ItemLightList)
import Browser.Navigation as Nav
import Comp.ItemCardList
import Comp.ItemDetail.FormChange exposing (FormChange(..))
import Comp.ItemDetail.MultiEditMenu exposing (SaveNameState(..))
import Comp.ItemMerge
import Comp.LinkTarget exposing (LinkTarget)
import Comp.PowerSearchInput
import Comp.SearchMenu
import Data.Flags exposing (Flags)
import Data.ItemQuery as Q
import Data.ItemSelection
import Data.Items
import Data.SearchMode exposing (SearchMode)
import Data.UiSettings exposing (UiSettings)
import Page exposing (Page(..))
import Page.Home.Data exposing (..)
import Process
import Scroll
import Set exposing (Set)
import Task
import Throttle
import Time
import Util.Html exposing (KeyCode(..))
import Util.ItemDragDrop as DD
import Util.Update


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    , newSettings : Maybe UiSettings
    }


update : Maybe String -> Nav.Key -> Flags -> UiSettings -> Msg -> Model -> UpdateResult
update mId key flags settings msg model =
    case msg of
        Init ->
            let
                searchParam =
                    { flags = flags
                    , searchType = model.lastSearchType
                    , pageSize = settings.itemSearchPageSize
                    , offset = 0
                    , scroll = True
                    }
            in
            makeResult <|
                Util.Update.andThen3
                    [ update mId key flags settings (SearchMenuMsg Comp.SearchMenu.Init)
                    , doSearch searchParam
                    ]
                    model

        ResetSearch ->
            let
                nm =
                    { model | searchOffset = 0, powerSearchInput = Comp.PowerSearchInput.init }
            in
            update mId key flags settings (SearchMenuMsg Comp.SearchMenu.ResetForm) nm

        SearchMenuMsg m ->
            let
                nextState =
                    Comp.SearchMenu.updateDrop
                        model.dragDropData.model
                        flags
                        settings
                        m
                        model.searchMenuModel

                dropCmd =
                    DD.makeUpdateCmd flags (\_ -> DoSearch model.lastSearchType) nextState.dragDrop.dropped

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

                result =
                    if nextState.stateChange && not model.searchInProgress then
                        doSearch (SearchParam flags BasicSearch settings.itemSearchPageSize 0 False) newModel

                    else
                        withSub ( newModel, Cmd.none )
            in
            { result
                | cmd =
                    Cmd.batch
                        [ result.cmd
                        , Cmd.map SearchMenuMsg nextState.cmd
                        , dropCmd
                        ]
            }

        SetLinkTarget lt ->
            case linkTargetMsg lt of
                Just m ->
                    update mId key flags settings m model

                Nothing ->
                    makeResult ( model, Cmd.none, Sub.none )

        ItemCardListMsg m ->
            let
                result =
                    Comp.ItemCardList.updateDrag model.dragDropData.model
                        flags
                        m
                        model.itemListModel

                searchMsg =
                    Maybe.map Util.Update.cmdUnit (linkTargetMsg result.linkTarget)
                        |> Maybe.withDefault Cmd.none

                nextView =
                    case ( model.viewMode, result.selection ) of
                        ( SelectView svm, Data.ItemSelection.Active ids ) ->
                            SelectView { svm | ids = ids }

                        ( v, _ ) ->
                            v
            in
            withSub
                ( { model
                    | itemListModel = result.model
                    , viewMode = nextView
                    , dragDropData = DD.DragDropData result.dragModel Nothing
                  }
                , Cmd.batch [ Cmd.map ItemCardListMsg result.cmd, searchMsg ]
                )

        ItemSearchResp scroll (Ok list) ->
            let
                noff =
                    settings.itemSearchPageSize

                m =
                    { model
                        | searchInProgress = False
                        , searchOffset = noff
                        , moreAvailable = list.groups /= []
                    }
            in
            makeResult <|
                Util.Update.andThen3
                    [ update mId key flags settings (ItemCardListMsg (Comp.ItemCardList.SetResults list))
                    , if scroll then
                        scrollToCard mId

                      else
                        \next -> makeResult ( next, Cmd.none, Sub.none )
                    ]
                    m

        ItemSearchAddResp (Ok list) ->
            let
                noff =
                    model.searchOffset + settings.itemSearchPageSize

                m =
                    { model
                        | searchInProgress = False
                        , moreInProgress = False
                        , searchOffset = noff
                        , moreAvailable = list.groups /= []
                    }
            in
            update mId key flags settings (ItemCardListMsg (Comp.ItemCardList.AddResults list)) m

        ItemSearchAddResp (Err _) ->
            withSub
                ( { model
                    | moreInProgress = False
                  }
                , Cmd.none
                )

        ItemSearchResp _ (Err _) ->
            withSub
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
                    { flags = flags
                    , searchType = stype
                    , pageSize = settings.itemSearchPageSize
                    , offset = 0
                    , scroll = False
                    }
            in
            if model.searchInProgress then
                withSub ( model, Cmd.none )

            else
                doSearch param nm

        ToggleSearchMenu ->
            let
                nextView =
                    case model.viewMode of
                        SimpleView ->
                            SearchView

                        SearchView ->
                            SimpleView

                        SelectView _ ->
                            SimpleView
            in
            withSub
                ( { model | viewMode = nextView }
                , Cmd.none
                )

        ToggleSelectView ->
            let
                ( nextView, cmd ) =
                    case model.viewMode of
                        SimpleView ->
                            ( SelectView initSelectViewModel, loadEditModel flags )

                        SearchView ->
                            ( SelectView initSelectViewModel, loadEditModel flags )

                        SelectView _ ->
                            ( SearchView, Cmd.none )
            in
            withSub
                ( { model
                    | viewMode = nextView
                  }
                , cmd
                )

        LoadMore ->
            if model.moreAvailable then
                doSearchMore flags settings model |> withSub

            else
                withSub ( model, Cmd.none )

        UpdateThrottle ->
            let
                ( newThrottle, cmd ) =
                    Throttle.update model.throttle
            in
            withSub ( { model | throttle = newThrottle }, cmd )

        SetBasicSearch str ->
            let
                smMsg =
                    SearchMenuMsg (Comp.SearchMenu.SetTextSearch str)
            in
            update mId key flags settings smMsg model

        ToggleSearchType ->
            case model.searchTypeDropdownValue of
                BasicSearch ->
                    update mId key flags settings (SearchMenuMsg Comp.SearchMenu.SetFulltextSearch) model

                ContentOnlySearch ->
                    update mId key flags settings (SearchMenuMsg Comp.SearchMenu.SetNamesSearch) model

        KeyUpSearchbarMsg (Just Enter) ->
            update mId key flags settings (DoSearch model.searchTypeDropdownValue) model

        KeyUpSearchbarMsg _ ->
            withSub ( model, Cmd.none )

        ScrollResult _ ->
            let
                cmd =
                    Process.sleep 800 |> Task.perform (always ClearItemDetailId)
            in
            withSub ( model, cmd )

        ClearItemDetailId ->
            noSub ( { model | scrollToCard = Nothing }, Cmd.none )

        SelectAllItems ->
            case model.viewMode of
                SelectView svm ->
                    let
                        visible =
                            Data.Items.idSet model.itemListModel.results

                        svm_ =
                            { svm | ids = Set.union svm.ids visible }
                    in
                    noSub
                        ( { model | viewMode = SelectView svm_ }
                        , Cmd.none
                        )

                _ ->
                    noSub ( model, Cmd.none )

        SelectNoItems ->
            case model.viewMode of
                SelectView svm ->
                    let
                        svm_ =
                            { svm | ids = Set.empty }
                    in
                    noSub
                        ( { model | viewMode = SelectView svm_ }
                        , Cmd.none
                        )

                _ ->
                    noSub ( model, Cmd.none )

        DeleteSelectedConfirmed ->
            case model.viewMode of
                SelectView svm ->
                    let
                        cmd =
                            Api.deleteAllItems flags svm.ids DeleteAllResp
                    in
                    noSub
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
                    noSub ( model, Cmd.none )

        RestoreSelectedConfirmed ->
            case model.viewMode of
                SelectView svm ->
                    let
                        cmd =
                            Api.restoreAllItems flags svm.ids DeleteAllResp
                    in
                    noSub
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
                    noSub ( model, Cmd.none )

        DeleteAllResp (Ok res) ->
            if res.success then
                let
                    nm =
                        { model | viewMode = SearchView }

                    param =
                        { flags = flags
                        , searchType = model.lastSearchType
                        , pageSize = settings.itemSearchPageSize
                        , offset = 0
                        , scroll = False
                        }
                in
                doSearch param nm

            else
                noSub ( model, Cmd.none )

        DeleteAllResp (Err _) ->
            noSub ( model, Cmd.none )

        RequestReprocessSelected ->
            case model.viewMode of
                SelectView svm ->
                    if svm.ids == Set.empty then
                        noSub ( model, Cmd.none )

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
                        noSub ( model_, Cmd.none )

                _ ->
                    noSub ( model, Cmd.none )

        CloseConfirmModal ->
            case model.viewMode of
                SelectView svm ->
                    noSub
                        ( { model
                            | viewMode = SelectView { svm | confirmModal = Nothing, action = NoneAction }
                          }
                        , Cmd.none
                        )

                _ ->
                    noSub ( model, Cmd.none )

        ReprocessSelectedConfirmed ->
            case model.viewMode of
                SelectView svm ->
                    if svm.ids == Set.empty then
                        noSub ( model, Cmd.none )

                    else
                        let
                            cmd =
                                Api.reprocessMultiple flags svm.ids DeleteAllResp
                        in
                        noSub
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
                    noSub ( model, Cmd.none )

        RequestDeleteSelected ->
            case model.viewMode of
                SelectView svm ->
                    if svm.ids == Set.empty then
                        noSub ( model, Cmd.none )

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
                        noSub ( model_, Cmd.none )

                _ ->
                    noSub ( model, Cmd.none )

        RequestRestoreSelected ->
            case model.viewMode of
                SelectView svm ->
                    if svm.ids == Set.empty then
                        noSub ( model, Cmd.none )

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
                        noSub ( model_, Cmd.none )

                _ ->
                    noSub ( model, Cmd.none )

        EditSelectedItems ->
            case model.viewMode of
                SelectView svm ->
                    if svm.action == EditSelected then
                        noSub
                            ( { model | viewMode = SelectView { svm | action = NoneAction } }
                            , Cmd.none
                            )

                    else if svm.ids == Set.empty then
                        noSub ( model, Cmd.none )

                    else
                        noSub
                            ( { model | viewMode = SelectView { svm | action = EditSelected } }
                            , Cmd.none
                            )

                _ ->
                    noSub ( model, Cmd.none )

        MergeSelectedItems ->
            case model.viewMode of
                SelectView svm ->
                    if svm.action == MergeSelected then
                        noSub
                            ( { model
                                | viewMode =
                                    SelectView
                                        { svm
                                            | action = NoneAction
                                            , mergeModel = Comp.ItemMerge.init []
                                        }
                              }
                            , Cmd.none
                            )

                    else if svm.ids == Set.empty then
                        noSub ( model, Cmd.none )

                    else
                        let
                            ( mm, mc ) =
                                Comp.ItemMerge.initQuery
                                    flags
                                    model.searchMenuModel.searchMode
                                    (Q.ItemIdIn (Set.toList svm.ids))
                        in
                        noSub
                            ( { model
                                | viewMode =
                                    SelectView
                                        { svm
                                            | action = MergeSelected
                                            , mergeModel = mm
                                        }
                              }
                            , Cmd.map MergeItemsMsg mc
                            )

                _ ->
                    noSub ( model, Cmd.none )

        MergeItemsMsg lmsg ->
            case model.viewMode of
                SelectView svm ->
                    let
                        result =
                            Comp.ItemMerge.update flags lmsg svm.mergeModel

                        nextView =
                            if result.done then
                                SelectView { svm | action = NoneAction }

                            else
                                SelectView { svm | mergeModel = result.model }
                    in
                    noSub
                        ( { model | viewMode = nextView }
                        , Cmd.map MergeItemsMsg result.cmd
                        )

                _ ->
                    noSub ( model, Cmd.none )

        EditMenuMsg lmsg ->
            case model.viewMode of
                SelectView svm ->
                    let
                        res =
                            Comp.ItemDetail.MultiEditMenu.update flags lmsg svm.editModel

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
                            Comp.ItemDetail.FormChange.multiUpdate flags
                                svm.ids
                                res.change
                                (MultiUpdateResp res.change)
                    in
                    makeResult
                        ( { model | viewMode = SelectView svm_ }
                        , Cmd.batch [ cmd_, upCmd ]
                        , sub_
                        )

                _ ->
                    noSub ( model, Cmd.none )

        MultiUpdateResp change (Ok res) ->
            let
                nm =
                    updateSelectViewNameState res.success model change
            in
            if res.success then
                case model.viewMode of
                    SelectView svm ->
                        -- replace changed items in the view
                        noSub ( nm, loadChangedItems flags model.searchMenuModel.searchMode svm.ids )

                    _ ->
                        noSub ( nm, Cmd.none )

            else
                noSub ( nm, Cmd.none )

        MultiUpdateResp change (Err _) ->
            makeResult
                ( updateSelectViewNameState False model change
                , Cmd.none
                , Sub.none
                )

        ReplaceChangedItemsResp (Ok items) ->
            noSub ( replaceItems model items, Cmd.none )

        ReplaceChangedItemsResp (Err _) ->
            noSub ( model, Cmd.none )

        UiSettingsUpdated ->
            let
                defaultViewMode =
                    if settings.searchMenuVisible then
                        SearchView

                    else
                        SimpleView

                viewMode =
                    case model.viewMode of
                        SimpleView ->
                            defaultViewMode

                        SearchView ->
                            defaultViewMode

                        sv ->
                            sv

                model_ =
                    { model | viewMode = viewMode }
            in
            update mId key flags settings (DoSearch model.lastSearchType) model_

        SearchStatsResp result ->
            let
                lm =
                    SearchMenuMsg (Comp.SearchMenu.GetStatsResp result)

                stats =
                    Result.withDefault model.searchStats result
            in
            update mId key flags settings lm { model | searchStats = stats }

        TogglePreviewFullWidth ->
            let
                newSettings =
                    { settings | cardPreviewFullWidth = not settings.cardPreviewFullWidth }

                cmd =
                    Api.saveClientSettings flags newSettings (ClientSettingsSaveResp newSettings)
            in
            noSub ( model, cmd )

        ClientSettingsSaveResp newSettings (Ok res) ->
            if res.success then
                { model = model
                , cmd = Cmd.none
                , sub = Sub.none
                , newSettings = Just newSettings
                }

            else
                noSub ( model, Cmd.none )

        ClientSettingsSaveResp _ (Err _) ->
            noSub ( model, Cmd.none )

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
                    makeResult ( model_, cmd_, Sub.map PowerSearchMsg result.subs )

                Comp.PowerSearchInput.SubmitSearch ->
                    update mId key flags settings (DoSearch model_.searchTypeDropdownValue) model_

        KeyUpPowerSearchbarMsg (Just Enter) ->
            update mId key flags settings (DoSearch model.searchTypeDropdownValue) model

        KeyUpPowerSearchbarMsg _ ->
            withSub ( model, Cmd.none )

        RemoveItem id ->
            update mId key flags settings (ItemCardListMsg (Comp.ItemCardList.RemoveItem id)) model



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


loadChangedItems : Flags -> SearchMode -> Set String -> Cmd Msg
loadChangedItems flags smode ids =
    if Set.isEmpty ids then
        Cmd.none

    else
        let
            idList =
                Set.toList ids

            searchInit =
                Q.request smode (Just <| Q.ItemIdIn idList)

            search =
                { searchInit
                    | limit = Just <| Set.size ids
                }
        in
        Api.itemSearch flags search ReplaceChangedItemsResp


scrollToCard : Maybe String -> Model -> UpdateResult
scrollToCard mId model =
    let
        scroll id =
            Scroll.scrollElementY "item-card-list" id 0.5 0.5
    in
    makeResult <|
        case mId of
            Just id ->
                ( { model | scrollToCard = mId }
                , Task.attempt ScrollResult (scroll id)
                , Sub.none
                )

            Nothing ->
                ( model, Cmd.none, Sub.none )


loadEditModel : Flags -> Cmd Msg
loadEditModel flags =
    Cmd.map EditMenuMsg (Comp.ItemDetail.MultiEditMenu.loadModel flags)


doSearch : SearchParam -> Model -> UpdateResult
doSearch param model =
    let
        param_ =
            { param | offset = 0 }

        searchCmd =
            doSearchCmd param_ model

        ( newThrottle, cmd ) =
            Throttle.try searchCmd model.throttle
    in
    withSub
        ( { model
            | searchInProgress = cmd /= Cmd.none
            , searchOffset = 0
            , throttle = newThrottle
            , lastSearchType = param.searchType
          }
        , cmd
        )


linkTargetMsg : LinkTarget -> Maybe Msg
linkTargetMsg linkTarget =
    case linkTarget of
        Comp.LinkTarget.LinkNone ->
            Nothing

        Comp.LinkTarget.LinkCorrOrg id ->
            Just <| SearchMenuMsg (Comp.SearchMenu.SetCorrOrg id)

        Comp.LinkTarget.LinkCorrPerson id ->
            Just <| SearchMenuMsg (Comp.SearchMenu.SetCorrPerson id)

        Comp.LinkTarget.LinkConcPerson id ->
            Just <| SearchMenuMsg (Comp.SearchMenu.SetConcPerson id)

        Comp.LinkTarget.LinkConcEquip id ->
            Just <| SearchMenuMsg (Comp.SearchMenu.SetConcEquip id)

        Comp.LinkTarget.LinkFolder id ->
            Just <| SearchMenuMsg (Comp.SearchMenu.SetFolder id)

        Comp.LinkTarget.LinkTag id ->
            Just <| SearchMenuMsg (Comp.SearchMenu.SetTag id.id)

        Comp.LinkTarget.LinkCustomField id ->
            Just <| SearchMenuMsg (Comp.SearchMenu.SetCustomField id)

        Comp.LinkTarget.LinkSource str ->
            Just <| SearchMenuMsg (Comp.SearchMenu.ResetToSource str)


doSearchMore : Flags -> UiSettings -> Model -> ( Model, Cmd Msg )
doSearchMore flags settings model =
    let
        param =
            { flags = flags
            , searchType = model.lastSearchType
            , pageSize = settings.itemSearchPageSize
            , offset = model.searchOffset
            , scroll = False
            }

        cmd =
            doSearchCmd param model
    in
    ( { model | moreInProgress = True }
    , cmd
    )


withSub : ( Model, Cmd Msg ) -> UpdateResult
withSub ( m, c ) =
    makeResult
        ( m
        , c
        , Throttle.ifNeeded
            (Time.every 500 (\_ -> UpdateThrottle))
            m.throttle
        )


noSub : ( Model, Cmd Msg ) -> UpdateResult
noSub ( m, c ) =
    makeResult ( m, c, Sub.none )


makeResult : ( Model, Cmd Msg, Sub Msg ) -> UpdateResult
makeResult ( m, c, s ) =
    { model = m
    , cmd = c
    , sub = s
    , newSettings = Nothing
    }
