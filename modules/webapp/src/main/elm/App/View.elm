module App.View exposing (view)

import App.Data exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Page exposing (Page(..))
import Page.CollectiveSettings.View
import Page.Home.Data
import Page.Home.View
import Page.ItemDetail.View
import Page.Login.View
import Page.ManageData.View
import Page.NewInvite.View
import Page.Queue.View
import Page.Register.View
import Page.Upload.View
import Page.UserSettings.View
import Util.Maybe


view : Model -> Html Msg
view model =
    case model.page of
        LoginPage _ ->
            loginLayout model

        RegisterPage ->
            registerLayout model

        NewInvitePage ->
            newInviteLayout model

        _ ->
            defaultLayout model


registerLayout : Model -> Html Msg
registerLayout model =
    div [ class "register-layout" ]
        [ viewRegister model
        , footer model
        ]


loginLayout : Model -> Html Msg
loginLayout model =
    div [ class "login-layout" ]
        [ viewLogin model
        , footer model
        ]


newInviteLayout : Model -> Html Msg
newInviteLayout model =
    div [ class "newinvite-layout" ]
        [ viewNewInvite model
        , footer model
        ]


defaultLayout : Model -> Html Msg
defaultLayout model =
    div [ class "default-layout" ]
        [ div [ class "ui fixed top sticky attached large menu top-menu" ]
            [ div [ class "ui fluid container" ]
                [ a
                    [ class "header item narrow-item"
                    , Page.href HomePage
                    ]
                    [ img
                        [ class "image"
                        , src (model.flags.config.docspellAssetPath ++ "/img/logo-96.png")
                        ]
                        []
                    , div [ class "content" ]
                        [ text model.flags.config.appName
                        ]
                    ]
                , loginInfo model
                ]
            ]
        , div
            [ class "main-content"
            , id "main-content"
            ]
            [ case model.page of
                HomePage ->
                    viewHome model

                LoginPage _ ->
                    viewLogin model

                ManageDataPage ->
                    viewManageData model

                CollectiveSettingPage ->
                    viewCollectiveSettings model

                UserSettingPage ->
                    viewUserSettings model

                QueuePage ->
                    viewQueue model

                RegisterPage ->
                    viewRegister model

                UploadPage mid ->
                    viewUpload mid model

                NewInvitePage ->
                    viewNewInvite model

                ItemDetailPage id ->
                    viewItemDetail id model
            ]
        , footer model
        ]


viewItemDetail : String -> Model -> Html Msg
viewItemDetail id model =
    let
        inav =
            Page.Home.Data.itemNav id model.homeModel
    in
    Html.map ItemDetailMsg (Page.ItemDetail.View.view inav model.uiSettings model.itemDetailModel)


viewNewInvite : Model -> Html Msg
viewNewInvite model =
    Html.map NewInviteMsg (Page.NewInvite.View.view model.flags model.newInviteModel)


viewUpload : Maybe String -> Model -> Html Msg
viewUpload mid model =
    Html.map UploadMsg (Page.Upload.View.view mid model.uploadModel)


viewRegister : Model -> Html Msg
viewRegister model =
    Html.map RegisterMsg (Page.Register.View.view model.flags model.registerModel)


viewQueue : Model -> Html Msg
viewQueue model =
    Html.map QueueMsg (Page.Queue.View.view model.queueModel)


viewUserSettings : Model -> Html Msg
viewUserSettings model =
    Html.map UserSettingsMsg (Page.UserSettings.View.view model.flags model.uiSettings model.userSettingsModel)


viewCollectiveSettings : Model -> Html Msg
viewCollectiveSettings model =
    Html.map CollSettingsMsg
        (Page.CollectiveSettings.View.view model.flags
            model.uiSettings
            model.collSettingsModel
        )


viewManageData : Model -> Html Msg
viewManageData model =
    Html.map ManageDataMsg
        (Page.ManageData.View.view model.flags
            model.uiSettings
            model.manageDataModel
        )


