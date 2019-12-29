module Comp.TagForm exposing
    ( Model
    , Msg(..)
    , emptyModel
    , getTag
    , isValid
    , update
    , view
    )

import Api.Model.Tag exposing (Tag)
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)


type alias Model =
    { tag : Tag
    , name : String
    , category : Maybe String
    }


emptyModel : Model
emptyModel =
    { tag = Api.Model.Tag.empty
    , name = ""
    , category = Nothing
    }


isValid : Model -> Bool
isValid model =
    model.name /= ""


getTag : Model -> Tag
getTag model =
    Tag model.tag.id model.name model.category 0


type Msg
    = SetName String
    | SetCategory String
    | SetTag Tag


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        SetTag t ->
            ( { model | tag = t, name = t.name, category = t.category }, Cmd.none )

        SetName n ->
            ( { model | name = n }, Cmd.none )

        SetCategory n ->
            ( { model | category = Just n }, Cmd.none )


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
        , div [ class "field" ]
            [ label [] [ text "Category" ]
            , input
                [ type_ "text"
                , onInput SetCategory
                , placeholder "Category (optional)"
                , value (Maybe.withDefault "" model.category)
                ]
                []
            ]
        ]
