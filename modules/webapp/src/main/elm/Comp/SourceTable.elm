module Comp.SourceTable exposing ( Model
                              , emptyModel
                              , Msg(..)
                              , view
                              , update)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Data.Flags exposing (Flags)
import Data.Priority exposing (Priority)
import Api.Model.Source exposing (Source)

type alias Model =
    { sources: List Source
    , selected: Maybe Source
    }

emptyModel: Model
emptyModel =
    { sources = []
    , selected = Nothing
    }

type Msg
    = SetSources (List Source)
    | Select Source
    | Deselect

update: Flags -> Msg -> Model -> (Model, Cmd Msg)
update flags msg model =
    case msg of
        SetSources list ->
            ({model | sources = list, selected = Nothing }, Cmd.none)

        Select source ->
            ({model | selected = Just source}, Cmd.none)

        Deselect ->
            ({model | selected = Nothing}, Cmd.none)


view: Model -> Html Msg
view model =
    table [class "ui selectable table"]
        [thead []
             [tr []
                  [th [class "collapsing"][text "Abbrev"]
                  ,th [class "collapsing"][text "Enabled"]
                  ,th [class "collapsing"][text "Counter"]
                  ,th [class "collapsing"][text "Priority"]
                  ,th [][text "Id"]
                  ]
             ]
        ,tbody []
            (List.map (renderSourceLine model) model.sources)
        ]

renderSourceLine: Model -> Source -> Html Msg
renderSourceLine model source =
    tr [classList [("active", model.selected == Just source)]
       ,onClick (Select source)
       ]
        [td [class "collapsing"]
             [text source.abbrev
             ]
        ,td [class "collapsing"]
            [if source.enabled then
                 i [class "check square outline icon"][]
             else
                 i [class "minus square outline icon"][]
            ]
        ,td [class "collapsing"]
            [source.counter |> String.fromInt |> text
            ]
        ,td [class "collapsing"]
            [Data.Priority.fromString source.priority
                 |> Maybe.map Data.Priority.toName
                 |> Maybe.withDefault source.priority
                 |> text
            ]
        ,td []
            [text source.id
            ]
        ]
