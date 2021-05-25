module Page.UserSettings.Update exposing (update)

import Comp.ChangePasswordForm
import Comp.EmailSettingsManage
import Comp.ImapSettingsManage
import Comp.NotificationManage
import Comp.ScanMailboxManage
import Comp.UiSettingsManage
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Page.UserSettings.Data exposing (..)


update : Flags -> UiSettings -> Msg -> Model -> ( Model, Cmd Msg, Maybe UiSettings )
update flags settings msg model =
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
                    ( { m | emailSettingsModel = em }
                    , Cmd.map EmailSettingsMsg c
                    , Nothing
                    )

                ImapSettingsTab ->
                    let
                        ( em, c ) =
                            Comp.ImapSettingsManage.init flags
                    in
                    ( { m | imapSettingsModel = em }
                    , Cmd.map ImapSettingsMsg c
                    , Nothing
                    )

                ChangePassTab ->
                    ( m, Cmd.none, Nothing )

                NotificationTab ->
                    let
                        initCmd =
                            Cmd.map NotificationMsg
                                (Tuple.second (Comp.NotificationManage.init flags))
                    in
                    ( m, initCmd, Nothing )

                ScanMailboxTab ->
                    let
                        initCmd =
                            Cmd.map ScanMailboxMsg
                                (Tuple.second (Comp.ScanMailboxManage.init flags))
                    in
                    ( m, initCmd, Nothing )

                UiSettingsTab ->
                    ( m, Cmd.none, Nothing )

        ChangePassMsg m ->
            let
                ( m2, c2 ) =
                    Comp.ChangePasswordForm.update flags m model.changePassModel
            in
            ( { model | changePassModel = m2 }
            , Cmd.map ChangePassMsg c2
            , Nothing
            )

        EmailSettingsMsg m ->
            let
                ( m2, c2 ) =
                    Comp.EmailSettingsManage.update flags m model.emailSettingsModel
            in
            ( { model | emailSettingsModel = m2 }
            , Cmd.map EmailSettingsMsg c2
            , Nothing
            )

        ImapSettingsMsg m ->
            let
                ( m2, c2 ) =
                    Comp.ImapSettingsManage.update flags m model.imapSettingsModel
            in
            ( { model | imapSettingsModel = m2 }
            , Cmd.map ImapSettingsMsg c2
            , Nothing
            )

        NotificationMsg lm ->
            let
                ( m2, c2 ) =
                    Comp.NotificationManage.update flags lm model.notificationModel
            in
            ( { model | notificationModel = m2 }
            , Cmd.map NotificationMsg c2
            , Nothing
            )

        ScanMailboxMsg lm ->
            let
                ( m2, c2 ) =
                    Comp.ScanMailboxManage.update flags lm model.scanMailboxModel
            in
            ( { model | scanMailboxModel = m2 }
            , Cmd.map ScanMailboxMsg c2
            , Nothing
            )

        UiSettingsMsg lm ->
            let
                res =
                    Comp.UiSettingsManage.update flags settings lm model.uiSettingsModel
            in
            ( { model | uiSettingsModel = res.model }
            , Cmd.map UiSettingsMsg res.cmd
            , res.newSettings
            )

        UpdateSettings ->
            update flags
                settings
                (UiSettingsMsg Comp.UiSettingsManage.UpdateSettings)
                model
