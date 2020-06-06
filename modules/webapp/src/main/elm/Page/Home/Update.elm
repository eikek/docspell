module Page.Home.Update exposing (update)

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
            let
                nm =
                    { model | searchOffset = 0 }
            in
            update key flags (SearchMenuMsg Comp.SearchMenu.ResetForm) nm

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
            ( { model | itemListModel = m2 }
            , Cmd.batch [ Cmd.map ItemCardListMsg c2, cmd ]
            )

        ItemSearchResp (Ok list) ->
            let
                noff =
                    model.searchOffset + searchLimit

                m =
                    { model
                        | searchInProgress = False
                        , moreInProgress = False
                        , searchOffset = noff
                        , viewMode = Listing
                        , moreAvailable = list.groups /= []
                    }
            in
            if model.searchOffset == 0 then
                update key flags (ItemCardListMsg (Comp.ItemCardList.SetResults list)) m

            else
                update key flags (ItemCardListMsg (Comp.ItemCardList.AddResults list)) m

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
            doSearch flags nm

        ToggleSearchMenu ->
            ( { model | menuCollapsed = not model.menuCollapsed }
            , Cmd.none
            )

        LoadMore ->
            if model.moreAvailable then
                doSearchMore flags model

            else
                ( model, Cmd.none )


doSearch : Flags -> Model -> ( Model, Cmd Msg )
doSearch flags model =
    let
        cmd =
            doSearchCmd flags 0 model.searchMenuModel
    in
    ( { model
        | searchInProgress = True
        , viewMode = Listing
        , searchOffset = 0
      }
    , cmd
    )


doSearchMore : Flags -> Model -> ( Model, Cmd Msg )
doSearchMore flags model =
    let
        cmd =
            doSearchCmd flags model.searchOffset model.searchMenuModel
    in
    ( { model | moreInProgress = True, viewMode = Listing }
    , cmd
    )
