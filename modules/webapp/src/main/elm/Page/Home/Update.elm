module Page.Home.Update exposing (update)

import Api
import Comp.ItemDetail
import Comp.ItemList
import Comp.SearchMenu
import Data.Flags exposing (Flags)
import Page.Home.Data exposing (..)
import Util.Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        Init ->
            Util.Update.andThen1
                [ update flags (SearchMenuMsg Comp.SearchMenu.Init)
                , update flags (ItemDetailMsg Comp.ItemDetail.Init)
                , doSearch flags
                ]
                model

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

        ItemListMsg m ->
            let
                ( m2, c2, mitem ) =
                    Comp.ItemList.update flags m model.itemListModel

                cmd =
                    case mitem of
                        Just item ->
                            Api.itemDetail flags item.id ItemDetailResp

                        Nothing ->
                            Cmd.none
            in
            ( { model | itemListModel = m2 }, Cmd.batch [ Cmd.map ItemListMsg c2, cmd ] )

        ItemSearchResp (Ok list) ->
            let
                m =
                    { model | searchInProgress = False, viewMode = Listing }
            in
            update flags (ItemListMsg (Comp.ItemList.SetResults list)) m

        ItemSearchResp (Err _) ->
            ( { model | searchInProgress = False }, Cmd.none )

        DoSearch ->
            doSearch flags model

        ItemDetailMsg m ->
            let
                ( m2, c2, nav ) =
                    Comp.ItemDetail.update flags m model.itemDetailModel

                newModel =
                    { model | itemDetailModel = m2 }

                newCmd =
                    Cmd.map ItemDetailMsg c2
            in
            case nav of
                Comp.ItemDetail.NavBack ->
                    doSearch flags newModel

                Comp.ItemDetail.NavPrev ->
                    case Comp.ItemList.prevItem model.itemListModel m2.item.id of
                        Just n ->
                            ( newModel, Cmd.batch [ newCmd, Api.itemDetail flags n.id ItemDetailResp ] )

                        Nothing ->
                            ( newModel, newCmd )

                Comp.ItemDetail.NavNext ->
                    case Comp.ItemList.nextItem model.itemListModel m2.item.id of
                        Just n ->
                            ( newModel, Cmd.batch [ newCmd, Api.itemDetail flags n.id ItemDetailResp ] )

                        Nothing ->
                            ( newModel, newCmd )

                Comp.ItemDetail.NavNextOrBack ->
                    case Comp.ItemList.nextItem model.itemListModel m2.item.id of
                        Just n ->
                            ( newModel, Cmd.batch [ newCmd, Api.itemDetail flags n.id ItemDetailResp ] )

                        Nothing ->
                            doSearch flags newModel

                Comp.ItemDetail.NavNone ->
                    ( newModel, newCmd )

        ItemDetailResp (Ok item) ->
            let
                m =
                    { model | viewMode = Detail }
            in
            update flags (ItemDetailMsg (Comp.ItemDetail.SetItem item)) m

        ItemDetailResp (Err _) ->
            ( model, Cmd.none )


doSearch : Flags -> Model -> ( Model, Cmd Msg )
doSearch flags model =
    let
        mask =
            Comp.SearchMenu.getItemSearch model.searchMenuModel
    in
    ( { model | searchInProgress = True, viewMode = Listing }
    , Api.itemSearch flags mask ItemSearchResp
    )
