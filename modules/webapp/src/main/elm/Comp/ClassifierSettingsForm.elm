module Comp.ClassifierSettingsForm exposing
    ( Model
    , Msg
    , getSettings
    , init
    , update
    , view
    )

import Api
import Api.Model.ClassifierSetting exposing (ClassifierSetting)
import Api.Model.TagList exposing (TagList)
import Comp.CalEventInput
import Comp.FixedDropdown
import Comp.IntField
import Data.CalEvent exposing (CalEvent)
import Data.Flags exposing (Flags)
import Data.Validated exposing (Validated(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck)
import Http
import Util.Tag


type alias Model =
    { enabled : Bool
    , categoryModel : Comp.FixedDropdown.Model String
    , category : Maybe String
    , scheduleModel : Comp.CalEventInput.Model
    , schedule : Validated CalEvent
    , itemCountModel : Comp.IntField.Model
    , itemCount : Maybe Int
    }


type Msg
    = GetTagsResp (Result Http.Error TagList)
    | ScheduleMsg Comp.CalEventInput.Msg
    | ToggleEnabled
    | CategoryMsg (Comp.FixedDropdown.Msg String)
    | ItemCountMsg Comp.IntField.Msg


init : Flags -> ClassifierSetting -> ( Model, Cmd Msg )
init flags sett =
    let
        newSchedule =
            Data.CalEvent.fromEvent sett.schedule
                |> Maybe.withDefault Data.CalEvent.everyMonth

        ( cem, cec ) =
            Comp.CalEventInput.init flags newSchedule
    in
    ( { enabled = sett.enabled
      , categoryModel = Comp.FixedDropdown.initString []
      , category = sett.category
      , scheduleModel = cem
      , schedule = Data.Validated.Unknown newSchedule
      , itemCountModel = Comp.IntField.init (Just 0) Nothing True "Item Count"
      , itemCount = Just sett.itemCount
      }
    , Cmd.batch
        [ Api.getTags flags "" GetTagsResp
        , Cmd.map ScheduleMsg cec
        ]
    )


getSettings : Model -> Validated ClassifierSetting
getSettings model =
    Data.Validated.map
        (\sch ->
            { enabled = model.enabled
            , category = model.category
            , schedule =
                Data.CalEvent.makeEvent sch
            , itemCount = Maybe.withDefault 0 model.itemCount
            }
        )
        model.schedule


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        GetTagsResp (Ok tl) ->
            let
                categories =
                    Util.Tag.getCategories tl.items
                        |> List.sort
            in
            ( { model
                | categoryModel = Comp.FixedDropdown.initString categories
                , category =
                    if model.category == Nothing then
                        List.head categories

                    else
                        model.category
              }
            , Cmd.none
            )

        GetTagsResp (Err _) ->
            ( model, Cmd.none )

        ScheduleMsg lmsg ->
            let
                ( cm, cc, ce ) =
                    Comp.CalEventInput.update
                        flags
                        (Data.Validated.value model.schedule)
                        lmsg
                        model.scheduleModel
            in
            ( { model
                | scheduleModel = cm
                , schedule = ce
              }
            , Cmd.map ScheduleMsg cc
            )

        ToggleEnabled ->
            ( { model | enabled = not model.enabled }
            , Cmd.none
            )

        CategoryMsg lmsg ->
            let
                ( mm, ma ) =
                    Comp.FixedDropdown.update lmsg model.categoryModel
            in
            ( { model
                | categoryModel = mm
                , category =
                    if ma == Nothing then
                        model.category

                    else
                        ma
              }
            , Cmd.none
            )

        ItemCountMsg lmsg ->
            let
                ( im, iv ) =
                    Comp.IntField.update lmsg model.itemCountModel
            in
            ( { model
                | itemCountModel = im
                , itemCount = iv
              }
            , Cmd.none
            )


view : Model -> Html Msg
view model =
    div []
        [ div
            [ class "field"
            ]
            [ div [ class "ui checkbox" ]
                [ input
                    [ type_ "checkbox"
                    , onCheck (\_ -> ToggleEnabled)
                    , checked model.enabled
                    ]
                    []
                , label [] [ text "Enable classification" ]
                , span [ class "small-info" ]
                    [ text "Disable document classification if not needed."
                    ]
                ]
            ]
        , div [ class "ui basic segment" ]
            [ text "Document classification tries to predict a tag for new incoming documents. This "
            , text "works by learning from existing documents in order to find common patterns within "
            , text "the text. The more documents you have correctly tagged, the better. Learning is done "
            , text "periodically based on a schedule and you need to specify a tag-group that should "
            , text "be used for learning."
            ]
        , div [ class "field" ]
            [ label [] [ text "Category" ]
            , Html.map CategoryMsg
                (Comp.FixedDropdown.viewString model.category
                    model.categoryModel
                )
            ]
        , Html.map ItemCountMsg
            (Comp.IntField.viewWithInfo
                "The maximum number of items to learn from, order by date newest first. Use 0 to mean all."
                model.itemCount
                "field"
                model.itemCountModel
            )
        , div [ class "field" ]
            [ label [] [ text "Schedule" ]
            , Html.map ScheduleMsg
                (Comp.CalEventInput.view "" (Data.Validated.value model.schedule) model.scheduleModel)
            ]
        ]
