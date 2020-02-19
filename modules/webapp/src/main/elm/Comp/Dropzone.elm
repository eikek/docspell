-- inspired from here: https://ellie-app.com/3T5mNms7SwKa1


module Comp.Dropzone exposing
    ( Model
    , Msg(..)
    , Settings
    , defaultSettings
    , init
    , setActive
    , update
    , view
    )

import File exposing (File)
import File.Select
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as D


type alias State =
    { hover : Bool
    , active : Bool
    }


type alias Settings =
    { classList : State -> List ( String, Bool )
    , contentTypes : List String
    }


defaultSettings : Settings
defaultSettings =
    { classList = \_ -> [ ( "ui placeholder segment", True ) ]
    , contentTypes = []
    }


type alias Model =
    { state : State
    , settings : Settings
    }


init : Settings -> Model
init settings =
    { state = State False True
    , settings = settings
    }


type Msg
    = DragEnter
    | DragLeave
    | GotFiles File (List File)
    | PickFiles
    | SetActive Bool


setActive : Bool -> Msg
setActive flag =
    SetActive flag


update : Msg -> Model -> ( Model, Cmd Msg, List File )
update msg model =
    case msg of
        SetActive flag ->
            let
                ns =
                    { hover = model.state.hover, active = flag }
            in
            ( { model | state = ns }, Cmd.none, [] )

        PickFiles ->
            ( model, File.Select.files model.settings.contentTypes GotFiles, [] )

        DragEnter ->
            let
                ns =
                    { hover = True, active = model.state.active }
            in
            ( { model | state = ns }, Cmd.none, [] )

        DragLeave ->
            let
                ns =
                    { hover = False, active = model.state.active }
            in
            ( { model | state = ns }, Cmd.none, [] )

        GotFiles file files ->
            let
                ns =
                    { hover = False, active = model.state.active }

                newFiles =
                    if model.state.active then
                        filterMime model.settings (file :: files)

                    else
                        []
            in
            ( { model | state = ns }, Cmd.none, newFiles )


view : Model -> Html Msg
view model =
    div
        [ classList (model.settings.classList model.state)
        , hijackOn "dragenter" (D.succeed DragEnter)
        , hijackOn "dragover" (D.succeed DragEnter)
        , hijackOn "dragleave" (D.succeed DragLeave)
        , hijackOn "drop" dropDecoder
        ]
        [ div [ class "ui icon header" ]
            [ i [ class "mouse pointer icon" ] []
            , div [ class "content" ]
                [ text "Drop files here"
                , div [ class "sub header" ]
                    [ text "PDF files only"
                    ]
                ]
            ]
        , div [ class "ui horizontal divider" ]
            [ text "Or"
            ]
        , a
            [ classList
                [ ( "ui basic primary button", True )
                , ( "disabled", not model.state.active )
                ]
            , onClick PickFiles
            , href ""
            ]
            [ i [ class "folder open icon" ] []
            , text "Select ..."
            ]
        ]


filterMime : Settings -> List File -> List File
filterMime settings files =
    let
        pred f =
            List.member (File.mime f) settings.contentTypes
    in
    if settings.contentTypes == [] then
        files

    else
        List.filter pred files


dropDecoder : D.Decoder Msg
dropDecoder =
    D.at [ "dataTransfer", "files" ] (D.oneOrMore GotFiles File.decoder)


hijackOn : String -> D.Decoder msg -> Attribute msg
hijackOn event decoder =
    preventDefaultOn event (D.map hijack decoder)


hijack : msg -> ( msg, Bool )
hijack msg =
    ( msg, True )
