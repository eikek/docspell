module Comp.UiSettingsForm exposing
    ( Model
    , Msg
    , init
    , initWith
    , update
    , view
    )

import Comp.IntField
import Data.UiSettings exposing (StoredUiSettings, UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)


type alias Model =
    { defaults : UiSettings
    , input : StoredUiSettings
    , searchPageSizeModel : Comp.IntField.Model
    }


initWith : UiSettings -> Model
initWith defaults =
    { defaults = defaults
    , input = Data.UiSettings.toStoredUiSettings defaults
    , searchPageSizeModel =
        Comp.IntField.init
            (Just 10)
            (Just 500)
            False
            "Item search page"
    }


init : Model
init =
    initWith Data.UiSettings.defaults


changeInput : (StoredUiSettings -> StoredUiSettings) -> Model -> StoredUiSettings
changeInput change model =
    change model.input


type Msg
    = SearchPageSizeMsg Comp.IntField.Msg


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



--- View


view : Model -> Html Msg
view model =
    div [ class "ui form" ]
        [ Html.map SearchPageSizeMsg
            (Comp.IntField.viewWithInfo
                "Maximum results in one page when searching items."
                model.input.itemSearchPageSize
                ""
                model.searchPageSizeModel
            )
        ]
