{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Comp.EmptyTrashForm exposing
    ( Model
    , Msg
    , getSettings
    , init
    , update
    , view
    )

import Api
import Comp.CalEventInput
import Comp.Dropdown
import Comp.FixedDropdown
import Comp.IntField
import Data.CalEvent exposing (CalEvent)
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Data.ListType exposing (ListType)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Markdown
import Messages.Comp.EmptyTrashForm exposing (Texts)
import Styles as S
import Util.Tag


type alias Model =
    { scheduleModel : Comp.CalEventInput.Model
    , schedule : Maybe CalEvent
    }


type Msg
    = ScheduleMsg Comp.CalEventInput.Msg


init : Flags -> String -> ( Model, Cmd Msg )
init flags schedule =
    let
        newSchedule =
            Data.CalEvent.fromEvent schedule
                |> Maybe.withDefault Data.CalEvent.everyMonth

        ( cem, cec ) =
            Comp.CalEventInput.init flags newSchedule
    in
    ( { scheduleModel = cem
      , schedule = Just newSchedule
      }
    , Cmd.map ScheduleMsg cec
    )


getSettings : Model -> Maybe CalEvent
getSettings model =
    model.schedule


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        ScheduleMsg lmsg ->
            let
                ( cm, cc, ce ) =
                    Comp.CalEventInput.update
                        flags
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
        ]
