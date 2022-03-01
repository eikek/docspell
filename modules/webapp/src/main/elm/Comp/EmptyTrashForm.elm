{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.EmptyTrashForm exposing
    ( Model
    , Msg
    , getSettings
    , init
    , update
    , view
    )

import Api.Model.EmptyTrashSetting exposing (EmptyTrashSetting)
import Comp.CalEventInput
import Comp.IntField
import Data.CalEvent exposing (CalEvent)
import Data.Flags exposing (Flags)
import Data.TimeZone exposing (TimeZone)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Comp.EmptyTrashForm exposing (Texts)
import Styles as S


type alias Model =
    { scheduleModel : Comp.CalEventInput.Model
    , schedule : Maybe CalEvent
    , minAgeModel : Comp.IntField.Model
    , minAgeDays : Maybe Int
    }


type Msg
    = ScheduleMsg Comp.CalEventInput.Msg
    | MinAgeMsg Comp.IntField.Msg


init : Flags -> EmptyTrashSetting -> ( Model, Cmd Msg )
init flags settings =
    let
        newSchedule =
            Data.CalEvent.fromEvent settings.schedule
                |> Maybe.withDefault Data.CalEvent.everyMonth

        ( cem, cec ) =
            Comp.CalEventInput.init flags newSchedule
    in
    ( { scheduleModel = cem
      , schedule = Just newSchedule
      , minAgeModel = Comp.IntField.init (Just 0) Nothing False
      , minAgeDays = Just <| millisToDays settings.minAge
      }
    , Cmd.map ScheduleMsg cec
    )


millisToDays : Int -> Int
millisToDays millis =
    round <| toFloat millis / 1000 / 60 / 60 / 24


daysToMillis : Int -> Int
daysToMillis days =
    days * 24 * 60 * 60 * 1000


getSettings : Model -> Maybe EmptyTrashSetting
getSettings model =
    Maybe.map2
        (\sch ->
            \age ->
                { schedule = Data.CalEvent.makeEvent sch
                , minAge = daysToMillis age
                }
        )
        model.schedule
        model.minAgeDays


update : Flags -> TimeZone -> Msg -> Model -> ( Model, Cmd Msg )
update flags tz msg model =
    case msg of
        ScheduleMsg lmsg ->
            let
                ( cm, cc, ce ) =
                    Comp.CalEventInput.update
                        flags
                        tz
                        model.schedule
                        lmsg
                        model.scheduleModel
            in
            ( { model
                | scheduleModel = cm
                , schedule = ce
              }
            , Cmd.map ScheduleMsg cc
            )

        MinAgeMsg lmsg ->
            let
                ( mm, newAge ) =
                    Comp.IntField.update lmsg model.minAgeModel
            in
            ( { model
                | minAgeModel = mm
                , minAgeDays = newAge
              }
            , Cmd.none
            )



--- View2


view : Texts -> UiSettings -> Model -> Html Msg
view texts _ model =
    div []
        [ div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text texts.schedule ]
            , Html.map ScheduleMsg
                (Comp.CalEventInput.view2
                    texts.calEventInput
                    ""
                    model.schedule
                    model.scheduleModel
                )
            ]
        , div [ class "mb-4" ]
            [ let
                settings : Comp.IntField.ViewSettings
                settings =
                    { number = model.minAgeDays
                    , label = texts.minAge
                    , classes = ""
                    , info = texts.minAgeInfo
                    }
              in
              Html.map MinAgeMsg (Comp.IntField.view settings model.minAgeModel)
            ]
        ]
