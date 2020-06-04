module Page.Home.Update exposing (update)

import Api
import Browser.Navigation as Nav
import Comp.ItemCardList
import Comp.SearchMenu
import Data.Flags exposing (Flags)
import Page exposing (Page(..))
import Page.Home.Data exposing (..)
import Util.Update


update : Nav.Key -> Flags -> Msg -> Model -> ( Model, Cmd Msg )
update key flags msg model =
    case msg of
        Init ->
            Util.Update.andThen1
                [ update key flags (SearchMenuMsg Comp.SearchMenu.Init)
                , doSearch flags
                ]
                model

        ResetSearch ->
            update key flags (SearchMenuMsg Comp.SearchMenu.ResetForm) model

        SearchMenuMsg m ->
            let
                nextState =
                    Comp.SearchMenu.update flags m model.searchMenuModel

                newModel =
                    { model | searchMenuModel = Tuple.first nextState.modelCmd }

                ( m2, c2 ) =
                    if nextState.stateChange then
                        doSearch flags newModel

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
            ( { model | itemListModel = m2 }, Cmd.batch [ Cmd.map ItemCardListMsg c2, cmd ] )

        ItemSearchResp (Ok list) ->
            let
                m =
                    { model | searchInProgress = False, viewMode = Listing }
            in
            update key flags (ItemCardListMsg (Comp.ItemCardList.SetResults list)) m

        ItemSearchResp (Err _) ->
            ( { model | searchInProgress = False }, Cmd.none )

        DoSearch ->
            doSearch flags model

        ToggleSearchMenu ->
            ( { model | menuCollapsed = not model.menuCollapsed }
            , Cmd.none
            )


doSearch : Flags -> Model -> ( Model, Cmd Msg )
doSearch flags model =
    let
        smask =
            Comp.SearchMenu.getItemSearch model.searchMenuModel

        mask =
            { smask | limit = 100 }
    in
    ( { model | searchInProgress = True, viewMode = Listing }
    , Api.itemSearch flags mask ItemSearchResp
    )
