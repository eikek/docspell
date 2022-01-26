module Comp.DashboardView exposing (Model, Msg, init, view, viewBox)

import Comp.BoxView
import Data.Box exposing (Box)
import Data.Dashboard exposing (Dashboard)
import Data.Flags exposing (Flags)
import Dict exposing (Dict)
import Html exposing (Html, div)
import Html.Attributes exposing (class)


type alias Model =
    { dashboard : Dashboard
    , boxModels : List Comp.BoxView.Model
    }


type Msg
    = BoxMsg Comp.BoxView.Msg


init : Flags -> Dashboard -> ( Model, Cmd Msg )
init flags db =
    let
        ( boxModels, cmds ) =
            List.map (Comp.BoxView.init flags) db.boxes
                |> List.map (Tuple.mapSecond <| Cmd.map BoxMsg)
                |> List.unzip
    in
    ( { dashboard = db
      , boxModels = boxModels
      }
    , Cmd.batch cmds
    )



--- View


view : Model -> Html Msg
view model =
    div
        [ class (gridStyle model.dashboard)
        ]
        (List.map viewBox model.boxModels)


viewBox : Comp.BoxView.Model -> Html Msg
viewBox box =
    Html.map BoxMsg
        (Comp.BoxView.view box)



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
