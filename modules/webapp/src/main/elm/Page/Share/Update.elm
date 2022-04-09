{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Share.Update exposing (UpdateResult, update)

import Api
import Comp.DownloadAll
import Comp.ItemCardList
import Comp.LinkTarget exposing (LinkTarget)
import Comp.PowerSearchInput
import Comp.SearchMenu
import Comp.SharePasswordForm
import Data.Flags exposing (Flags)
import Data.ItemIds
import Data.ItemQuery as Q
import Data.SearchMode
import Data.UiSettings exposing (UiSettings)
import Page.Share.Data exposing (..)
import Process
import Set
import Task
import Time
import Util.Html
import Util.Maybe
import Util.Update


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    }


update : Flags -> UiSettings -> String -> Msg -> Model -> UpdateResult
update flags settings shareId msg model =
    case msg of
        VerifyResp (Ok res) ->
            if res.success then
                noSub
                    ( { model
                        | pageError = PageErrorNone
                        , mode = ModeShare
                        , verifyResult = res
                        , searchInProgress = True
                      }
                    , Cmd.batch
                        [ makeSearchCmd flags True model
                        , Api.clientSettingsShare flags res.token UiSettingsResp
                        ]
                    )

            else if res.passwordRequired then
                noSub
                    ( { model
                        | pageError = PageErrorNone
                        , mode = ModePassword
                      }
                    , Cmd.none
                    )

            else
                noSub
                    ( { model | pageError = PageErrorAuthFail }
                    , Cmd.none
                    )

        VerifyResp (Err err) ->
            noSub ( { model | pageError = PageErrorHttp err }, Cmd.none )

        SearchResp (Ok list) ->
            update flags
                settings
                shareId
                (ItemListMsg (Comp.ItemCardList.SetResults list))
                { model | searchInProgress = False, pageError = PageErrorNone }

        SearchResp (Err err) ->
            noSub ( { model | pageError = PageErrorHttp err, searchInProgress = False }, Cmd.none )

        StatsResp doInit (Ok stats) ->
            let
                lm =
                    if doInit then
                        Comp.SearchMenu.initFromStats stats

                    else
                        Comp.SearchMenu.setFromStats stats
            in
            update flags
                settings
                shareId
                (SearchMenuMsg lm)
                model

        StatsResp _ (Err err) ->
            noSub ( { model | pageError = PageErrorHttp err }, Cmd.none )

        PasswordMsg lmsg ->
            let
                ( m, c, res ) =
                    Comp.SharePasswordForm.update shareId flags lmsg model.passwordModel
            in
            case res of
                Just verifyResult ->
                    update flags
                        settings
                        shareId
                        (VerifyResp (Ok verifyResult))
                        model

                Nothing ->
                    noSub ( { model | passwordModel = m }, Cmd.map PasswordMsg c )

        SearchMenuMsg lm ->
            let
                res =
                    Comp.SearchMenu.update flags settings lm model.searchMenuModel

                nextModel =
                    { model | searchMenuModel = res.model }

                ( initSearch, searchCmd ) =
                    if res.stateChange && not model.searchInProgress then
                        ( True, makeSearchCmd flags False nextModel )

                    else
                        ( False, Cmd.none )
            in
            noSub
                ( { nextModel | searchInProgress = initSearch }
                , Cmd.batch [ Cmd.map SearchMenuMsg res.cmd, searchCmd ]
                )

        PowerSearchMsg lm ->
            let
                res =
                    Comp.PowerSearchInput.update lm model.powerSearchInput

                nextModel =
                    { model | powerSearchInput = res.model }

                ( initSearch, searchCmd ) =
                    case res.action of
                        Comp.PowerSearchInput.NoAction ->
                            ( False, Cmd.none )

                        Comp.PowerSearchInput.SubmitSearch ->
                            ( True, makeSearchCmd flags False nextModel )
            in
            { model = { nextModel | searchInProgress = initSearch }
            , cmd = Cmd.batch [ Cmd.map PowerSearchMsg res.cmd, searchCmd ]
            , sub = Sub.map PowerSearchMsg res.subs
            }

        ResetSearch ->
            let
                nm =
                    { model
                        | powerSearchInput = Comp.PowerSearchInput.init
                        , contentSearch = Nothing
                        , pageError = PageErrorNone
                    }
            in
            update flags settings shareId (SearchMenuMsg Comp.SearchMenu.ResetForm) nm

        ItemListMsg lm ->
            let
                result =
                    Comp.ItemCardList.update flags lm model.itemListModel

                searchMsg =
                    Maybe.map Util.Update.cmdUnit (linkTargetMsg result.linkTarget)
                        |> Maybe.withDefault Cmd.none

                vm =
                    model.viewMode

                itemRows =
                    case result.toggleOpenRow of
                        Just rid ->
                            if Set.member rid vm.rowsOpen then
                                Set.remove rid vm.rowsOpen

                            else
                                Set.insert rid vm.rowsOpen

                        Nothing ->
                            vm.rowsOpen
            in
            noSub
                ( { model | itemListModel = result.model, viewMode = { vm | rowsOpen = itemRows } }
                , Cmd.batch [ Cmd.map ItemListMsg result.cmd, searchMsg ]
                )

        ToggleSearchBar ->
            noSub
                ( { model
                    | searchMode =
                        case model.searchMode of
                            SearchBarContent ->
                                SearchBarNormal

                            SearchBarNormal ->
                                SearchBarContent
                  }
                , Cmd.none
                )

        SetContentSearch q ->
            noSub ( { model | contentSearch = Util.Maybe.fromString q }, Cmd.none )

        ContentSearchKey (Just Util.Html.Enter) ->
            noSub ( model, makeSearchCmd flags False model )

        ContentSearchKey _ ->
            noSub ( model, Cmd.none )

        ToggleShowGroups ->
            let
                vm =
                    model.viewMode

                next =
                    { vm | showGroups = not vm.showGroups, menuOpen = False }
            in
            noSub ( { model | viewMode = next }, Cmd.none )

        ToggleViewMenu ->
            let
                vm =
                    model.viewMode

                next =
                    { vm | menuOpen = not vm.menuOpen }
            in
            noSub ( { model | viewMode = next }, Cmd.none )

        ToggleArrange am ->
            let
                vm =
                    model.viewMode

                next =
                    { vm | arrange = am, menuOpen = False }
            in
            noSub ( { model | viewMode = next }, Cmd.none )

        UiSettingsResp (Ok s) ->
            noSub ( { model | uiSettings = s }, Cmd.none )

        UiSettingsResp (Err _) ->
            noSub ( model, Cmd.none )

        DownloadAllMsg lm ->
            case model.topContent of
                TopContentDownload dm ->
                    let
                        res =
                            Comp.DownloadAll.update flags lm dm

                        nextModel =
                            if res.closed then
                                TopContentHidden

                            else
                                TopContentDownload res.model

                        -- The share page can't use websockets (not authenticated) so need to poll
                        -- for new download state
                        checkSub =
                            if Comp.DownloadAll.isPreparing res.model then
                                Process.sleep 3500
                                    |> Task.perform (always (DownloadAllMsg Comp.DownloadAll.checkDownload))

                            else
                                Cmd.none
                    in
                    { model = { model | topContent = nextModel }
                    , cmd =
                        Cmd.batch
                            [ Cmd.map DownloadAllMsg res.cmd
                            , checkSub
                            ]
                    , sub = Sub.none
                    }

                _ ->
                    noSub ( model, Cmd.none )

        ToggleDownloadAll ->
            let
                vm =
                    model.viewMode

                nextVm =
                    { vm | menuOpen = False }
            in
            case model.topContent of
                TopContentHidden ->
                    let
                        query =
                            createQuery flags model
                                |> Maybe.withDefault (Q.DateMs Q.Gt 0)

                        am =
                            Comp.DownloadAll.AccessShare shareId

                        ( dm, dc ) =
                            Comp.DownloadAll.init am flags (Q.render query)
                    in
                    noSub ( { model | topContent = TopContentDownload dm, viewMode = nextVm }, Cmd.map DownloadAllMsg dc )

                TopContentDownload _ ->
                    noSub ( { model | topContent = TopContentHidden, viewMode = nextVm }, Cmd.none )


