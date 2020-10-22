module Page.Home.Update exposing (update)

import Browser.Navigation as Nav
import Comp.FixedDropdown
import Comp.ItemCardList
import Comp.SearchMenu
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Page exposing (Page(..))
import Page.Home.Data exposing (..)
import Process
import Scroll
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
            in
            withSub
                ( { model
                    | itemListModel = result.model
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



--- Helpers


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


doSearch : Flags -> UiSettings -> Bool -> Model -> ( Model, Cmd Msg, Sub Msg )
doSearch flags settings scroll model =
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