viewLogin : Model -> Html Msg
viewLogin model =
    Html.map LoginMsg (Page.Login.View.view model.flags model.loginModel)


viewHome : Model -> Html Msg
viewHome model =
    let
        mid =
            case model.page of
                HomePage ->
                    Util.Maybe.fromString model.itemDetailModel.detail.item.id

                _ ->
                    Nothing
    in
    Html.map HomeMsg (Page.Home.View.view mid model.flags model.uiSettings model.homeModel)


menuEntry : Model -> Page -> List (Html Msg) -> Html Msg
menuEntry model page children =
    a
        [ classList
            [ ( "icon item", True )
            , ( "active", model.page == page )
            ]
        , Page.href page
        ]
        children


loginInfo : Model -> Html Msg
loginInfo model =
    div [ class "right menu" ]
        (case model.flags.account of
            Just _ ->
                [ div
                    [ class "ui dropdown icon link item"
                    , onClick ToggleNavMenu
                    ]
                    [ i [ class "ui bars icon" ] []
                    , div
                        [ classList
                            [ ( "left menu", True )
                            , ( "transition visible", model.navMenuOpen )
                            ]
                        ]
                        [ menuEntry model
                            HomePage
                            [ img
                                [ class "image icon"
                                , src (model.flags.config.docspellAssetPath ++ "/img/logo-mc-96.png")
                                ]
                                []
                            , text "Items"
                            ]
                        , div [ class "divider" ] []
                        , menuEntry model
                            CollectiveSettingPage
                            [ i [ class "users circle icon" ] []
                            , text "Collective Profile"
                            ]
                        , menuEntry model
                            UserSettingPage
                            [ i [ class "user circle icon" ] []
                            , text "User Profile"
                            ]
                        , div [ class "divider" ] []
                        , menuEntry model
                            ManageDataPage
                            [ i [ class "cubes icon" ] []
                            , text "Manage Data"
                            ]
                        , div [ class "divider" ] []
                        , menuEntry model
                            (UploadPage Nothing)
                            [ i [ class "upload icon" ] []
                            , text "Upload files"
                            ]
                        , menuEntry model
                            QueuePage
                            [ i [ class "tachometer alternate icon" ] []
                            , text "Procesing Queue"
                            ]
                        , div
                            [ classList
                                [ ( "divider", True )
                                , ( "invisible", model.flags.config.signupMode /= "invite" )
                                ]
                            ]
                            []
                        , a
                            [ classList
                                [ ( "icon item", True )
                                , ( "invisible", model.flags.config.signupMode /= "invite" )
                                ]
                            , Page.href NewInvitePage
                            ]
                            [ i [ class "key icon" ] []
                            , text "New Invites"
                            ]
                        , div [ class "divider" ] []
                        , a
                            [ class "icon item"
                            , href "https://docspell.org/doc"
                            , target "_new"
                            , title "Opens https://docspell.org/doc"
                            ]
                            [ i [ class "help icon" ] []
                            , text "Help"
                            , span [ class "ui right floated" ]
                                [ i [ class "external link icon" ] []
                                ]
                            ]
                        , div [ class "divider" ] []
                        , a
                            [ class "icon item"
                            , href ""
                            , onClick Logout
                            ]
                            [ i [ class "sign-out icon" ] []
                            , text "Logout"
                            ]
                        ]
                    ]
                ]

            Nothing ->
                [ a
                    [ class "item"
                    , Page.href (Page.loginPage model.page)
                    ]
                    [ text "Login"
                    ]
                , a
                    [ class "item"
                    , Page.href RegisterPage
                    ]
                    [ text "Register"
                    ]
                ]
        )


footer : Model -> Html Msg
footer model =
    div [ class "ui footer" ]
        [ div [ class "ui center aligned container" ]
            [ a [ href "https://github.com/eikek/docspell" ]
                [ i [ class "ui github icon" ] []
                ]
            , span []
                [ text "Docspell "
                , text model.version.version
                , text " (#"
                , String.left 8 model.version.gitCommit |> text
                , text ")"
                ]
            ]
        ]
