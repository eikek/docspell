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
import Comp.Dropdown
import Comp.EmailInput
import Comp.IntField
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
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
    , timer : String
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
    | SetSchedule String


initCmd : Flags -> Cmd Msg
initCmd flags =
    Cmd.batch
        [ Api.getMailSettings flags "" ConnResp
        , Api.getTags flags "" GetTagsResp
        ]


init : Flags -> ( Model, Cmd Msg )
init flags =
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
      , timer = "*-*-1/7 12:00"
      , formError = Nothing
      }
    , initCmd flags
    )


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        SetSchedule str ->
            ( { model | timer = str }, Cmd.none )

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
            ]
        , div [ class "required field" ]
            [ label [] [ text "Send via" ]
            , Html.map ConnMsg (Comp.Dropdown.view model.connectionModel)
            ]
        , div [ class "required field" ]
            [ label []
                [ text "Recipient(s)"
                ]
            , Html.map RecipientMsg
                (Comp.EmailInput.view model.recipients model.recipientsModel)
            ]
        , div [ class "field" ]
            [ label [] [ text "Tags Include (and)" ]
            , Html.map TagIncMsg (Comp.Dropdown.view model.tagInclModel)
            ]
        , div [ class "field" ]
            [ label [] [ text "Tags Exclude (or)" ]
            , Html.map TagExcMsg (Comp.Dropdown.view model.tagExclModel)
            ]
        , Html.map RemindDaysMsg
            (Comp.IntField.view model.remindDays
                "required field"
                model.remindDaysModel
            )
        , div [ class "required field" ]
            [ label [] [ text "Schedule" ]
            , input
                [ type_ "text"
                , onInput SetSchedule
                , value model.timer
                ]
                []
            ]
        , div [ class "ui divider" ] []
        , button
            [ class "ui primary button"
            , onClick Submit
            ]
            [ text "Submit"
            ]
        ]
