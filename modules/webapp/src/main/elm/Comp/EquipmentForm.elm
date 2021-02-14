module Comp.EquipmentForm exposing
    ( Model
    , Msg(..)
    , emptyModel
    , getEquipment
    , isValid
    , update
    , view
    , view2
    )

import Api.Model.Equipment exposing (Equipment)
import Comp.Basic as B
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Styles as S


type alias Model =
    { equipment : Equipment
    , name : String
    }


emptyModel : Model
emptyModel =
    { equipment = Api.Model.Equipment.empty
    , name = ""
    }


isValid : Model -> Bool
isValid model =
    model.name /= ""


getEquipment : Model -> Equipment
getEquipment model =
    Equipment model.equipment.id model.name model.equipment.created


type Msg
    = SetName String
    | SetEquipment Equipment


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        SetEquipment t ->
            ( { model | equipment = t, name = t.name }, Cmd.none )

        SetName n ->
            ( { model | name = n }, Cmd.none )


view : Model -> Html Msg
view model =
    div [ class "ui form" ]
        [ div
            [ classList
                [ ( "field", True )
                , ( "error", not (isValid model) )
                ]
            ]
            [ label [] [ text "Name*" ]
            , input
                [ type_ "text"
                , onInput SetName
                , placeholder "Name"
                , value model.name
                ]
                []
            ]
        ]



--- View2


view2 : Model -> Html Msg
view2 model =
    div [ class "flex flex-col" ]
        [ div
            [ class "mb-4"
            ]
            [ label
                [ for "equipname"
                , class S.inputLabel
                ]
                [ text "Name"
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , onInput SetName
                , placeholder "Name"
                , value model.name
                , name "equipname"
                , class S.textInput
                , classList
                    [ ( "border-red-600 dark:border-orange-600"
                      , not (isValid model)
                      )
                    ]
                ]
                []
            ]
        ]
