module Page.UserSettings.View exposing (view)

import Comp.ChangePasswordForm
import Comp.EmailSettingsManage
import Comp.ImapSettingsManage
import Comp.NotificationForm
import Comp.ScanMailboxManage
import Comp.UiSettingsManage
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Page.UserSettings.Data exposing (..)
import Util.Html exposing (classActive)


view : UiSettings -> Model -> Html Msg
view settings model =
    div [ class "usersetting-page ui padded grid" ]
        [ div [ class "sixteen wide mobile four wide tablet four wide computer column" ]
            [ h4 [ class "ui top attached ablue-comp header" ]
                [ text "User Settings"
                ]
            , div [ class "ui attached fluid segment" ]
                [ div [ class "ui fluid vertical secondary menu" ]
                    [ makeTab model ChangePassTab "Change Password" "user secret icon"
                    , makeTab model EmailSettingsTab "E-Mail Settings (SMTP)" "mail icon"
                    , makeTab model ImapSettingsTab "E-Mail Settings (IMAP)" "mail icon"
                    , makeTab model NotificationTab "Notification Task" "bullhorn icon"
                    , makeTab model ScanMailboxTab "Scan Mailbox Task" "envelope open outline icon"
                    , makeTab model UiSettingsTab "UI Settings" "cog icon"
                    ]
                ]
            ]
        , div [ class "sixteen wide mobile twelve wide tablet twelve wide computer column" ]
            [ div [ class "" ]
                (case model.currentTab of
                    Just ChangePassTab ->
                        viewChangePassword model

                    Just EmailSettingsTab ->
                        viewEmailSettings settings model

                    Just NotificationTab ->
                        viewNotificationForm settings model

                    Just ImapSettingsTab ->
                        viewImapSettings settings model

                    Just ScanMailboxTab ->
                        viewScanMailboxManage settings model

                    Just UiSettingsTab ->
                        viewUiSettings settings model

                    Nothing ->
                        []
                )
            ]
        ]


makeTab : Model -> Tab -> String -> String -> Html Msg
makeTab model tab header icon =
    a
        [ classActive (model.currentTab == Just tab) "link icon item"
        , onClick (SetTab tab)
        , href "#"
        ]
        [ i [ class icon ] []
        , text header
        ]


viewUiSettings : UiSettings -> Model -> List (Html Msg)
viewUiSettings settings model =
    [ h2 [ class "ui header" ]
        [ i [ class "cog icon" ] []
        , text "UI Settings"
        ]
    , p []
        [ text "These settings only affect the web ui. They are stored in the browser, "
        , text "so they are separated between browsers and devices."
        ]
    , Html.map UiSettingsMsg
        (Comp.UiSettingsManage.view
            settings
            "ui segment"
            model.uiSettingsModel
        )
    ]


viewEmailSettings : UiSettings -> Model -> List (Html Msg)
viewEmailSettings settings model =
    [ h2 [ class "ui header" ]
        [ i [ class "mail icon" ] []
        , div [ class "content" ]
            [ text "E-Mail Settings (Smtp)"
            ]
        ]
    , Html.map EmailSettingsMsg (Comp.EmailSettingsManage.view settings model.emailSettingsModel)
    ]


viewImapSettings : UiSettings -> Model -> List (Html Msg)
viewImapSettings settings model =
    [ h2 [ class "ui header" ]
        [ i [ class "mail icon" ] []
        , div [ class "content" ]
            [ text "E-Mail Settings (Imap)"
            ]
        ]
    , Html.map ImapSettingsMsg (Comp.ImapSettingsManage.view settings model.imapSettingsModel)
    ]


viewChangePassword : Model -> List (Html Msg)
viewChangePassword model =
    [ h2 [ class "ui header" ]
        [ i [ class "ui user secret icon" ] []
        , div [ class "content" ]
            [ text "Change Password"
            ]
        ]
    , Html.map ChangePassMsg (Comp.ChangePasswordForm.view model.changePassModel)
    ]


viewNotificationForm : UiSettings -> Model -> List (Html Msg)
viewNotificationForm settings model =
    [ h2 [ class "ui header" ]
        [ i [ class "ui bullhorn icon" ] []
        , div [ class "content" ]
            [ text "Notification"
            ]
        ]
    , p []
        [ text """
            Docspell can notify you once the due dates of your items
            come closer. Notification is done via e-mail. You need to
            provide a connection in your e-mail settings."""
        ]
    , p []
        [ text "Docspell finds all items that are due in "
        , em [] [ text "Remind Days" ]
        , text " days and sends this list via e-mail."
        ]
    , Html.map NotificationMsg
        (Comp.NotificationForm.view "segment" settings model.notificationModel)
    ]


viewScanMailboxManage : UiSettings -> Model -> List (Html Msg)
viewScanMailboxManage settings model =
    [ h2 [ class "ui header" ]
        [ i [ class "ui envelope open outline icon" ] []
        , div [ class "content" ]
            [ text "Scan Mailbox"
            ]
        ]
    , p []
        [ text "Docspell can scan folders of your mailbox to import your mails. "
        , text "You need to provide a connection in "
        , text "your e-mail (imap) settings."
        ]
    , p []
        [ text """
            Docspell goes through all configured folders and imports
            mails matching the search criteria. Mails are skipped if
            they were imported in a previous run and the corresponding
            items still exist. After submitting a mail into docspell,
            you can choose to move it to another folder, to delete it
            or to just leave it there. In the latter case you should
            adjust the schedule to avoid reading over the same mails
            again."""
        ]
    , Html.map ScanMailboxMsg
        (Comp.ScanMailboxManage.view
            settings
            model.scanMailboxModel
        )
    ]
