{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.SimpleTextInput exposing
    ( Config
    , Model
    , Msg
    , ValueChange(..)
    , defaultConfig
    , getValue
    , init
    , initDefault
    , onEnterOnly
    , setValue
    , update
    , view
    , viewMap
    )

import Html exposing (Attribute, Html, input)
import Html.Attributes exposing (type_, value)
import Html.Events exposing (onBlur, onInput)
import Task
import Throttle exposing (Throttle)
import Time
import Util.Html exposing (KeyCode, onKeyUpCode)
import Util.Maybe


type Model
    = Model InnerModel


type alias Config =
    { delay : Float
    , setOnTyping : Bool
    , setOnEnter : Bool
    , setOnBlur : Bool
    , valueTransform : String -> String
    }


defaultConfig : Config
defaultConfig =
    { delay = 1500
    , setOnTyping = True
    , setOnEnter = True
    , setOnBlur = True
    , valueTransform = identity
    }


onEnterOnly : Config
onEnterOnly =
    { defaultConfig | setOnTyping = False, setOnBlur = False }


type alias InnerModel =
    { cfg : Config
    , throttle : Throttle Msg
    , value : Maybe String
    , lastPublished : Maybe String
    }


init : Config -> Maybe String -> Model
init cfg str =
    Model
        { cfg = cfg
        , throttle = Throttle.create 1
        , value = str
        , lastPublished = str
        }


initDefault : Maybe String -> Model
initDefault str =
    init defaultConfig str


getValue : Model -> Maybe String
getValue (Model model) =
    model.lastPublished


setValue : Model -> String -> ( Model, Sub Msg )
setValue (Model model) str =
    let
        v =
            Util.Maybe.fromString str

        inner =
            { model | value = v, lastPublished = v }
    in
    ( Model inner, makeSub inner inner.throttle )


type Msg
    = SetText String
    | DelayedSet
    | UpdateThrottle
    | KeyPressed (Maybe KeyCode)
    | FocusRemoved



--- Update


type ValueChange
    = ValueUpdated (Maybe String)
    | ValueUnchanged


type alias Result =
    { model : Model
    , change : ValueChange
    , cmd : Cmd Msg
    , sub : Sub Msg
    , keyPressed : Maybe KeyCode
    }


update : Msg -> Model -> Result
update msg (Model model) =
    case msg of
        SetText str ->
            let
                maybeStr =
                    Util.Maybe.fromString str
                        |> Maybe.map model.cfg.valueTransform

                cmd_ =
                    Task.succeed () |> Task.perform (\_ -> DelayedSet)

                ( newThrottle, cmd ) =
                    if model.cfg.setOnTyping then
                        Throttle.try cmd_ model.throttle

                    else
                        ( model.throttle, Cmd.none )
            in
            { model = Model { model | value = maybeStr, throttle = newThrottle }
            , change = ValueUnchanged
            , cmd = cmd
            , sub = makeSub model newThrottle
            , keyPressed = Nothing
            }

        UpdateThrottle ->
            let
                ( newThrottle, cmd ) =
                    Throttle.update model.throttle
            in
            { model = Model { model | throttle = newThrottle }
            , change = ValueUnchanged
            , cmd = cmd
            , sub = makeSub model newThrottle
            , keyPressed = Nothing
            }

        DelayedSet ->
            if model.lastPublished == model.value then
                unit model

            else
                publishChange model

        FocusRemoved ->
            if model.cfg.setOnBlur then
                publishChange model

            else
                unit model

        KeyPressed (Just Util.Html.Enter) ->
            let
                res =
                    if model.cfg.setOnEnter then
                        publishChange model

                    else
                        unit model
            in
            { res | keyPressed = Just Util.Html.Enter }

        KeyPressed kc ->
            let
                res =
                    unit model
            in
            { res | keyPressed = kc }


publishChange : InnerModel -> Result
publishChange model =
    if model.lastPublished == model.value then
        unit model

    else
        Result (Model { model | lastPublished = model.value })
            (ValueUpdated model.value)
            Cmd.none
            (makeSub model model.throttle)
            Nothing


unit : InnerModel -> Result
unit model =
    { model = Model model
    , change = ValueUnchanged
    , cmd = Cmd.none
    , sub = makeSub model model.throttle
    , keyPressed = Nothing
    }


makeSub : InnerModel -> Throttle Msg -> Sub Msg
makeSub model newThrottle =
    if model.cfg.setOnTyping then
        Throttle.ifNeeded
            (Time.every model.cfg.delay (\_ -> UpdateThrottle))
            newThrottle

    else
        Sub.none



--- View


inputAttrs : InnerModel -> List (Attribute Msg)
inputAttrs model =
    List.filterMap identity
        [ type_ "text" |> Just
        , onInput SetText |> Just
        , if model.cfg.setOnEnter then
            Just (onKeyUpCode KeyPressed)

          else
            Nothing
        , onBlur FocusRemoved |> Just
        , value (Maybe.withDefault "" model.value) |> Just
        ]


view : List (Attribute Msg) -> Model -> Html Msg
view extra (Model model) =
    let
        attrs =
            inputAttrs model
    in
    input
        (attrs ++ extra)
        []


viewMap : (Msg -> msg) -> List (Attribute msg) -> Model -> Html msg
viewMap f extra (Model model) =
    let
        attrs =
            inputAttrs model
                |> List.map (Html.Attributes.map f)
    in
    input (attrs ++ extra) []
