module Comp.BoxStatsEdit exposing (..)

import Comp.BoxSearchQueryInput
import Comp.FixedDropdown
import Comp.MenuBar as MB
import Data.Bookmarks
import Data.BoxContent exposing (QueryData, SearchQuery(..), StatsData, SummaryShow(..))
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (Html, div, label, span, text)
import Html.Attributes exposing (class)
import Messages.Comp.BoxStatsEdit exposing (Texts)
import Styles as S


type alias Model =
    { data : StatsData
    , searchQueryModel : Comp.BoxSearchQueryInput.Model
    , showModel : Comp.FixedDropdown.Model SummaryShowLabel
    , summaryShow : SummaryShow
    }


type Msg
    = SearchQueryMsg Comp.BoxSearchQueryInput.Msg
    | ShowMsg (Comp.FixedDropdown.Msg SummaryShowLabel)
    | ToggleItemCountVisible


type SummaryShowLabel
    = ShowFields
    | ShowGeneric


init : Flags -> StatsData -> ( Model, Cmd Msg, Sub Msg )
init flags data =
    let
        ( qm, qc, qs ) =
            Comp.BoxSearchQueryInput.init flags data.query Data.Bookmarks.empty

        emptyModel =
            { data = data
            , searchQueryModel = qm
            , showModel =
                Comp.FixedDropdown.init
                    [ ShowFields, ShowGeneric ]
            , summaryShow = data.show
            }
    in
    ( emptyModel, Cmd.map SearchQueryMsg qc, Sub.map SearchQueryMsg qs )



--- Update


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    , data : StatsData
    }


update : Flags -> Msg -> Model -> UpdateResult
update flags msg model =
    case msg of
        SearchQueryMsg lm ->
            let
                result =
                    Comp.BoxSearchQueryInput.update flags lm model.searchQueryModel

                setData data =
                    { data | query = Maybe.withDefault data.query result.query }

                nextModel =
                    withData setData { model | searchQueryModel = result.model }
            in
            { model = nextModel
            , cmd = Cmd.map SearchQueryMsg result.cmd
            , sub = Sub.map SearchQueryMsg result.sub
            , data = nextModel.data
            }

        ShowMsg lm ->
            let
                ( mm, sel ) =
                    Comp.FixedDropdown.update lm model.showModel

                nextShow =
                    case ( model.summaryShow, sel ) of
                        ( SummaryShowFields _, Just ShowGeneric ) ->
                            SummaryShowGeneral

                        ( SummaryShowGeneral, Just ShowFields ) ->
                            SummaryShowFields False

                        _ ->
                            model.summaryShow

                data =
                    model.data

                data_ =
                    { data | show = nextShow }
            in
            unit { model | showModel = mm, summaryShow = nextShow, data = data_ }

        ToggleItemCountVisible ->
            let
                nextShow =
                    case model.summaryShow of
                        SummaryShowFields flag ->
                            SummaryShowFields (not flag)

                        _ ->
                            model.summaryShow

                data =
                    model.data

                data_ =
                    { data | show = nextShow }
            in
            unit { model | summaryShow = nextShow, data = data_ }


unit : Model -> UpdateResult
unit model =
    { model = model
    , cmd = Cmd.none
    , sub = Sub.none
    , data = model.data
    }


withData : (StatsData -> StatsData) -> Model -> Model
withData modify model =
    { model | data = modify model.data }



--- View


view : Texts -> UiSettings -> Model -> Html Msg
view texts settings model =
    let
        showSettings =
            { display =
                \a ->
                    case a of
                        ShowFields ->
                            texts.fieldStatistics

                        ShowGeneric ->
                            texts.basicNumbers
            , icon = \_ -> Nothing
            , selectPlaceholder = ""
            , style = DS.mainStyle
            }

        showLabel =
            case model.summaryShow of
                SummaryShowFields _ ->
                    ShowFields

                SummaryShowGeneral ->
                    ShowGeneric
    in
    div []
        [ Html.map SearchQueryMsg
            (Comp.BoxSearchQueryInput.view texts.searchQuery settings model.searchQueryModel)
        , div [ class "mt-2" ]
            [ label [ class S.inputLabel ]
                [ text texts.showLabel ]
            , Html.map ShowMsg
                (Comp.FixedDropdown.viewStyled2 showSettings False (Just showLabel) model.showModel)
            ]
        , div [ class "mt-2" ]
            [ case model.summaryShow of
                SummaryShowGeneral ->
                    span [ class "hidden" ] []

                SummaryShowFields itemCountVisible ->
                    MB.viewItem <|
                        MB.Checkbox
                            { tagger = \_ -> ToggleItemCountVisible
                            , label = texts.showItemCount
                            , id = ""
                            , value = itemCountVisible
                            }
            ]
        ]
