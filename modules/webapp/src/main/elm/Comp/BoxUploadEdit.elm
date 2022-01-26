module Comp.BoxUploadEdit exposing (..)

import Api
import Api.Model.Source exposing (Source)
import Api.Model.SourceList exposing (SourceList)
import Comp.BoxUploadView exposing (Msg)
import Comp.FixedDropdown
import Data.BoxContent exposing (UploadData)
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Html exposing (Html, div, label, text)
import Html.Attributes exposing (class)
import Http
import Messages.Comp.BoxUploadEdit exposing (Texts)
import Styles as S


type alias Model =
    { data : UploadData
    , allSources : List Source
    , sourceModel : Comp.FixedDropdown.Model Source
    }


type Msg
    = GetSourcesResp (Result Http.Error SourceList)
    | SourceMsg (Comp.FixedDropdown.Msg Source)


init : Flags -> UploadData -> ( Model, Cmd Msg )
init flags data =
    ( { data = data
      , allSources = []
      , sourceModel = Comp.FixedDropdown.init []
      }
    , Api.getSources flags GetSourcesResp
    )



--- Update


update : Msg -> Model -> ( Model, UploadData )
update msg model =
    case msg of
        GetSourcesResp (Ok list) ->
            let
                all =
                    List.map .source list.items
                        |> List.filter .enabled

                dm =
                    Comp.FixedDropdown.init all
            in
            ( { model | allSources = all, sourceModel = dm }
            , model.data
            )

        GetSourcesResp (Err _) ->
            ( model, model.data )

        SourceMsg lm ->
            let
                ( dm, sel ) =
                    Comp.FixedDropdown.update lm model.sourceModel

                ud =
                    model.data

                ud_ =
                    { ud | sourceId = Maybe.map .id sel }
            in
            ( { model | sourceModel = dm, data = ud_ }, ud_ )



--- View


view : Texts -> Model -> Html Msg
view texts model =
    let
        cfg =
            { display = \s -> s.abbrev
            , icon = \_ -> Nothing
            , selectPlaceholder = texts.sourcePlaceholder
            , style = DS.mainStyle
            }

        selected =
            List.filter (\e -> Just e.id == model.data.sourceId) model.allSources
                |> List.head
    in
    div []
        [ div []
            [ label [ class S.inputLabel ]
                [ text texts.sourceLabel
                ]
            , Html.map SourceMsg
                (Comp.FixedDropdown.viewStyled2 cfg False selected model.sourceModel)
            ]
        , div [ class "mt-1 opacity-75 text-sm" ]
            [ text texts.infoText
            ]
        ]
