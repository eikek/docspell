module Page.UserSettings.View exposing (view)

import Comp.ChangePasswordForm
import Comp.EmailSettingsManage
import Comp.ImapSettingsManage
import Comp.NotificationForm
import Comp.ScanMailboxForm
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Page.UserSettings.Data exposing (..)
import Util.Html exposing (classActive)


view : Model -> Html Msg
view model =
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
                    ]
                ]
            ]
        , div [ class "sixteen wide mobile twelve wide tablet twelve wide computer column" ]
            [ div [ class "" ]
                (case model.currentTab of
                    Just ChangePassTab ->
                        viewChangePassword model

                    Just EmailSettingsTab ->
                        viewEmailSettings model

                    Just NotificationTab ->
                        viewNotificationForm model

                    Just ImapSettingsTab ->
                        viewImapSettings model

                    Just ScanMailboxTab ->
                        viewScanMailboxForm model

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


viewEmailSettings : Model -> List (Html Msg)
viewEmailSettings model =
    [ h2 [ class "ui header" ]
        [ i [ class "mail icon" ] []
        , div [ class "content" ]
            [ text "E-Mail Settings (Smtp)"
            ]
        ]
    , Html.map EmailSettingsMsg (Comp.EmailSettingsManage.view model.emailSettingsModel)
    ]


viewImapSettings : Model -> List (Html Msg)
viewImapSettings model =
    [ h2 [ class "ui header" ]
        [ i [ class "mail icon" ] []
        , div [ class "content" ]
            [ text "E-Mail Settings (Imap)"
            ]
        ]
    , Html.map ImapSettingsMsg (Comp.ImapSettingsManage.view model.imapSettingsModel)
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


viewNotificationForm : Model -> List (Html Msg)
viewNotificationForm model =
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
        (Comp.NotificationForm.view "segment" model.notificationModel)
    ]


viewScanMailboxForm : Model -> List (Html Msg)
viewScanMailboxForm model =
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
        (Comp.ScanMailboxForm.view "segment" model.scanMailboxModel)
    ]
