module Comp.NotificationForm exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.EmailSettingsList exposing (EmailSettingsList)
import Api.Model.NotificationSettings exposing (NotificationSettings)
import Api.Model.Tag exposing (Tag)
import Api.Model.TagList exposing (TagList)
import Comp.CalEventInput
import Comp.Dropdown
import Comp.EmailInput
import Comp.IntField
import Data.CalEvent exposing (CalEvent)
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Data.Validated exposing (Validated(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick)
import Http
import Util.Http
import Util.Maybe
import Util.Tag
import Util.Update


type alias Model =
    { settings : NotificationSettings
    , connectionModel : Comp.Dropdown.Model String
    , tagInclModel : Comp.Dropdown.Model Tag
    , tagExclModel : Comp.Dropdown.Model Tag
    , recipients : List String
    , recipientsModel : Comp.EmailInput.Model
    , remindDays : Maybe Int
    , remindDaysModel : Comp.IntField.Model
    , capOverdue : Bool
    , enabled : Bool
    , schedule : Validated CalEvent
    , scheduleModel : Comp.CalEventInput.Model
    , formMsg : Maybe BasicResult
    , loading : Int
    }


type Msg
    = Submit
    | TagIncMsg (Comp.Dropdown.Msg Tag)
    | TagExcMsg (Comp.Dropdown.Msg Tag)
    | ConnMsg (Comp.Dropdown.Msg String)
    | ConnResp (Result Http.Error EmailSettingsList)
    | RecipientMsg Comp.EmailInput.Msg
    | GetTagsResp (Result Http.Error TagList)
    | RemindDaysMsg Comp.IntField.Msg
    | ToggleEnabled
    | ToggleCapOverdue
    | CalEventMsg Comp.CalEventInput.Msg
    | SetNotificationSettings (Result Http.Error NotificationSettings)
    | SubmitResp (Result Http.Error BasicResult)
    | StartOnce


initCmd : Flags -> Cmd Msg
initCmd flags =
    Cmd.batch
        [ Api.getMailSettings flags "" ConnResp
        , Api.getTags flags "" GetTagsResp
        , Api.getNotifyDueItems flags SetNotificationSettings
        ]


init : Flags -> UiSettings -> ( Model, Cmd Msg )
init flags settings =
    let
        initialSchedule =
            Data.Validated.Unknown Data.CalEvent.everyMonth

        ( sm, sc ) =
            Comp.CalEventInput.init flags Data.CalEvent.everyMonth
    in
    ( { settings = Api.Model.NotificationSettings.empty
      , connectionModel =
            Comp.Dropdown.makeSingle
                { makeOption = \a -> { value = a, text = a }
                , placeholder = "Select connection..."
                }
      , tagInclModel = Util.Tag.makeDropdownModel
      , tagExclModel = Util.Tag.makeDropdownModel
      , recipients = []
      , recipientsModel = Comp.EmailInput.init
      , remindDays = Just 1
      , remindDaysModel = Comp.IntField.init (Just 1) Nothing True "Remind Days"
      , enabled = False
      , capOverdue = False
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


makeSettings : Model -> Validated NotificationSettings
makeSettings model =
    let
        prev =
            model.settings

        conn =
            Comp.Dropdown.getSelected model.connectionModel
                |> List.head
                |> Maybe.map Valid
                |> Maybe.withDefault (Invalid [ "Connection missing" ] "")

        recp =
            if List.isEmpty model.recipients then
                Invalid [ "No recipients" ] []

            else
                Valid model.recipients

        rmdays =
            Maybe.map Valid model.remindDays
                |> Maybe.withDefault (Invalid [ "Remind Days is required" ] 0)

        make smtp rec days timer =
            { prev
                | smtpConnection = smtp
                , tagsInclude = Comp.Dropdown.getSelected model.tagInclModel
                , tagsExclude = Comp.Dropdown.getSelected model.tagExclModel
                , recipients = rec
                , remindDays = days
                , capOverdue = model.capOverdue
                , enabled = model.enabled
                , schedule = Data.CalEvent.makeEvent timer
            }
    in
    Data.Validated.map4 make
        conn
        recp
        rmdays
        model.schedule


withValidSettings : (NotificationSettings -> Cmd Msg) -> Model -> ( Model, Cmd Msg )
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

        RecipientMsg m ->
            let
                ( em, ec, rec ) =
                    Comp.EmailInput.update flags model.recipients m model.recipientsModel
            in
            ( { model
                | recipients = rec
                , recipientsModel = em
                , formMsg = Nothing
              }
            , Cmd.map RecipientMsg ec
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

        TagIncMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.tagInclModel
            in
            ( { model
                | tagInclModel = m2
                , formMsg = Nothing
              }
            , Cmd.map TagIncMsg c2
            )

        TagExcMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.tagExclModel
            in
            ( { model
                | tagExclModel = m2
                , formMsg = Nothing
              }
            , Cmd.map TagExcMsg c2
            )

        GetTagsResp (Ok tags) ->
            let
                tagList =
                    Comp.Dropdown.SetOptions tags.items
            in
            Util.Update.andThen1
                [ update flags (TagIncMsg tagList)
                , update flags (TagExcMsg tagList)
                ]
                { model | loading = model.loading - 1 }

        GetTagsResp (Err err) ->
            ( { model
                | loading = model.loading - 1
                , formMsg = Just (BasicResult False (Util.Http.errorToString err))
              }
            , Cmd.none
            )

        RemindDaysMsg m ->
            let
                ( pm, val ) =
                    Comp.IntField.update m model.remindDaysModel
            in
            ( { model
                | remindDaysModel = pm
                , remindDays = val
                , formMsg = Nothing
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

        ToggleCapOverdue ->
            ( { model
                | capOverdue = not model.capOverdue
                , formMsg = Nothing
              }
            , Cmd.none
            )

        SetNotificationSettings (Ok s) ->
            let
                smtp =
                    Util.Maybe.fromString s.smtpConnection
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []

                ( nm, nc ) =
                    Util.Update.andThen1
                        [ update flags (ConnMsg (Comp.Dropdown.SetSelection smtp))
                        , update flags (TagIncMsg (Comp.Dropdown.SetSelection s.tagsInclude))
                        , update flags (TagExcMsg (Comp.Dropdown.SetSelection s.tagsExclude))
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
                , recipients = s.recipients
                , remindDays = Just s.remindDays
                , enabled = s.enabled
                , capOverdue = s.capOverdue
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

        SetNotificationSettings (Err err) ->
            ( { model
                | formMsg = Just (BasicResult False (Util.Http.errorToString err))
                , loading = model.loading - 1
              }
            , Cmd.none
            )

        Submit ->
            withValidSettings
                (\set -> Api.submitNotifyDueItems flags set SubmitResp)
                model

        StartOnce ->
            withValidSettings
                (\set -> Api.startOnceNotifyDueItems flags set SubmitResp)
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


view : String -> UiSettings -> Model -> Html Msg
view extraClasses settings model =
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
        , div [ class "inline field" ]
            [ div [ class "ui checkbox" ]
                [ input
                    [ type_ "checkbox"
                    , onCheck (\_ -> ToggleEnabled)
                    , checked model.enabled
                    ]
                    []
                , label [] [ text "Enabled" ]
                ]
            , span [ class "small-info" ]
                [ text "Enable or disable this task."
                ]
            ]
        , div [ class "required field" ]
            [ label [] [ text "Send via" ]
            , Html.map ConnMsg (Comp.Dropdown.view settings model.connectionModel)
            , span [ class "small-info" ]
                [ text "The SMTP connection to use when sending notification mails."
                ]
            ]
        , div [ class "required field" ]
            [ label []
                [ text "Recipient(s)"
                ]
            , Html.map RecipientMsg
                (Comp.EmailInput.view model.recipients model.recipientsModel)
            , span [ class "small-info" ]
                [ text "One or more mail addresses, confirm each by pressing 'Return'."
                ]
            ]
        , div [ class "field" ]
            [ label [] [ text "Tags Include (and)" ]
            , Html.map TagIncMsg (Comp.Dropdown.view settings model.tagInclModel)
            , span [ class "small-info" ]
                [ text "Items must have all the tags specified here."
                ]
            ]
        , div [ class "field" ]
            [ label [] [ text "Tags Exclude (or)" ]
            , Html.map TagExcMsg (Comp.Dropdown.view settings model.tagExclModel)
            , span [ class "small-info" ]
                [ text "Items must not have any tag specified here."
                ]
            ]
        , Html.map RemindDaysMsg
            (Comp.IntField.viewWithInfo
                "Select items with a due date *lower than* `today+remindDays`"
                model.remindDays
                "required field"
                model.remindDaysModel
            )
        , div [ class "required inline field" ]
            [ div [ class "ui checkbox" ]
                [ input
                    [ type_ "checkbox"
                    , onCheck (\_ -> ToggleCapOverdue)
                    , checked model.capOverdue
                    ]
                    []
                , label []
                    [ text "Cap overdue items"
                    ]
                ]
            , div [ class "small-info" ]
                [ text "If checked, only items with a due date"
                , em [] [ text " greater than " ]
                , code [] [ text "today-remindDays" ]
                , text " are considered."
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
