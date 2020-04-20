module Comp.NotificationForm exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Api
import Api.Model.EmailSettingsList exposing (EmailSettingsList)
import Api.Model.NotificationSettings exposing (NotificationSettings)
import Api.Model.Tag exposing (Tag)
import Api.Model.TagList exposing (TagList)
import Comp.CalEventInput
import Comp.Dropdown
import Comp.EmailInput
import Comp.IntField
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick)
import Http
import Util.Http
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
    , enabled : Bool
    , schedule : String
    , scheduleModel : Comp.CalEventInput.Model
    , formError : Maybe String
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
    | CalEventMsg Comp.CalEventInput.Msg


initCmd : Flags -> Cmd Msg
initCmd flags =
    Cmd.batch
        [ Api.getMailSettings flags "" ConnResp
        , Api.getTags flags "" GetTagsResp
        ]


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( sm, sc ) =
            Comp.CalEventInput.init flags
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
      , schedule = Comp.CalEventInput.initialSchedule
      , scheduleModel = sm
      , formError = Nothing
      }
    , Cmd.batch
        [ initCmd flags
        , Cmd.map CalEventMsg sc
        ]
    )


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        CalEventMsg lmsg ->
            let
                ( cm, cc, cs ) =
                    Comp.CalEventInput.update flags lmsg model.scheduleModel
            in
            ( { model
                | schedule = Maybe.withDefault model.schedule cs
                , scheduleModel = cm
              }
            , Cmd.map CalEventMsg cc
            )

        RecipientMsg m ->
            let
                ( em, ec, rec ) =
                    Comp.EmailInput.update flags model.recipients m model.recipientsModel
            in
            ( { model | recipients = rec, recipientsModel = em }
            , Cmd.map RecipientMsg ec
            )

        ConnMsg m ->
            let
                ( cm, _ ) =
                    -- dropdown doesn't use cmd!!
                    Comp.Dropdown.update m model.connectionModel
            in
            ( { model | connectionModel = cm }, Cmd.none )

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
                , formError =
                    if names == [] then
                        Just "No E-Mail connections configured. Goto user settings to add one."

                    else
                        Nothing
              }
            , Cmd.none
            )

        ConnResp (Err err) ->
            ( { model | formError = Just (Util.Http.errorToString err) }, Cmd.none )

        TagIncMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.tagInclModel
            in
            ( { model | tagInclModel = m2 }
            , Cmd.map TagIncMsg c2
            )

        TagExcMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.tagExclModel
            in
            ( { model | tagExclModel = m2 }
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
                model

        GetTagsResp (Err _) ->
            ( model, Cmd.none )

        RemindDaysMsg m ->
            let
                ( pm, val ) =
                    Comp.IntField.update m model.remindDaysModel
            in
            ( { model
                | remindDaysModel = pm
                , remindDays = val
              }
            , Cmd.none
            )

        ToggleEnabled ->
            ( { model | enabled = not model.enabled }, Cmd.none )

        _ ->
            ( model, Cmd.none )


view : String -> Model -> Html Msg
view extraClasses model =
    div
        [ classList
            [ ( "ui form", True )
            , ( extraClasses, True )
            , ( "error", model.formError /= Nothing )
            ]
        ]
        [ div [ class "inline field" ]
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
            , Html.map ConnMsg (Comp.Dropdown.view model.connectionModel)
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
            , Html.map TagIncMsg (Comp.Dropdown.view model.tagInclModel)
            , span [ class "small-info" ]
                [ text "Items must have all tags specified here."
                ]
            ]
        , div [ class "field" ]
            [ label [] [ text "Tags Exclude (or)" ]
            , Html.map TagExcMsg (Comp.Dropdown.view model.tagExclModel)
            , span [ class "small-info" ]
                [ text "Items must not have all tags specified here."
                ]
            ]
        , Html.map RemindDaysMsg
            (Comp.IntField.view model.remindDays
                "required field"
                model.remindDaysModel
            )
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
                (Comp.CalEventInput.view "" model.scheduleModel)
            , span [ class "small-info" ]
                [ text "Specify how often and when this task should run. "
                , text "Use English 3-letter weekdays. Either a single value, "
                , text "a list or a '*' (meaning all) is allowed for each part."
                ]
            ]
        , div [ class "ui divider" ] []
        , button
            [ class "ui primary button"
            , onClick Submit
            ]
            [ text "Submit"
            ]
        ]
