module Page.Home.Update exposing (update)

import Browser.Navigation as Nav
import Comp.FixedDropdown
import Comp.ItemCardList
import Comp.SearchMenu
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Page exposing (Page(..))
import Page.Home.Data exposing (..)
import Throttle
import Time
import Util.Html exposing (KeyCode(..))
import Util.ItemDragDrop as DD
import Util.Maybe
import Util.String
import Util.Update


update : Nav.Key -> Flags -> UiSettings -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update key flags settings msg model =
    case msg of
        Init ->
            Util.Update.andThen2
                [ update key flags settings (SearchMenuMsg Comp.SearchMenu.Init)
                , doSearch flags settings
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
            update key flags settings (SearchMenuMsg Comp.SearchMenu.ResetForm) nm

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
                    case nextState.dragDrop.dropped of
                        Just dropped ->
                            let
                                _ =
                                    Debug.log "item/folder" dropped
                            in
                            DD.makeUpdateCmd flags (\_ -> DoSearch) nextState.dragDrop.dropped

                        Nothing ->
                            Cmd.none

                newModel =
                    { model
                        | searchMenuModel = nextState.model
                        , dragDropData = nextState.dragDrop
                    }

                ( m2, c2, s2 ) =
                    if nextState.stateChange && not model.searchInProgress then
                        doSearch flags settings newModel

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

                cmd =
                    case result.selected of
                        Just item ->
                            Page.set key (ItemDetailPage item.id)

                        Nothing ->
                            Cmd.none
            in
            withSub
                ( { model
                    | itemListModel = result.model
                    , dragDropData = DD.DragDropData result.dragModel Nothing
                  }
                , Cmd.batch [ Cmd.map ItemCardListMsg result.cmd, cmd ]
                )

        ItemSearchResp (Ok list) ->
            let
                noff =
                    settings.itemSearchPageSize

                m =
                    { model
                        | searchInProgress = False
                        , searchOffset = noff
                        , viewMode = Listing
                        , moreAvailable = list.groups /= []
                    }
            in
            update key flags settings (ItemCardListMsg (Comp.ItemCardList.SetResults list)) m

        ItemSearchAddResp (Ok list) ->
            let
                noff =
                    model.searchOffset + settings.itemSearchPageSize

                m =
                    { model
                        | searchInProgress = False
                        , moreInProgress = False
                        , searchOffset = noff
                        , viewMode = Listing
                        , moreAvailable = list.groups /= []
                    }
            in
            update key flags settings (ItemCardListMsg (Comp.ItemCardList.AddResults list)) m

        ItemSearchAddResp (Err _) ->
            withSub
                ( { model
                    | moreInProgress = False
                  }
                , Cmd.none
                )

        ItemSearchResp (Err _) ->
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
                doSearch flags settings nm

        ToggleSearchMenu ->
            withSub
                ( { model | menuCollapsed = not model.menuCollapsed }
                , Cmd.none
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
            update key flags settings smMsg model

        SetContentOnly str ->
            withSub
                ( { model | contentOnlySearch = Util.Maybe.fromString str }
                , Cmd.none
                )

        SearchTypeMsg lm ->
            let
                ( sm, mv ) =
                    Comp.FixedDropdown.update lm model.searchTypeDropdown
            in
            withSub
                ( { model
                    | searchTypeDropdown = sm
                    , searchTypeForm = Maybe.withDefault model.searchTypeForm mv
                  }
                , Cmd.none
                )

        KeyUpMsg (Just Enter) ->
            update key flags settings DoSearch model

        KeyUpMsg _ ->
            withSub ( model, Cmd.none )



--- Helpers


doSearch : Flags -> UiSettings -> Model -> ( Model, Cmd Msg, Sub Msg )
doSearch flags settings model =
    let
        stype =
            if
                not model.menuCollapsed
                    || Util.String.isNothingOrBlank model.contentOnlySearch
            then
                BasicSearch

            else
                model.searchTypeForm

        model_ =
            { model | searchType = stype }

        searchCmd =
            doSearchCmd flags settings 0 model_

        ( newThrottle, cmd ) =
            Throttle.try searchCmd model.throttle
    in
    withSub
        ( { model_
            | searchInProgress = cmd /= Cmd.none
            , viewMode = Listing
            , searchOffset = 0
            , throttle = newThrottle
          }
        , cmd
        )


doSearchMore : Flags -> UiSettings -> Model -> ( Model, Cmd Msg )
doSearchMore flags settings model =
    let
        cmd =
            doSearchCmd flags settings model.searchOffset model
    in
    ( { model | moreInProgress = True, viewMode = Listing }
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
