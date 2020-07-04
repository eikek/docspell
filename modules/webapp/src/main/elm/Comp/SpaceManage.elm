module Comp.SpaceManage exposing
    ( Model
    , Msg
    , empty
    , init
    , update
    , view
    )

import Api
import Api.Model.SpaceDetail exposing (SpaceDetail)
import Api.Model.SpaceItem exposing (SpaceItem)
import Api.Model.SpaceList exposing (SpaceList)
import Api.Model.User exposing (User)
import Api.Model.UserList exposing (UserList)
import Comp.SpaceDetail
import Comp.SpaceTable
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http


type alias Model =
    { tableModel : Comp.SpaceTable.Model
    , detailModel : Maybe Comp.SpaceDetail.Model
    , spaces : List SpaceItem
    , users : List User
    , query : String
    , loading : Bool
    }


type Msg
    = TableMsg Comp.SpaceTable.Msg
    | DetailMsg Comp.SpaceDetail.Msg
    | UserListResp (Result Http.Error UserList)
    | SpaceListResp (Result Http.Error SpaceList)
    | SpaceDetailResp (Result Http.Error SpaceDetail)
    | SetQuery String
    | InitNewSpace


empty : Model
empty =
    { tableModel = Comp.SpaceTable.init
    , detailModel = Nothing
    , spaces = []
    , users = []
    , query = ""
    , loading = False
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( empty
    , Cmd.batch
        [ Api.getUsers flags UserListResp
        , Api.getSpaces flags SpaceListResp
        ]
    )



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    ( model, Cmd.none )



--- View


view : Model -> Html Msg
view model =
    div []
        [ div [ class "ui secondary menu" ]
            [ div [ class "horizontally fitted item" ]
                [ div [ class "ui icon input" ]
                    [ input
                        [ type_ "text"
                        , onInput SetQuery
                        , value model.query
                        , placeholder "Search…"
                        ]
                        []
                    , i [ class "ui search icon" ]
                        []
                    ]
                ]
            , div [ class "right menu" ]
                [ div [ class "item" ]
                    [ a
                        [ class "ui primary button"
                        , href "#"
                        , onClick InitNewSpace
                        ]
                        [ i [ class "plus icon" ] []
                        , text "New Space"
                        ]
                    ]
                ]
            ]
        , Html.map TableMsg (Comp.SpaceTable.view model.tableModel model.spaces)
        , div
            [ classList
                [ ( "ui dimmer", True )
                , ( "active", model.loading )
                ]
            ]
            [ div [ class "ui loader" ] []
            ]
        ]
