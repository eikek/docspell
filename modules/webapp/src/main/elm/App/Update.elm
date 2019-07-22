module App.Update exposing (update, initPage)

import Api
import Ports
import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Url
import Data.Flags
import App.Data exposing (..)
import Page exposing (Page(..))
import Page.Home.Data
import Page.Home.Update
import Page.Login.Data
import Page.Login.Update
import Page.ManageData.Data
import Page.ManageData.Update
import Page.CollectiveSettings.Data
import Page.CollectiveSettings.Update
import Page.UserSettings.Data
import Page.UserSettings.Update
import Page.Queue.Data
import Page.Queue.Update
import Page.Register.Data
import Page.Register.Update
import Page.Upload.Data
import Page.Upload.Update
import Page.NewInvite.Data
import Page.NewInvite.Update
import Util.Update

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    let
        (m, c, s) = updateWithSub msg model
    in
        ({m|subs = s}, c)

updateWithSub: Msg -> Model -> (Model, Cmd Msg, Sub Msg)
updateWithSub  msg model =
    case msg of
        HomeMsg lm ->
            updateHome lm model |> noSub

        LoginMsg lm ->
            updateLogin lm model |> noSub

        ManageDataMsg lm ->
            updateManageData lm model |> noSub

        CollSettingsMsg m ->
            updateCollSettings m model |> noSub

        UserSettingsMsg m ->
            updateUserSettings m model |> noSub

        QueueMsg m ->
            updateQueue m model |> noSub

        RegisterMsg m ->
            updateRegister m model |> noSub

        UploadMsg m ->
            updateUpload m model

        NewInviteMsg m ->
            updateNewInvite m model |> noSub

        VersionResp (Ok info) ->
            ({model|version = info}, Cmd.none) |> noSub

        VersionResp (Err err) ->
            (model, Cmd.none, Sub.none)

        Logout ->
            (model
            , Cmd.batch
                [ Api.logout model.flags LogoutResp
                , Ports.removeAccount ()
                ]
            , Sub.none)

        LogoutResp _ ->
            ({model|loginModel = Page.Login.Data.emptyModel}, Page.goto (LoginPage Nothing), Sub.none)

        SessionCheckResp res ->
            case res of
                Ok lr ->
                    let
                        newFlags = if lr.success then Data.Flags.withAccount model.flags lr
                                   else Data.Flags.withoutAccount model.flags
                        command = if lr.success then Api.refreshSession newFlags SessionCheckResp
                                  else Cmd.batch [Ports.removeAccount (), Page.goto (Page.loginPage model.page)]
                    in
                        ({model | flags = newFlags}, command, Sub.none)
                Err _ ->
                    (model, Cmd.batch [Ports.removeAccount (), Page.goto (Page.loginPage model.page)], Sub.none)

        NavRequest req ->
            case req of
                Internal url ->
                    let
                        newPage = Page.fromUrl url
                        isCurrent =
                            Page.fromUrl url |>
                            Maybe.map (\p -> p == model.page) |>
                            Maybe.withDefault True
                    in
                        ( model
                        , if isCurrent then Cmd.none else Nav.pushUrl model.key (Url.toString url)
                        , Sub.none
                        )

                External url ->
                    ( model
                    , Nav.load url
                    , Sub.none
                    )

        NavChange url ->
            let
                page  = Page.fromUrl url
                          |> Maybe.withDefault (defaultPage model.flags)
                check  = checkPage model.flags page
                (m, c) = initPage model page
            in
                if check == page then ( { m | page = page }, c, Sub.none )
                else (model, Page.goto check, Sub.none)

        ToggleNavMenu ->
            ({model | navMenuOpen = not model.navMenuOpen }, Cmd.none, Sub.none)


updateNewInvite: Page.NewInvite.Data.Msg -> Model -> (Model, Cmd Msg)
updateNewInvite lmsg model =
    let
        (lm, lc) = Page.NewInvite.Update.update model.flags lmsg model.newInviteModel
    in
        ( {model | newInviteModel = lm }
        , Cmd.map NewInviteMsg lc
        )