noSub : ( Model, Cmd Msg ) -> UpdateResult
noSub ( m, c ) =
    UpdateResult m c Sub.none


createQuery : Flags -> Model -> Maybe Q.ItemQuery
createQuery flags model =
    Q.and
        [ Comp.SearchMenu.getItemQuery Data.ItemIds.empty model.searchMenuModel
        , Maybe.map Q.Fragment <|
            case model.searchMode of
                SearchBarNormal ->
                    Comp.PowerSearchInput.getSearchString model.powerSearchInput

                SearchBarContent ->
                    if flags.config.fullTextSearchEnabled then
                        Maybe.map (Q.Contents >> Q.render) model.contentSearch

                    else
                        Maybe.map (Q.AllNames >> Q.render) model.contentSearch
        ]


makeSearchCmd : Flags -> Bool -> Model -> Cmd Msg
makeSearchCmd flags doInit model =
    let
        xq =
            createQuery flags model

        request mq =
            { offset = Nothing
            , limit = Nothing
            , withDetails = Just True
            , query = Q.renderMaybe mq
            , searchMode = Just (Data.SearchMode.asString Data.SearchMode.Normal)
            }

        searchCmd =
            Api.searchShare flags model.verifyResult.token (request xq) SearchResp

        statsCmd =
            Api.searchShareStats flags model.verifyResult.token (request xq) (StatsResp doInit)
    in
    Cmd.batch [ searchCmd, statsCmd ]


linkTargetMsg : LinkTarget -> Maybe Msg
linkTargetMsg linkTarget =
    Maybe.map SearchMenuMsg (Comp.SearchMenu.linkTargetMsg linkTarget)
