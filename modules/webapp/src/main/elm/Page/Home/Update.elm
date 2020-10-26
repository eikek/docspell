module Page.Home.Update exposing (update)

import Api
import Api.Model.IdList exposing (IdList)
import Api.Model.ItemLightList exposing (ItemLightList)
import Api.Model.ItemSearch exposing (ItemSearch)
import Browser.Navigation as Nav
import Comp.FixedDropdown
import Comp.ItemCardList
import Comp.ItemDetail.EditMenu
import Comp.ItemDetail.FormChange
import Comp.SearchMenu
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Data.ItemSelection
import Data.Items
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
import Util.Maybe
import Util.String
import Util.Update


update : Maybe String -> Nav.Key -> Flags -> UiSettings -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update mId key flags settings msg model =
    case msg of
        Init ->
            Util.Update.andThen2
                [ update mId key flags settings (SearchMenuMsg Comp.SearchMenu.Init)
                , doSearch flags settings True
                ]
                model

        ResetSearch ->
            let
                nm =
                    { model
                        | searchOffset = 0
                        , searchType = defaultSearchType flags
                    }
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
                    DD.makeUpdateCmd flags (\_ -> DoSearch) nextState.dragDrop.dropped

                newModel =
                    { model
                        | searchMenuModel = nextState.model
                        , dragDropData = nextState.dragDrop
                    }

                ( m2, c2, s2 ) =
                    if nextState.stateChange && not model.searchInProgress then
                        doSearch flags settings False newModel

                    else
                        withSub ( newModel, Cmd.none )
            in
            ( m2
            , Cmd.batch
                [ c2
                , Cmd.map SearchMenuMsg nextState.cmd
                , dropCmd
                ]
            , s2
            )

        ItemCardListMsg m ->
            let
                result =
                    Comp.ItemCardList.updateDrag model.dragDropData.model
                        flags
                        m
                        model.itemListModel

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
                , Cmd.batch [ Cmd.map ItemCardListMsg result.cmd ]
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
            Util.Update.andThen2
                [ update mId key flags settings (ItemCardListMsg (Comp.ItemCardList.SetResults list))
                , if scroll then
                    scrollToCard mId

                  else
                    \next -> ( next, Cmd.none, Sub.none )
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
            Util.Update.andThen2
                [ update mId key flags settings (ItemCardListMsg (Comp.ItemCardList.AddResults list))
                ]
                m

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

        DoSearch ->
            let
                nm =
                    { model | searchOffset = 0 }
            in
            if model.searchInProgress then
                withSub ( model, Cmd.none )

            else
                doSearch flags settings False nm

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
                    case model.searchTypeForm of
                        BasicSearch ->
                            SearchMenuMsg (Comp.SearchMenu.SetAllName str)

                        ContentSearch ->
                            SearchMenuMsg (Comp.SearchMenu.SetFulltext str)

                        ContentOnlySearch ->
                            SetContentOnly str
            in
            update mId key flags settings smMsg model

        SetContentOnly str ->
            withSub
                ( { model | contentOnlySearch = Util.Maybe.fromString str }
                , Cmd.none
                )

        SearchTypeMsg lm ->
            let
                ( sm, mv ) =
                    Comp.FixedDropdown.update lm model.searchTypeDropdown

                mvChange =
                    Util.Maybe.filter (\a -> a /= model.searchTypeForm) mv

                m0 =
                    { model
                        | searchTypeDropdown = sm
                        , searchTypeForm = Maybe.withDefault model.searchTypeForm mv
                    }

                next =
                    case mvChange of
                        Just BasicSearch ->
                            Just
                                ( { m0 | contentOnlySearch = Nothing }
                                , Maybe.withDefault "" model.contentOnlySearch
                                )

                        Just ContentOnlySearch ->
                            Just
                                ( { m0 | contentOnlySearch = model.searchMenuModel.allNameModel }
                                , ""
                                )

                        _ ->
                            Nothing
            in
            case next of
                Just ( m_, nstr ) ->
                    update mId key flags settings (SearchMenuMsg (Comp.SearchMenu.SetAllName nstr)) m_

                Nothing ->
                    withSub ( m0, Cmd.none )

        KeyUpMsg (Just Enter) ->
            update mId key flags settings DoSearch model

        KeyUpMsg _ ->
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

        DeleteSelectedConfirmMsg lmsg ->
            case model.viewMode of
                SelectView svm ->
                    let
                        ( confirmModel, confirmed ) =
                            Comp.YesNoDimmer.update lmsg svm.deleteAllConfirm

                        cmd =
                            if confirmed then
                                Api.deleteAllItems flags svm.ids DeleteAllResp

                            else
                                Cmd.none

                        act =
                            if confirmModel.active || confirmed then
                                DeleteSelected

                            else
                                NoneAction
                    in
                    noSub
                        ( { model
                            | viewMode =
                                SelectView
                                    { svm
                                        | deleteAllConfirm = confirmModel
                                        , action = act
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
                in
                doSearch flags settings False nm

            else
                noSub ( model, Cmd.none )

        DeleteAllResp (Err _) ->
            noSub ( model, Cmd.none )

        RequestDeleteSelected ->
            case model.viewMode of
                SelectView svm ->
                    if svm.ids == Set.empty then
                        noSub ( model, Cmd.none )

                    else
                        let
                            lmsg =
                                DeleteSelectedConfirmMsg Comp.YesNoDimmer.activate

                            model_ =
                                { model | viewMode = SelectView { svm | action = DeleteSelected } }
                        in
                        update mId key flags settings lmsg model_

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

        EditMenuMsg lmsg ->
            case model.viewMode of
                SelectView svm ->
                    let
                        res =
                            Comp.ItemDetail.EditMenu.update flags lmsg svm.editModel

                        svm_ =
                            { svm | editModel = res.model }

                        cmd_ =
                            Cmd.map EditMenuMsg res.cmd

                        sub_ =
                            Sub.map EditMenuMsg res.sub

                        upCmd =
                            Comp.ItemDetail.FormChange.multiUpdate flags
                                svm.ids
                                res.change
                                MultiUpdateResp
                    in
                    ( { model | viewMode = SelectView svm_ }
                    , Cmd.batch [ cmd_, upCmd ]
                    , sub_
                    )

                _ ->
                    noSub ( model, Cmd.none )

        MultiUpdateResp (Ok res) ->
            if res.success then
                case model.viewMode of
                    SelectView svm ->
                        -- replace changed items in the view
                        noSub ( model, loadChangedItems flags svm.ids )

                    _ ->
                        noSub ( model, Cmd.none )

            else
                noSub ( model, Cmd.none )

        MultiUpdateResp (Err _) ->
            noSub ( model, Cmd.none )

        ReplaceChangedItemsResp (Ok items) ->
            noSub ( replaceItems model items, Cmd.none )

        ReplaceChangedItemsResp (Err _) ->
            noSub ( model, Cmd.none )



--- Helpers


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


loadChangedItems : Flags -> Set String -> Cmd Msg
loadChangedItems flags ids =
    if Set.isEmpty ids then
        Cmd.none

    else
        let
            searchInit =
                Api.Model.ItemSearch.empty

            idList =
                IdList (Set.toList ids)

            search =
                { searchInit
                    | itemSubset = Just idList
                    , limit = Set.size ids
                }
        in
        Api.itemSearch flags search ReplaceChangedItemsResp


scrollToCard : Maybe String -> Model -> ( Model, Cmd Msg, Sub Msg )
scrollToCard mId model =
    let
        scroll id =
            Scroll.scroll id 0.5 0.5 0.5 0.5
    in
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
    Cmd.map EditMenuMsg (Comp.ItemDetail.EditMenu.loadModel flags)


doSearch : Flags -> UiSettings -> Bool -> Model -> ( Model, Cmd Msg, Sub Msg )
doSearch flags settings scroll model =
    let
        stype =
            if
                not (menuCollapsed model)
                    || Util.String.isNothingOrBlank model.contentOnlySearch
            then
                BasicSearch

            else
                model.searchTypeForm

        model_ =
            { model | searchType = stype }

        searchCmd =
            doSearchCmd flags settings 0 scroll model_

        ( newThrottle, cmd ) =
            Throttle.try searchCmd model.throttle
    in
    withSub
        ( { model_
            | searchInProgress = cmd /= Cmd.none
            , searchOffset = 0
            , throttle = newThrottle
          }
        , cmd
        )


doSearchMore : Flags -> UiSettings -> Model -> ( Model, Cmd Msg )
doSearchMore flags settings model =
    let
        cmd =
            doSearchCmd flags settings model.searchOffset False model
    in
    ( { model | moreInProgress = True }
    , cmd
    )


withSub : ( Model, Cmd Msg ) -> ( Model, Cmd Msg, Sub Msg )
withSub ( m, c ) =
    ( m
    , c
    , Throttle.ifNeeded
        (Time.every 500 (\_ -> UpdateThrottle))
        m.throttle
    )


noSub : ( Model, Cmd Msg ) -> ( Model, Cmd Msg, Sub Msg )
noSub ( m, c ) =
    ( m, c, Sub.none )
