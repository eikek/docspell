module Page.Home.Update exposing (update)

import Browser.Navigation as Nav
import Comp.ItemCardList
import Comp.SearchMenu
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Page exposing (Page(..))
import Page.Home.Data exposing (..)
import Util.Update


update : Nav.Key -> Flags -> UiSettings -> Msg -> Model -> ( Model, Cmd Msg )
update key flags settings msg model =
    case msg of
        Init ->
            Util.Update.andThen1
                [ update key flags settings (SearchMenuMsg Comp.SearchMenu.Init)
                ]
                model

        ResetSearch ->
            let
                nm =
                    { model | searchOffset = 0 }
            in
            update key flags settings (SearchMenuMsg Comp.SearchMenu.ResetForm) nm

        SearchMenuMsg m ->
            let
                nextState =
                    Comp.SearchMenu.update flags settings m model.searchMenuModel

                newModel =
                    { model | searchMenuModel = Tuple.first nextState.modelCmd }

                ( m2, c2 ) =
                    if nextState.stateChange && not model.searchInProgress then
                        doSearch flags settings newModel

                    else
                        ( newModel, Cmd.none )
            in
            ( m2, Cmd.batch [ c2, Cmd.map SearchMenuMsg (Tuple.second nextState.modelCmd) ] )

        ItemCardListMsg m ->
            let
                ( m2, c2, mitem ) =
                    Comp.ItemCardList.update flags m model.itemListModel

                cmd =
                    case mitem of
                        Just item ->
                            Page.set key (ItemDetailPage item.id)

                        Nothing ->
                            Cmd.none
            in
            ( { model | itemListModel = m2 }
            , Cmd.batch [ Cmd.map ItemCardListMsg c2, cmd ]
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
            ( { model
                | moreInProgress = False
              }
            , Cmd.none
            )

        ItemSearchResp (Err _) ->
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
            doSearch flags settings nm

        ToggleSearchMenu ->
            ( { model | menuCollapsed = not model.menuCollapsed }
            , Cmd.none
            )

        LoadMore ->
            if model.moreAvailable then
                doSearchMore flags settings model

            else
                ( model, Cmd.none )


doSearch : Flags -> UiSettings -> Model -> ( Model, Cmd Msg )
doSearch flags settings model =
    let
        cmd =
            doSearchCmd flags settings 0 model
    in
    ( { model
        | searchInProgress = True
        , viewMode = Listing
        , searchOffset = 0
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
