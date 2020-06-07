module Page.UserSettings.Update exposing (update)

import Comp.ChangePasswordForm
import Comp.EmailSettingsManage
import Comp.ImapSettingsManage
import Comp.NotificationForm
import Comp.ScanMailboxManage
import Comp.UiSettingsManage
import Data.Flags exposing (Flags)
import Page.UserSettings.Data exposing (..)


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update flags msg model =
    case msg of
        SetTab t ->
            let
                m =
                    { model | currentTab = Just t }
            in
            case t of
                EmailSettingsTab ->
                    let
                        ( em, c ) =
                            Comp.EmailSettingsManage.init flags
                    in
                    ( { m | emailSettingsModel = em }, Cmd.map EmailSettingsMsg c, Sub.none )

                ImapSettingsTab ->
                    let
                        ( em, c ) =
                            Comp.ImapSettingsManage.init flags
                    in
                    ( { m | imapSettingsModel = em }, Cmd.map ImapSettingsMsg c, Sub.none )

                ChangePassTab ->
                    ( m, Cmd.none, Sub.none )

                NotificationTab ->
                    let
                        initCmd =
                            Cmd.map NotificationMsg
                                (Tuple.second (Comp.NotificationForm.init flags))
                    in
                    ( m, initCmd, Sub.none )

                ScanMailboxTab ->
                    let
                        initCmd =
                            Cmd.map ScanMailboxMsg
                                (Tuple.second (Comp.ScanMailboxManage.init flags))
                    in
                    ( m, initCmd, Sub.none )

                UiSettingsTab ->
                    ( m, Cmd.none, Sub.none )

        ChangePassMsg m ->
            let
                ( m2, c2 ) =
                    Comp.ChangePasswordForm.update flags m model.changePassModel
            in
            ( { model | changePassModel = m2 }, Cmd.map ChangePassMsg c2, Sub.none )

        EmailSettingsMsg m ->
            let
                ( m2, c2 ) =
                    Comp.EmailSettingsManage.update flags m model.emailSettingsModel
            in
            ( { model | emailSettingsModel = m2 }, Cmd.map EmailSettingsMsg c2, Sub.none )

        ImapSettingsMsg m ->
            let
                ( m2, c2 ) =
                    Comp.ImapSettingsManage.update flags m model.imapSettingsModel
            in
            ( { model | imapSettingsModel = m2 }, Cmd.map ImapSettingsMsg c2, Sub.none )

        NotificationMsg lm ->
            let
                ( m2, c2 ) =
                    Comp.NotificationForm.update flags lm model.notificationModel
            in
            ( { model | notificationModel = m2 }
            , Cmd.map NotificationMsg c2
            , Sub.none
            )

        ScanMailboxMsg lm ->
            let
                ( m2, c2 ) =
                    Comp.ScanMailboxManage.update flags lm model.scanMailboxModel
            in
            ( { model | scanMailboxModel = m2 }
            , Cmd.map ScanMailboxMsg c2
            , Sub.none
            )

        GetUiSettings settings ->
            let
                ( um, uc ) =
                    Comp.UiSettingsManage.init flags settings
            in
            ( { model | uiSettingsModel = um }
            , Cmd.map UiSettingsMsg uc
            , Sub.none
            )

        UiSettingsMsg lm ->
            let
                ( m2, c2, s2 ) =
                    Comp.UiSettingsManage.update flags lm model.uiSettingsModel
            in
            ( { model | uiSettingsModel = m2 }
            , Cmd.map UiSettingsMsg c2
            , Sub.map UiSettingsMsg s2
            )
