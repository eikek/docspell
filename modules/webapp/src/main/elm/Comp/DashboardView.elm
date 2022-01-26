module Comp.DashboardView exposing (Model, Msg, init, reloadData, update, view, viewBox)

import Comp.BoxView
import Data.Dashboard exposing (Dashboard)
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Dict exposing (Dict)
import Html exposing (Html, div)
import Html.Attributes exposing (class)
import Messages.Comp.DashboardView exposing (Texts)
import Util.Update


type alias Model =
    { dashboard : Dashboard
    , boxModels : Dict Int Comp.BoxView.Model
    }


type Msg
    = BoxMsg Int Comp.BoxView.Msg
    | ReloadData


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


reloadData : Msg
reloadData =
    ReloadData



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update flags msg model =
    case msg of
        BoxMsg index lm ->
            case Dict.get index model.boxModels of
                Just bm ->
                    let
                        ( cm, cc, cs ) =
                            Comp.BoxView.update flags lm bm
                    in
                    ( { model | boxModels = Dict.insert index cm model.boxModels }
                    , Cmd.map (BoxMsg index) cc
                    , Sub.map (BoxMsg index) cs
                    )

                Nothing ->
                    unit model

        ReloadData ->
            let
                updateAll =
                    List.map (\index -> BoxMsg index Comp.BoxView.reloadData) (Dict.keys model.boxModels)
                        |> List.map (\m -> update flags m)
                        |> Util.Update.andThen2
            in
            updateAll model


unit : Model -> ( Model, Cmd Msg, Sub Msg )
unit model =
    ( model, Cmd.none, Sub.none )



--- View


view : Texts -> Flags -> UiSettings -> Model -> Html Msg
view texts flags settings model =
    div
        [ class (gridStyle model.dashboard)
        ]
        (List.indexedMap (viewBox texts flags settings) <| Dict.values model.boxModels)


viewBox : Texts -> Flags -> UiSettings -> Int -> Comp.BoxView.Model -> Html Msg
viewBox texts flags settings index box =
    Html.map (BoxMsg index)
        (Comp.BoxView.view texts.boxView flags settings box)



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
