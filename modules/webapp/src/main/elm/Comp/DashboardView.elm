module Comp.DashboardView exposing (Model, Msg, init, update, view, viewBox)

import Comp.BoxView
import Data.Box exposing (Box)
import Data.Dashboard exposing (Dashboard)
import Data.Flags exposing (Flags)
import Dict exposing (Dict)
import Html exposing (Html, div)
import Html.Attributes exposing (class)
import Messages.Comp.DashboardView exposing (Texts)


type alias Model =
    { dashboard : Dashboard
    , boxModels : Dict Int Comp.BoxView.Model
    }


type Msg
    = BoxMsg Int Comp.BoxView.Msg


init : Flags -> Dashboard -> ( Model, Cmd Msg )
init flags db =
    let
        ( boxModels, cmds ) =
            List.map (Comp.BoxView.init flags) db.boxes
                |> List.indexedMap (\a -> \( bm, bc ) -> ( bm, Cmd.map (BoxMsg a) bc ))
                |> List.unzip
    in
    ( { dashboard = db
      , boxModels =
            List.indexedMap Tuple.pair boxModels
                |> Dict.fromList
      }
    , Cmd.batch cmds
    )



--- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        BoxMsg index lm ->
            case Dict.get index model.boxModels of
                Just bm ->
                    let
                        ( cm, cc ) =
                            Comp.BoxView.update lm bm
                    in
                    ( { model | boxModels = Dict.insert index cm model.boxModels }
                    , Cmd.map (BoxMsg index) cc
                    )

                Nothing ->
                    unit model


unit : Model -> ( Model, Cmd Msg )
unit model =
    ( model, Cmd.none )



--- View


view : Texts -> Model -> Html Msg
view texts model =
    div
        [ class (gridStyle model.dashboard)
        ]
        (List.indexedMap (viewBox texts) <| Dict.values model.boxModels)


viewBox : Texts -> Int -> Comp.BoxView.Model -> Html Msg
viewBox texts index box =
    Html.map (BoxMsg index)
        (Comp.BoxView.view texts.boxView box)



--- Helpers


gridStyle : Dashboard -> String
gridStyle db =
    let
        colStyle =
            case db.columns of
                1 ->
                    ""

                2 ->
                    "md:grid-cols-2"

                3 ->
                    "md:grid-cols-3"

                4 ->
                    "md:grid-cols-4"

                _ ->
                    "md:grid-cols-5"
    in
    "grid gap-4 grid-cols-1 " ++ colStyle
