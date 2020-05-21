module Page.UserSettings.Update exposing (update)

import Comp.ChangePasswordForm
import Comp.EmailSettingsManage
import Comp.ImapSettingsManage
import Comp.NotificationForm
import Comp.ScanMailboxManage
import Data.Flags exposing (Flags)
import Page.UserSettings.Data exposing (..)


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        SetTab t ->
            let
                m =
                    { model | currentTab = Just t }

                ( m2, cmd ) =
                    case t of
                        EmailSettingsTab ->
                            let
                                ( em, c ) =
                                    Comp.EmailSettingsManage.init flags
                            in
                            ( { m | emailSettingsModel = em }, Cmd.map EmailSettingsMsg c )

                        ImapSettingsTab ->
                            let
                                ( em, c ) =
                                    Comp.ImapSettingsManage.init flags
                            in
                            ( { m | imapSettingsModel = em }, Cmd.map ImapSettingsMsg c )

                        ChangePassTab ->
                            ( m, Cmd.none )

                        NotificationTab ->
                            let
                                initCmd =
                                    Cmd.map NotificationMsg
                                        (Tuple.second (Comp.NotificationForm.init flags))
                            in
                            ( m, initCmd )

                        ScanMailboxTab ->
                            let
                                initCmd =
                                    Cmd.map ScanMailboxMsg
                                        (Tuple.second (Comp.ScanMailboxManage.init flags))
                            in
                            ( m, initCmd )
            in
            ( m2, cmd )

        ChangePassMsg m ->
            let
                ( m2, c2 ) =
                    Comp.ChangePasswordForm.update flags m model.changePassModel
            in
            ( { model | changePassModel = m2 }, Cmd.map ChangePassMsg c2 )

        EmailSettingsMsg m ->
            let
                ( m2, c2 ) =
                    Comp.EmailSettingsManage.update flags m model.emailSettingsModel
            in
            ( { model | emailSettingsModel = m2 }, Cmd.map EmailSettingsMsg c2 )

        ImapSettingsMsg m ->
            let
                ( m2, c2 ) =
                    Comp.ImapSettingsManage.update flags m model.imapSettingsModel
            in
            ( { model | imapSettingsModel = m2 }, Cmd.map ImapSettingsMsg c2 )

        NotificationMsg lm ->
            let
                ( m2, c2 ) =
                    Comp.NotificationForm.update flags lm model.notificationModel
            in
            ( { model | notificationModel = m2 }
            , Cmd.map NotificationMsg c2
            )

        ScanMailboxMsg lm ->
            let
                ( m2, c2 ) =
                    Comp.ScanMailboxManage.update flags lm model.scanMailboxModel
            in
            ( { model | scanMailboxModel = m2 }
            , Cmd.map ScanMailboxMsg c2
            )