updateUpload: Page.Upload.Data.Msg -> Model -> (Model, Cmd Msg, Sub Msg)
updateUpload lmsg model =
    let
        (lm, lc, ls) = Page.Upload.Update.update (Page.uploadId model.page) model.flags lmsg model.uploadModel
    in
        ( { model | uploadModel = lm }
        , Cmd.map UploadMsg lc
        , Sub.map UploadMsg ls
        )

updateRegister: Page.Register.Data.Msg -> Model -> (Model, Cmd Msg)
updateRegister lmsg model =
    let
        (lm, lc) = Page.Register.Update.update model.flags lmsg model.registerModel
    in
        ( { model | registerModel = lm }
        , Cmd.map RegisterMsg lc
        )

updateQueue: Page.Queue.Data.Msg -> Model -> (Model, Cmd Msg)
updateQueue lmsg model =
    let
        (lm, lc) = Page.Queue.Update.update model.flags lmsg model.queueModel
    in
        ( { model | queueModel = lm }
        , Cmd.map QueueMsg lc
        )


updateUserSettings: Page.UserSettings.Data.Msg -> Model -> (Model, Cmd Msg)
updateUserSettings lmsg model =
    let
        (lm, lc) = Page.UserSettings.Update.update model.flags lmsg model.userSettingsModel
    in
        ( { model | userSettingsModel = lm }
        , Cmd.map UserSettingsMsg lc
        )

updateCollSettings: Page.CollectiveSettings.Data.Msg -> Model -> (Model, Cmd Msg)
updateCollSettings lmsg model =
    let
        (lm, lc) = Page.CollectiveSettings.Update.update model.flags lmsg model.collSettingsModel
    in
        ( { model | collSettingsModel = lm }
        , Cmd.map CollSettingsMsg lc
        )

updateLogin: Page.Login.Data.Msg -> Model -> (Model, Cmd Msg)
updateLogin lmsg model =
    let
        (lm, lc, ar) = Page.Login.Update.update (Page.loginPageReferrer model.page) model.flags lmsg model.loginModel
        newFlags = Maybe.map (Data.Flags.withAccount model.flags) ar
                   |> Maybe.withDefault model.flags
    in
        ({model | loginModel = lm, flags = newFlags}
        ,Cmd.map LoginMsg lc
        )

updateHome: Page.Home.Data.Msg -> Model -> (Model, Cmd Msg)
updateHome lmsg model =
    let
        (lm, lc) = Page.Home.Update.update model.flags lmsg model.homeModel
    in
        ( {model | homeModel = lm }
        , Cmd.map HomeMsg lc
        )

updateManageData: Page.ManageData.Data.Msg -> Model -> (Model, Cmd Msg)
updateManageData lmsg model =
    let
        (lm, lc) = Page.ManageData.Update.update model.flags lmsg model.manageDataModel
    in
        ({ model | manageDataModel = lm }
        ,Cmd.map ManageDataMsg lc
        )

initPage: Model -> Page -> (Model, Cmd Msg)
initPage model page =
    case page of
        HomePage ->
            Util.Update.andThen1
                [updateHome Page.Home.Data.Init
                ,updateQueue Page.Queue.Data.StopRefresh
                ] model

        LoginPage _ ->
            updateQueue Page.Queue.Data.StopRefresh model

        ManageDataPage ->
            updateQueue Page.Queue.Data.StopRefresh model

        CollectiveSettingPage ->
            Util.Update.andThen1
                [updateQueue Page.Queue.Data.StopRefresh
                ,updateCollSettings Page.CollectiveSettings.Data.Init
                ] model

        UserSettingPage ->
            updateQueue Page.Queue.Data.StopRefresh model

        QueuePage ->
            updateQueue Page.Queue.Data.Init model

        RegisterPage ->
            updateQueue Page.Queue.Data.StopRefresh model

        UploadPage _ ->
            updateQueue Page.Queue.Data.StopRefresh model

        NewInvitePage ->
            updateQueue Page.Queue.Data.StopRefresh model


noSub: (Model, Cmd Msg) -> (Model, Cmd Msg, Sub Msg)
noSub (m, c) =
    (m, c, Sub.none)
