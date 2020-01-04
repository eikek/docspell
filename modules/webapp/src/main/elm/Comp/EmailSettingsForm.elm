module Comp.EmailSettingsForm exposing
    ( Model
    , Msg
    , emptyModel
    , update
    , view
    )

import Api.Model.EmailSettings exposing (EmailSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)


type alias Model =
    { settings : EmailSettings
    , name : String
    }


emptyModel : Model
emptyModel =
    { settings = Api.Model.EmailSettings.empty
    , name = ""
    }


init : EmailSettings -> Model
init ems =
    { settings = ems
    , name = ems.name
    }


type Msg
    = SetName String


isValid : Model -> Bool
isValid model =
    True


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div
        [ classList
            [ ( "ui form", True )
            , ( "error", not (isValid model) )
            , ( "success", isValid model )
            ]
        ]
        [ div [ class "required field" ]
            [ label [] [ text "Name" ]
            , input
                [ type_ "text"
                , value model.name
                , onInput SetName
                , placeholder "Connection name"
                ]
                []
            ]
        ]
