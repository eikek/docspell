module Comp.UiSettingsForm exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Api
import Api.Model.TagList exposing (TagList)
import Comp.IntField
import Comp.MappingForm
import Data.Color
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (StoredUiSettings, UiSettings)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Util.List


type alias Model =
    { defaults : UiSettings
    , input : StoredUiSettings
    , searchPageSizeModel : Comp.IntField.Model
    , tagColorModel : Comp.MappingForm.Model
    , tagColors : Dict String String
    }


init : Flags -> UiSettings -> ( Model, Cmd Msg )
init flags defaults =
    ( { defaults = defaults
      , input = Data.UiSettings.toStoredUiSettings defaults
      , searchPageSizeModel =
            Comp.IntField.init
                (Just 10)
                (Just 500)
                False
                "Item search page"
      , tagColorModel =
            Comp.MappingForm.init
                []
                Data.Color.allString
      , tagColors = Dict.empty
      }
    , Api.getTags flags "" GetTagsResp
    )


changeInput : (StoredUiSettings -> StoredUiSettings) -> Model -> StoredUiSettings
changeInput change model =
    change model.input


type Msg
    = SearchPageSizeMsg Comp.IntField.Msg
    | TagColorMsg Comp.MappingForm.Msg
    | GetTagsResp (Result Http.Error TagList)


getSettings : Model -> UiSettings
getSettings model =
    Data.UiSettings.merge model.input model.defaults



--- Update


update : Msg -> Model -> ( Model, Maybe UiSettings )
update msg model =
    case msg of
        SearchPageSizeMsg lm ->
            let
                ( m, n ) =
                    Comp.IntField.update lm model.searchPageSizeModel

                model_ =
                    { model
                        | searchPageSizeModel = m
                        , input = changeInput (\s -> { s | itemSearchPageSize = n }) model
                    }

                nextSettings =
                    Maybe.map (\_ -> getSettings model_) n
            in
            ( model_, nextSettings )

        TagColorMsg lm ->
            let
                ( m_, d_ ) =
                    Comp.MappingForm.update lm model.tagColorModel
            in
            ( { model
                | tagColorModel = m_
                , tagColors = Maybe.withDefault model.tagColors d_
              }
            , Nothing
            )

        GetTagsResp (Ok tl) ->
            let
                categories =
                    List.filterMap .category tl.items
                        |> Util.List.distinct
            in
            ( { model
                | tagColorModel =
                    Comp.MappingForm.init
                        categories
                        Data.Color.allString
                , tagColors = Dict.empty
              }
            , Nothing
            )

        GetTagsResp (Err _) ->
            ( model, Nothing )



--- View


tagColorViewOpts : Comp.MappingForm.ViewOpts
tagColorViewOpts =
    { renderItem =
        \( k, v ) ->
            span [ class ("ui label " ++ v) ]
                [ text k ]
    , label = "Choose color for tag categories"
    , description = Just "Tags can be represented differently based on their category."
    }


view : Model -> Html Msg
view model =
    div [ class "ui form" ]
        [ Html.map SearchPageSizeMsg
            (Comp.IntField.viewWithInfo
                "Maximum results in one page when searching items."
                model.input.itemSearchPageSize
                "field"
                model.searchPageSizeModel
            )
        , Html.map TagColorMsg
            (Comp.MappingForm.view
                model.tagColors
                tagColorViewOpts
                model.tagColorModel
            )
        ]
