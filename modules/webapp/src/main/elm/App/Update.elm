{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module App.Update exposing
    ( initPage
    , update
    )

import Api
import App.Data exposing (..)
import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Data.AppEvent exposing (AppEvent(..))
import Data.Environment as Env
import Data.Flags
import Data.ItemIds exposing (ItemIds)
import Data.ServerEvent exposing (ServerEvent(..))
import Data.UiSettings exposing (UiSettings)
import Data.UiTheme
import Messages exposing (Messages)
import Page exposing (Page(..))
import Page.CollectiveSettings.Data
import Page.CollectiveSettings.Update
import Page.Dashboard.Data
import Page.Dashboard.Update
import Page.ItemDetail.Data
import Page.ItemDetail.Update
import Page.Login.Data
import Page.Login.Update
import Page.ManageData.Data
import Page.ManageData.Update
import Page.NewInvite.Data
import Page.NewInvite.Update
import Page.Queue.Data
import Page.Queue.Update
import Page.Register.Data
import Page.Register.Update
import Page.Search.Data
import Page.Search.Update
import Page.Share.Data
import Page.Share.Update
import Page.ShareDetail.Data
import Page.ShareDetail.Update
import Page.Upload.Data
import Page.Upload.Update
import Page.UserSettings.Data
import Page.UserSettings.Update
import Ports
import Url
import Util.Maybe
import Util.Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        ( m, c, s ) =
            updateWithSub msg model
    in
    ( { m | subs = s }, c )


updateWithSub : Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
updateWithSub msg model =
    let
        texts =
            Messages.get <| App.Data.getUiLanguage model
    in
    case msg of
        ToggleSidebar ->
            ( { model | sidebarVisible = not model.sidebarVisible }, Cmd.none, Sub.none )

        ToggleDarkMode ->
            case model.flags.account of
                Just _ ->
                    let
                        settings =
                            model.uiSettings

                        next =
                            Data.UiTheme.cycle settings.uiTheme

                        newSettings s =
                            { s | uiTheme = Just (Data.UiTheme.toString next) }
                    in
                    -- when authenticated, store it in settings only
                    -- once new settings are successfully saved (the
                    -- response is arrived), the ui is updated. so it
                    -- is also updated on page refresh
                    ( { model | userMenuOpen = False }
                    , Api.saveUserClientSettingsBy model.flags newSettings ClientSettingsSaveResp
                    , Sub.none
                    )

                Nothing ->
                    let
                        next =
                            Data.UiTheme.cycle model.anonymousTheme
                    in
                    -- when not logged in, simply set the theme
                    ( { model | userMenuOpen = False, anonymousTheme = next }
                    , Ports.setUiTheme next
                    , Sub.none
                    )

        ClientSettingsSaveResp (Ok res) ->
            if res.success then
                ( model, Api.getClientSettings model.flags GetUiSettings, Sub.none )

            else
                ( model, Cmd.none, Sub.none )

        ClientSettingsSaveResp (Err _) ->
            ( model, Cmd.none, Sub.none )

        ToggleLangMenu ->
            ( { model | langMenuOpen = not model.langMenuOpen }
            , Cmd.none
            , Sub.none
            )

        SetLanguage lang ->
            ( { model | anonymousUiLang = lang, langMenuOpen = False }, Cmd.none, Sub.none )

        SearchMsg lm ->
            updateSearch texts lm model

        ShareMsg lm ->
            updateShare lm model

        ShareDetailMsg lm ->
            updateShareDetail lm model

        LoginMsg lm ->
            updateLogin lm model

        ManageDataMsg lm ->
            updateManageData lm model

        CollSettingsMsg m ->
            updateCollSettings texts m model

        UserSettingsMsg m ->
            updateUserSettings texts m model

        QueueMsg m ->
            updateQueue m model

        RegisterMsg m ->
            updateRegister m model

        UploadMsg m ->
            updateUpload m model

        NewInviteMsg m ->
            updateNewInvite m model

        ItemDetailMsg m ->
            updateItemDetail texts m model

        DashboardMsg m ->
            updateDashboard texts m model

        VersionResp (Ok info) ->
            ( { model | version = info }, Cmd.none, Sub.none )

        VersionResp (Err _) ->
            ( model, Cmd.none, Sub.none )

        Logout ->
            ( model
            , Cmd.batch
                [ Api.logout model.flags LogoutResp
                , Ports.removeAccount ()
                ]
            , Sub.none
            )

        LogoutResp _ ->
            ( { model | loginModel = Page.Login.Data.emptyModel }
            , Page.goto (LoginPage Page.emptyLoginData)
            , Sub.none
            )

        SessionCheckResp res ->
            case res of
                Ok lr ->
                    let
                        newFlags =
                            if lr.success then
                                Data.Flags.withAccount model.flags lr

                            else
                                Data.Flags.withoutAccount model.flags

                        command =
                            if lr.success then
                                Cmd.batch
                                    [ Api.refreshSession newFlags SessionCheckResp
                                    , Ports.setAccount lr
                                    , case model.flags.account of
                                        Just _ ->
                                            Cmd.none

                                        Nothing ->
                                            Page.goto model.page
                                    ]

                            else
                                Cmd.batch
                                    [ Ports.removeAccount ()
                                    , case model.page of
                                        LoginPage _ ->
                                            Cmd.none

                                        _ ->
                                            Page.goto (Page.loginPage model.page)
                                    ]
                    in
                    ( { model | flags = newFlags }, command, Sub.none )

                Err _ ->
                    ( model
                    , Cmd.batch
                        [ Ports.removeAccount ()
                        , case model.page of
                            LoginPage _ ->
                                Cmd.none

                            _ ->
                                Page.goto (Page.loginPage model.page)
                        ]
                    , Sub.none
                    )

        NavRequest req ->
            case req of
                Internal url ->
                    if String.startsWith "/app" url.path then
                        let
                            isCurrent =
                                Page.fromUrl url
                                    |> Maybe.map (\p -> p == model.page)
                                    |> Maybe.withDefault True
                        in
                        ( model
                        , if isCurrent then
                            Cmd.none

                          else
                            Nav.pushUrl model.key (Url.toString url)
                        , Sub.none
                        )

                    else
                        ( model, Nav.load <| Url.toString url, Sub.none )

                External url ->
                    ( model
                    , Nav.load url
                    , Sub.none
                    )

        NavChange url ->
            let
                page =
                    Page.fromUrl url
                        |> Maybe.withDefault (defaultPage model.flags)

                ( m, c, s ) =
                    initPage model page
            in
            ( { m | page = page }, c, s )

        ToggleNavMenu ->
            ( { model
                | navMenuOpen = not model.navMenuOpen
                , userMenuOpen =
                    if not model.navMenuOpen then
                        False

                    else
                        model.userMenuOpen
              }
            , Cmd.none
            , Sub.none
            )

        ToggleUserMenu ->
            ( { model
                | userMenuOpen = not model.userMenuOpen
                , navMenuOpen =
                    if not model.userMenuOpen then
                        False

                    else
                        model.navMenuOpen
              }
            , Cmd.none
            , Sub.none
            )

        GetUiSettings (Ok settings) ->
            applyClientSettings texts model settings

        GetUiSettings (Err _) ->
            ( model, Cmd.none, Sub.none )

        ReceiveWsMessage data ->
            case data of
                Ok (JobDone task) ->
                    let
                        isProcessItem =
                            task == "process-item"

                        newModel =
                            { model
                                | showNewItemsArrived = isProcessItem && not (Page.isSearchPage model.page)
                                , jobsWaiting = max 0 (model.jobsWaiting - 1)
                            }
                    in
                    if Page.isSearchPage model.page && isProcessItem then
                        updateSearch texts Page.Search.Data.RefreshView newModel

                    else if Page.isDashboardPage model.page && isProcessItem then
                        updateDashboard texts Page.Dashboard.Data.reloadDashboardData newModel

                    else
                        ( newModel, Cmd.none, Sub.none )

                Ok (JobSubmitted _) ->
                    ( { model | jobsWaiting = model.jobsWaiting + 1 }, Cmd.none, Sub.none )

                Ok (JobsWaiting n) ->
                    ( { model | jobsWaiting = max 0 n }, Cmd.none, Sub.none )

                Err _ ->
                    ( model, Cmd.none, Sub.none )

        ToggleShowNewItemsArrived ->
            ( { model | showNewItemsArrived = not model.showNewItemsArrived }
            , Cmd.none
            , Sub.none
            )


modelEnv : Model -> Env.Update
modelEnv model =
    { key = model.key
    , selectedItems = model.selectedItems
    , flags = model.flags
    , settings = model.uiSettings
    }


applyClientSettings : Messages -> Model -> UiSettings -> ( Model, Cmd Msg, Sub Msg )
applyClientSettings texts model settings =
    let
        setTheme =
            Ports.setUiTheme settings.uiTheme

        flags =
            model.flags
    in
    Util.Update.andThen2
        [ \m ->
            ( { m | sidebarVisible = flags.innerWidth > 768 && settings.sideMenuVisible }
            , setTheme
            , Sub.none
            )
        , updateDashboard texts Page.Dashboard.Data.reloadUiSettings
        , updateSearch texts Page.Search.Data.UiSettingsUpdated
        , updateItemDetail texts Page.ItemDetail.Data.UiSettingsUpdated
        ]
        { model | uiSettings = settings }


applySelectionChange : Messages -> Model -> ItemIds -> ( Model, Cmd Msg, Sub Msg )
applySelectionChange texts model newSelection =
    if model.selectedItems == newSelection then
        ( { model | selectedItems = newSelection }, Cmd.none, Sub.none )

    else
        Util.Update.andThen2
            [ updateSearch texts Page.Search.Data.ItemSelectionChanged
            ]
            { model | selectedItems = newSelection }


updateDashboard : Messages -> Page.Dashboard.Data.Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
updateDashboard texts lmsg model =
    let
        ( dbm, dbc, dbs ) =
            Page.Dashboard.Update.update texts.dashboard
                model.uiSettings
                model.key
                model.flags
                lmsg
                model.dashboardModel
    in
    ( { model | dashboardModel = dbm }
    , Cmd.map DashboardMsg dbc
    , Sub.map DashboardMsg dbs
    )


updateShareDetail : Page.ShareDetail.Data.Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
updateShareDetail lmsg model =
    case Page.pageShareDetail model.page of
        Just ( shareId, itemId ) ->
            let
                ( m, c ) =
                    Page.ShareDetail.Update.update shareId itemId model.flags lmsg model.shareDetailModel
            in
            ( { model | shareDetailModel = m }
            , Cmd.map ShareDetailMsg c
            , Sub.none
            )

        Nothing ->
            ( model, Cmd.none, Sub.none )


updateShare : Page.Share.Data.Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
updateShare lmsg model =
    case Page.pageShareId model.page of
        Just id ->
            let
                result =
                    Page.Share.Update.update model.flags model.uiSettings id lmsg model.shareModel
            in
            ( { model | shareModel = result.model }
            , Cmd.map ShareMsg result.cmd
            , Sub.map ShareMsg result.sub
            )

        Nothing ->
            ( model, Cmd.none, Sub.none )


updateItemDetail : Messages -> Page.ItemDetail.Data.Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
updateItemDetail texts lmsg model =
    let
        inav =
            Page.Search.Data.itemNav model.itemDetailModel.detail.item.id model.searchModel

        result =
            Page.ItemDetail.Update.update
                inav
                (modelEnv model)
                lmsg
                model.itemDetailModel

        ( model_, cmd_, sub_ ) =
            applySelectionChange
                texts
                { model | itemDetailModel = result.model }
                result.selectedItems

        ( hm, hc, hs ) =
            updateSearch texts (Page.Search.Data.SetLinkTarget result.linkTarget) model_

        ( hm1, hc1, hs1 ) =
            case result.removedItem of
                Just removedId ->
                    updateSearch texts (Page.Search.Data.RemoveItem removedId) hm

                Nothing ->
                    ( hm, hc, hs )
    in
    ( hm1
    , Cmd.batch [ Cmd.map ItemDetailMsg result.cmd, hc, hc1, cmd_ ]
    , Sub.batch [ Sub.map ItemDetailMsg result.sub, hs, hs1, sub_ ]
    )


updateNewInvite : Page.NewInvite.Data.Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
updateNewInvite lmsg model =
    let
        ( lm, lc ) =
            Page.NewInvite.Update.update model.flags lmsg model.newInviteModel
    in
    ( { model | newInviteModel = lm }
    , Cmd.map NewInviteMsg lc
    , Sub.none
    )


updateUpload : Page.Upload.Data.Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
updateUpload lmsg model =
    let
        ( lm, lc, ls ) =
            Page.Upload.Update.update
                (Page.uploadId model.page)
                model.flags
                lmsg
                model.uploadModel
    in
    ( { model | uploadModel = lm }
    , Cmd.map UploadMsg lc
    , Sub.map UploadMsg ls
    )


updateRegister : Page.Register.Data.Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
updateRegister lmsg model =
    let
        ( lm, lc ) =
            Page.Register.Update.update model.flags lmsg model.registerModel
    in
    ( { model | registerModel = lm }
    , Cmd.map RegisterMsg lc
    , Sub.none
    )


updateQueue : Page.Queue.Data.Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
updateQueue lmsg model =
    let
        notQueuePage =
            model.page /= QueuePage

        ( lm, lc ) =
            Page.Queue.Update.update model.flags notQueuePage lmsg model.queueModel
    in
    ( { model | queueModel = lm }
    , Cmd.map QueueMsg lc
    , Sub.none
    )


updateUserSettings : Messages -> Page.UserSettings.Data.Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
updateUserSettings _ lmsg model =
    let
        result =
            Page.UserSettings.Update.update model.flags model.uiSettings lmsg model.userSettingsModel

        model_ =
            { model | userSettingsModel = result.model }

        lc =
            case result.appEvent of
                AppReloadUiSettings ->
                    Api.getClientSettings model.flags GetUiSettings

                AppNothing ->
                    Cmd.none
    in
    ( model_
    , Cmd.batch
        [ Cmd.map UserSettingsMsg result.cmd
        , lc
        ]
    , Sub.batch
        [ Sub.map UserSettingsMsg result.sub
        ]
    )


updateCollSettings : Messages -> Page.CollectiveSettings.Data.Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
updateCollSettings texts lmsg model =
    let
        ( lm, lc, ls ) =
            Page.CollectiveSettings.Update.update texts.collectiveSettings
                model.flags
                lmsg
                model.collSettingsModel
    in
    ( { model | collSettingsModel = lm }
    , Cmd.map CollSettingsMsg lc
    , Sub.map CollSettingsMsg ls
    )


updateLogin : Page.Login.Data.Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
updateLogin lmsg model =
    let
        ( lm, lc, ar ) =
            Page.Login.Update.update (Page.loginPageReferrer model.page)
                model.flags
                lmsg
                model.loginModel

        newFlags =
            Maybe.map (Data.Flags.withAccount model.flags) ar
                |> Maybe.withDefault model.flags
    in
    ( { model | loginModel = lm, flags = newFlags }
    , Cmd.map LoginMsg lc
    , Sub.none
    )


updateSearch : Messages -> Page.Search.Data.Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
updateSearch texts lmsg model =
    let
        ( lastViewItemId, bookmarkId ) =
            case model.page of
                SearchPage bId ->
                    ( Util.Maybe.fromString model.itemDetailModel.detail.item.id, bId )

                _ ->
                    ( Nothing, Nothing )

        env =
            modelEnv model

        result =
            Page.Search.Update.update texts.search bookmarkId lastViewItemId env lmsg model.searchModel

        lc =
            case result.appEvent of
                AppReloadUiSettings ->
                    Api.getClientSettings model.flags GetUiSettings

                AppNothing ->
                    Cmd.none

        ( model_, cmd_, sub_ ) =
            applySelectionChange texts { model | searchModel = result.model } result.selectedItems
    in
    ( model_
    , Cmd.batch [ Cmd.map SearchMsg result.cmd, lc, cmd_ ]
    , Sub.batch [ Sub.map SearchMsg result.sub, sub_ ]
    )


updateManageData : Page.ManageData.Data.Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
updateManageData lmsg model =
    let
        ( lm, lc, ls ) =
            Page.ManageData.Update.update model.flags lmsg model.manageDataModel
    in
    ( { model | manageDataModel = lm }
    , Cmd.map ManageDataMsg lc
    , Sub.map ManageDataMsg ls
    )


initPage : Model -> Page -> ( Model, Cmd Msg, Sub Msg )
initPage model_ page =
    let
        model =
            { model_ | page = page }

        texts =
            Messages.get <| App.Data.getUiLanguage model

        noop =
            ( model, Cmd.none, Sub.none )
    in
    case page of
        SearchPage _ ->
            Util.Update.andThen2
                [ updateSearch texts Page.Search.Data.Init
                ]
                model

        LoginPage _ ->
            noop

        ManageDataPage ->
            noop

        CollectiveSettingPage ->
            Util.Update.andThen2
                [ updateCollSettings texts Page.CollectiveSettings.Data.Init
                ]
                model

        UserSettingPage ->
            noop

        QueuePage ->
            updateQueue Page.Queue.Data.Init model

        RegisterPage ->
            noop

        UploadPage _ ->
            Util.Update.andThen2
                [ updateUpload Page.Upload.Data.reset
                ]
                model

        NewInvitePage ->
            noop

        ItemDetailPage id ->
            Util.Update.andThen2
                [ updateItemDetail texts (Page.ItemDetail.Data.Init id)
                ]
                model

        SharePage id ->
            let
                cmd =
                    Cmd.map ShareMsg (Page.Share.Data.initCmd id model.flags)

                shareModel =
                    model.shareModel
            in
            if shareModel.initialized then
                ( model, Cmd.none, Sub.none )

            else
                ( { model | shareModel = { shareModel | initialized = True } }, cmd, Sub.none )

        ShareDetailPage _ _ ->
            case model_.page of
                SharePage _ ->
                    let
                        verifyResult =
                            model.shareModel.verifyResult
                    in
                    updateShareDetail (Page.ShareDetail.Data.VerifyResp (Ok verifyResult)) model

                _ ->
                    ( model, Cmd.none, Sub.none )

        DashboardPage ->
            ( model, Cmd.map DashboardMsg (Page.Dashboard.Data.reinitCmd model.flags), Sub.none )
