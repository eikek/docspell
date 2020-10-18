module App.Update exposing
    ( initPage
    , update
    )

import Api
import App.Data exposing (..)
import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Data.Flags
import Page exposing (Page(..))
import Page.CollectiveSettings.Data
import Page.CollectiveSettings.Update
import Page.Home.Data
import Page.Home.Update
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
    case msg of
        HomeMsg lm ->
            updateHome lm model

        LoginMsg lm ->
            updateLogin lm model

        ManageDataMsg lm ->
            updateManageData lm model

        CollSettingsMsg m ->
            updateCollSettings m model

        UserSettingsMsg m ->
            updateUserSettings m model

        QueueMsg m ->
            updateQueue m model

        RegisterMsg m ->
            updateRegister m model

        UploadMsg m ->
            updateUpload m model

        NewInviteMsg m ->
            updateNewInvite m model

        ItemDetailMsg m ->
            updateItemDetail m model

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
            , Page.goto (LoginPage Nothing)
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
                                Api.refreshSession newFlags SessionCheckResp

                            else
                                Cmd.batch
                                    [ Ports.removeAccount ()
                                    , Page.goto (Page.loginPage model.page)
                                    ]
                    in
                    ( { model | flags = newFlags }, command, Sub.none )

                Err _ ->
                    ( model
                    , Cmd.batch
                        [ Ports.removeAccount ()
                        , Page.goto (Page.loginPage model.page)
                        ]
                    , Sub.none
                    )

        NavRequest req ->
            case req of
                Internal url ->
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

                check =
                    checkPage model.flags page

                ( m, c, s ) =
                    initPage model page
            in
            if check == page then
                ( { m | page = page }, c, s )

            else
                ( model, Page.goto check, Sub.none )

        ToggleNavMenu ->
            ( { model | navMenuOpen = not model.navMenuOpen }
            , Cmd.none
            , Sub.none
            )

        GetUiSettings settings ->
            Util.Update.andThen2
                [ updateUserSettings Page.UserSettings.Data.UpdateSettings
                , updateHome Page.Home.Data.DoSearch
                ]
                { model | uiSettings = settings }


updateItemDetail : Page.ItemDetail.Data.Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
updateItemDetail lmsg model =
    let
        inav =
            Page.Home.Data.itemNav model.itemDetailModel.detail.item.id model.homeModel

        ( lm, lc, ls ) =
            Page.ItemDetail.Update.update
                model.key
                model.flags
                inav
                model.uiSettings
                lmsg
                model.itemDetailModel
    in
    ( { model
        | itemDetailModel = lm
      }
    , Cmd.map ItemDetailMsg lc
    , Sub.map ItemDetailMsg ls
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
        ( lm, lc ) =
            Page.Queue.Update.update model.flags lmsg model.queueModel
    in
    ( { model | queueModel = lm }
    , Cmd.map QueueMsg lc
    , Sub.none
    )


updateUserSettings : Page.UserSettings.Data.Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
updateUserSettings lmsg model =
    let
        ( lm, lc, ls ) =
            Page.UserSettings.Update.update model.flags model.uiSettings lmsg model.userSettingsModel
    in
    ( { model
        | userSettingsModel = lm
      }
    , Cmd.map UserSettingsMsg lc
    , Sub.map UserSettingsMsg ls
    )


updateCollSettings : Page.CollectiveSettings.Data.Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
updateCollSettings lmsg model =
    let
        ( lm, lc ) =
            Page.CollectiveSettings.Update.update model.flags
                lmsg
                model.collSettingsModel
    in
    ( { model | collSettingsModel = lm }
    , Cmd.map CollSettingsMsg lc
    , Sub.none
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


updateHome : Page.Home.Data.Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
updateHome lmsg model =
    let
        mid =
            case model.page of
                HomePage ->
                    Util.Maybe.fromString model.itemDetailModel.detail.item.id

                _ ->
                    Nothing

        ( lm, lc, ls ) =
            Page.Home.Update.update mid model.key model.flags model.uiSettings lmsg model.homeModel
    in
    ( { model
        | homeModel = lm
      }
    , Cmd.map HomeMsg lc
    , Sub.map HomeMsg ls
    )


updateManageData : Page.ManageData.Data.Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
updateManageData lmsg model =
    let
        ( lm, lc ) =
            Page.ManageData.Update.update model.flags lmsg model.manageDataModel
    in
    ( { model | manageDataModel = lm }
    , Cmd.map ManageDataMsg lc
    , Sub.none
    )


initPage : Model -> Page -> ( Model, Cmd Msg, Sub Msg )
initPage model_ page =
    let
        model =
            { model_ | page = page }
    in
    case page of
        HomePage ->
            Util.Update.andThen2
                [ updateHome Page.Home.Data.Init
                , updateQueue Page.Queue.Data.StopRefresh
                ]
                model

        LoginPage _ ->
            updateQueue Page.Queue.Data.StopRefresh model

        ManageDataPage ->
            updateQueue Page.Queue.Data.StopRefresh model

        CollectiveSettingPage ->
            Util.Update.andThen2
                [ updateQueue Page.Queue.Data.StopRefresh
                , updateCollSettings Page.CollectiveSettings.Data.Init
                ]
                model

        UserSettingPage ->
            Util.Update.andThen2
                [ updateQueue Page.Queue.Data.StopRefresh
                ]
                model

        QueuePage ->
            updateQueue Page.Queue.Data.Init model

        RegisterPage ->
            updateQueue Page.Queue.Data.StopRefresh model

        UploadPage _ ->
            Util.Update.andThen2
                [ updateQueue Page.Queue.Data.StopRefresh
                , updateUpload Page.Upload.Data.Clear
                ]
                model

        NewInvitePage ->
            updateQueue Page.Queue.Data.StopRefresh model

        ItemDetailPage id ->
            Util.Update.andThen2
                [ updateItemDetail (Page.ItemDetail.Data.Init id)
                , updateQueue Page.Queue.Data.StopRefresh
                ]
                model
