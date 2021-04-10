module Comp.ClassifierSettingsForm exposing
    ( Model
    , Msg
    , getSettings
    , init
    , update
    , view2
    )

import Api
import Api.Model.ClassifierSetting exposing (ClassifierSetting)
import Api.Model.TagList exposing (TagList)
import Comp.CalEventInput
import Comp.Dropdown
import Comp.FixedDropdown
import Comp.IntField
import Data.CalEvent exposing (CalEvent)
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Data.ListType exposing (ListType)
import Data.UiSettings exposing (UiSettings)
import Data.Validated exposing (Validated(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Markdown
import Messages.Comp.ClassifierSettingsForm exposing (Texts)
import Styles as S
import Util.Tag


type alias Model =
    { scheduleModel : Comp.CalEventInput.Model
    , schedule : Validated CalEvent
    , itemCountModel : Comp.IntField.Model
    , itemCount : Maybe Int
    , categoryListModel : Comp.Dropdown.Model String
    , categoryListType : ListType
    , categoryListTypeModel : Comp.FixedDropdown.Model ListType
    }


type Msg
    = ScheduleMsg Comp.CalEventInput.Msg
    | ItemCountMsg Comp.IntField.Msg
    | GetTagsResp (Result Http.Error TagList)
    | CategoryListMsg (Comp.Dropdown.Msg String)
    | CategoryListTypeMsg (Comp.FixedDropdown.Msg ListType)


init : Flags -> ClassifierSetting -> ( Model, Cmd Msg )
init flags sett =
    let
        newSchedule =
            Data.CalEvent.fromEvent sett.schedule
                |> Maybe.withDefault Data.CalEvent.everyMonth

        ( cem, cec ) =
            Comp.CalEventInput.init flags newSchedule
    in
    ( { scheduleModel = cem
      , schedule = Data.Validated.Unknown newSchedule
      , itemCountModel = Comp.IntField.init (Just 0) Nothing True
      , itemCount = Just sett.itemCount
      , categoryListModel =
            let
                minit =
                    Comp.Dropdown.makeModel
                        { multiple = True
                        , searchable = \n -> n > 0
                        }

                lm =
                    Comp.Dropdown.SetSelection sett.categoryList

                ( m_, _ ) =
                    Comp.Dropdown.update lm minit
            in
            m_
      , categoryListType =
            Data.ListType.fromString sett.listType
                |> Maybe.withDefault Data.ListType.Whitelist
      , categoryListTypeModel =
            Comp.FixedDropdown.init Data.ListType.all
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
            { schedule =
                Data.CalEvent.makeEvent sch
            , itemCount = Maybe.withDefault 0 model.itemCount
            , listType = Data.ListType.toString model.categoryListType
            , categoryList = Comp.Dropdown.getSelected model.categoryListModel
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

                lm =
                    Comp.Dropdown.SetOptions categories
            in
            update flags (CategoryListMsg lm) model

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

        CategoryListMsg lm ->
            let
                ( m_, cmd_ ) =
                    Comp.Dropdown.update lm model.categoryListModel
            in
            ( { model | categoryListModel = m_ }
            , Cmd.map CategoryListMsg cmd_
            )

        CategoryListTypeMsg lm ->
            let
                ( m_, sel ) =
                    Comp.FixedDropdown.update lm model.categoryListTypeModel

                newListType =
                    Maybe.withDefault model.categoryListType sel
            in
            ( { model
                | categoryListTypeModel = m_
                , categoryListType = newListType
              }
            , Cmd.none
            )



--- View2


view2 : Texts -> UiSettings -> Model -> Html Msg
view2 texts settings model =
    let
        categoryCfg =
            { makeOption = \s -> { text = s, additional = "" }
            , labelColor = \_ -> \_ -> "grey "
            , placeholder = "Choose categories …"
            , style = DS.mainStyle
            }

        catListCfg =
            { display = Data.ListType.label
            , icon = \_ -> Nothing
            , style = DS.mainStyle
            }
    in
    div []
        [ Markdown.toHtml [ class "px-2 py-2 opacity-75" ]
            texts.autoTaggingText
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text texts.blacklistOrWhitelist ]
            , Html.map CategoryListTypeMsg
                (Comp.FixedDropdown.viewStyled2 catListCfg
                    False
                    (Just model.categoryListType)
                    model.categoryListTypeModel
                )
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ case model.categoryListType of
                    Data.ListType.Whitelist ->
                        text texts.whitelistLabel

                    Data.ListType.Blacklist ->
                        text texts.blacklistLabel
                ]
            , Html.map CategoryListMsg
                (Comp.Dropdown.view2
                    categoryCfg
                    settings
                    model.categoryListModel
                )
            ]
        , Html.map ItemCountMsg
            (Comp.IntField.view
                { label = texts.itemCount
                , info = texts.itemCountHelp
                , classes = "mb-4"
                , number = model.itemCount
                }
                model.itemCountModel
            )
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text texts.schedule ]
            , Html.map ScheduleMsg
                (Comp.CalEventInput.view2
                    texts.calEventInput
                    ""
                    (Data.Validated.value model.schedule)
                    model.scheduleModel
                )
            ]
        ]
