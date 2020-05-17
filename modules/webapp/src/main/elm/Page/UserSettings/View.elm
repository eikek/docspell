module Page.UserSettings.View exposing (view)

import Comp.ChangePasswordForm
import Comp.EmailSettingsManage
import Comp.NotificationForm
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
                [ text "User"
                ]
            , div [ class "ui attached fluid segment" ]
                [ div [ class "ui fluid vertical secondary menu" ]
                    [ makeTab model ChangePassTab "Change Password" "user secret icon"
                    , makeTab model EmailSettingsTab "E-Mail Settings" "mail icon"
                    , makeTab model NotificationTab "Notifications" "bullhorn icon"
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
            [ text "E-Mail Settings"
            ]
        ]
    , Html.map EmailSettingsMsg (Comp.EmailSettingsManage.view model.emailSettingsModel)
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
        [ text "Docspell can notify you once the due dates of your items come closer. "
        , text "Notification is done via e-mail. You need to provide a connection in "
        , text "your e-mail settings."
        ]
    , p []
        [ text "Each time this is executed, docspell finds all items that are due in "
        , em [] [ text "Remind Days" ]
        , text " days."
        ]
    , Html.map NotificationMsg
        (Comp.NotificationForm.view "segment" model.notificationModel)
    ]
