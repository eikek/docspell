module Comp.ScanMailboxForm exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.ImapSettingsList exposing (ImapSettingsList)
import Api.Model.ScanMailboxSettings exposing (ScanMailboxSettings)
import Api.Model.Tag exposing (Tag)
import Api.Model.TagList exposing (TagList)
import Comp.CalEventInput
import Comp.Dropdown
import Comp.EmailInput
import Comp.IntField
import Data.CalEvent exposing (CalEvent)
import Data.Flags exposing (Flags)
import Data.Validated exposing (Validated(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick)
import Http
import Util.Http
import Util.Maybe
import Util.Update


type alias Model =
    { settings : ScanMailboxSettings
    , connectionModel : Comp.Dropdown.Model String
    , enabled : Bool
    , schedule : Validated CalEvent
    , scheduleModel : Comp.CalEventInput.Model
    , formMsg : Maybe BasicResult
    , loading : Int
    }


type Msg
    = Submit
    | ConnMsg (Comp.Dropdown.Msg String)
    | ConnResp (Result Http.Error ImapSettingsList)
    | ToggleEnabled
    | CalEventMsg Comp.CalEventInput.Msg
    | SetScanMailboxSettings (Result Http.Error ScanMailboxSettings)
    | SubmitResp (Result Http.Error BasicResult)
    | StartOnce


initCmd : Flags -> Cmd Msg
initCmd flags =
    Cmd.batch
        [ Api.getImapSettings flags "" ConnResp
        , Api.getScanMailbox flags SetScanMailboxSettings
        ]


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        initialSchedule =
            Data.Validated.Unknown Data.CalEvent.everyMonth

        ( sm, sc ) =
            Comp.CalEventInput.init flags Data.CalEvent.everyMonth
    in
    ( { settings = Api.Model.ScanMailboxSettings.empty
      , connectionModel =
            Comp.Dropdown.makeSingle
                { makeOption = \a -> { value = a, text = a }
                , placeholder = "Select connection..."
                }
      , enabled = False
      , schedule = initialSchedule
      , scheduleModel = sm
      , formMsg = Nothing
      , loading = 3
      }
    , Cmd.batch
        [ initCmd flags
        , Cmd.map CalEventMsg sc
        ]
    )



--- Update


makeSettings : Model -> Validated ScanMailboxSettings
makeSettings model =
    let
        prev =
            model.settings

        conn =
            Comp.Dropdown.getSelected model.connectionModel
                |> List.head
                |> Maybe.map Valid
                |> Maybe.withDefault (Invalid [ "Connection missing" ] "")

        make smtp timer =
            { prev
                | imapConnection = smtp
                , enabled = model.enabled
                , schedule = Data.CalEvent.makeEvent timer
            }
    in
    Data.Validated.map2 make
        conn
        model.schedule


withValidSettings : (ScanMailboxSettings -> Cmd Msg) -> Model -> ( Model, Cmd Msg )
withValidSettings mkcmd model =
    case makeSettings model of
        Valid set ->
            ( { model | formMsg = Nothing }
            , mkcmd set
            )

        Invalid errs _ ->
            let
                errMsg =
                    String.join ", " errs
            in
            ( { model | formMsg = Just (BasicResult False errMsg) }, Cmd.none )

        Unknown _ ->
            ( { model | formMsg = Just (BasicResult False "An unknown error occured") }
            , Cmd.none
            )


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        CalEventMsg lmsg ->
            let
                ( cm, cc, cs ) =
                    Comp.CalEventInput.update flags
                        (Data.Validated.value model.schedule)
                        lmsg
                        model.scheduleModel
            in
            ( { model
                | schedule = cs
                , scheduleModel = cm
                , formMsg = Nothing
              }
            , Cmd.map CalEventMsg cc
            )

        ConnMsg m ->
            let
                ( cm, cc ) =
                    Comp.Dropdown.update m model.connectionModel
            in
            ( { model
                | connectionModel = cm
                , formMsg = Nothing
              }
            , Cmd.map ConnMsg cc
            )

        ConnResp (Ok list) ->
            let
                names =
                    List.map .name list.items

                cm =
                    Comp.Dropdown.makeSingleList
                        { makeOption = \a -> { value = a, text = a }
                        , placeholder = "Select Connection..."
                        , options = names
                        , selected = List.head names
                        }
            in
            ( { model
                | connectionModel = cm
                , loading = model.loading - 1
                , formMsg =
                    if names == [] then
                        Just
                            (BasicResult False
                                "No E-Mail connections configured. Goto E-Mail Settings to add one."
                            )

                    else
                        Nothing
              }
            , Cmd.none
            )

        ConnResp (Err err) ->
            ( { model
                | formMsg = Just (BasicResult False (Util.Http.errorToString err))
                , loading = model.loading - 1
              }
            , Cmd.none
            )

        ToggleEnabled ->
            ( { model
                | enabled = not model.enabled
                , formMsg = Nothing
              }
            , Cmd.none
            )

        SetScanMailboxSettings (Ok s) ->
            let
                imap =
                    Util.Maybe.fromString s.imapConnection
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []

                ( nm, nc ) =
                    Util.Update.andThen1
                        [ update flags (ConnMsg (Comp.Dropdown.SetSelection imap))
                        ]
                        model

                newSchedule =
                    Data.CalEvent.fromEvent s.schedule
                        |> Maybe.withDefault Data.CalEvent.everyMonth

                ( sm, sc ) =
                    Comp.CalEventInput.init flags newSchedule
            in
            ( { nm
                | settings = s
                , enabled = s.enabled
                , schedule = Data.Validated.Unknown newSchedule
                , scheduleModel = sm
                , formMsg = Nothing
                , loading = model.loading - 1
              }
            , Cmd.batch
                [ nc
                , Cmd.map CalEventMsg sc
                ]
            )

        SetScanMailboxSettings (Err err) ->
            ( { model
                | formMsg = Just (BasicResult False (Util.Http.errorToString err))
                , loading = model.loading - 1
              }
            , Cmd.none
            )

        Submit ->
            withValidSettings
                (\set -> Api.submitScanMailbox flags set SubmitResp)
                model

        StartOnce ->
            withValidSettings
                (\set -> Api.startOnceScanMailbox flags set SubmitResp)
                model

        SubmitResp (Ok res) ->
            ( { model | formMsg = Just res }
            , Cmd.none
            )

        SubmitResp (Err err) ->
            ( { model
                | formMsg = Just (BasicResult False (Util.Http.errorToString err))
              }
            , Cmd.none
            )



--- View


isFormError : Model -> Bool
isFormError model =
    Maybe.map .success model.formMsg
        |> Maybe.map not
        |> Maybe.withDefault False


isFormSuccess : Model -> Bool
isFormSuccess model =
    Maybe.map .success model.formMsg
        |> Maybe.withDefault False


view : String -> Model -> Html Msg
view extraClasses model =
    div
        [ classList
            [ ( "ui form", True )
            , ( extraClasses, True )
            , ( "error", isFormError model )
            , ( "success", isFormSuccess model )
            ]
        ]
        [ div
            [ classList
                [ ( "ui dimmer", True )
                , ( "active", model.loading > 0 )
                ]
            ]
            [ div [ class "ui text loader" ]
                [ text "Loading..."
                ]
            ]
        , div [ class "required field" ]
            [ label [] [ text "Send via" ]
            , Html.map ConnMsg (Comp.Dropdown.view model.connectionModel)
            , span [ class "small-info" ]
                [ text "The IMAP connection to use when sending notification mails."
                ]
            ]
        , div [ class "required field" ]
            [ label []
                [ text "Schedule"
                , a
                    [ class "right-float"
                    , href "https://github.com/eikek/calev#what-are-calendar-events"
                    , target "_blank"
                    ]
                    [ i [ class "help icon" ] []
                    , text "Click here for help"
                    ]
                ]
            , Html.map CalEventMsg
                (Comp.CalEventInput.view ""
                    (Data.Validated.value model.schedule)
                    model.scheduleModel
                )
            , span [ class "small-info" ]
                [ text "Specify how often and when this task should run. "
                , text "Use English 3-letter weekdays. Either a single value, "
                , text "a list (ex. 1,2,3), a range (ex. 1..3) or a '*' (meaning all) "
                , text "is allowed for each part."
                ]
            ]
        , div [ class "ui divider" ] []
        , div
            [ classList
                [ ( "ui message", True )
                , ( "success", isFormSuccess model )
                , ( "error", isFormError model )
                , ( "hidden", model.formMsg == Nothing )
                ]
            ]
            [ Maybe.map .message model.formMsg
                |> Maybe.withDefault ""
                |> text
            ]
        , button
            [ class "ui primary button"
            , onClick Submit
            ]
            [ text "Submit"
            ]
        , button
            [ class "ui right floated button"
            , onClick StartOnce
            ]
            [ text "Start Once"
            ]
        ]
