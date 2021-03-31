-- inspired from here: https://ellie-app.com/3T5mNms7SwKa1


module Comp.Dropzone exposing
    ( Model
    , Msg(..)
    , Settings
    , defaultSettings
    , init
    , setActive
    , update
    , view2
    )

import Comp.Basic as B
import File exposing (File)
import File.Select
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Messages.DropzoneComp exposing (Texts)
import Styles as S
import Util.Html exposing (onDragEnter, onDragLeave, onDragOver, onDropFiles)


type alias State =
    { hover : Bool
    , active : Bool
    }


type alias Settings =
    { classList : State -> List ( String, Bool )
    }


defaultSettings : Settings
defaultSettings =
    { classList = \_ -> [ ( "ui placeholder segment", True ) ]
    }


type alias Model =
    { state : State
    , contentTypes : List String
    }


init : List String -> Model
init contentTypes =
    { state = State False True
    , contentTypes = contentTypes
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
            ( model, File.Select.files model.contentTypes GotFiles, [] )

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
                        filterMime model (file :: files)

                    else
                        []
            in
            ( { model | state = ns }, Cmd.none, newFiles )


filterMime : Model -> List File -> List File
filterMime model files =
    let
        pred f =
            List.member (File.mime f) model.contentTypes
    in
    if model.contentTypes == [] then
        files

    else
        List.filter pred files



--- View2


view2 : Texts -> Model -> Html Msg
view2 texts model =
    div
        [ classList
            [ ( "bg-opacity-100 bg-blue-100 dark:bg-lightblue-800", model.state.hover )
            , ( "bg-blue-100 dark:bg-lightblue-900 bg-opacity-50", not model.state.hover )
            , ( "disabled", not model.state.active )
            ]
        , class "flex flex-col justify-center items-center py-2 md:py-12 border-0 border-t-2 border-blue-500 dark:border-lightblue-500 dropzone"
        , onDragEnter DragEnter
        , onDragOver DragEnter
        , onDragLeave DragLeave
        , onDropFiles GotFiles
        ]
        [ div
            [ class S.header1
            , class "hidden md:inline-flex items-center"
            ]
            [ i [ class "fa fa-mouse-pointer" ] []
            , div [ class "ml-3" ]
                [ text texts.dropFilesHere
                ]
            ]
        , B.horizontalDivider
            { label = texts.or
            , topCss = "w-2/3 mb-4 hidden md:inline-flex"
            , labelCss = "px-4 bg-gray-200 bg-opacity-50"
            , lineColor = "bg-gray-300 dark:bg-bluegray-600"
            }
        , B.primaryBasicButton
            { label = texts.select
            , icon = "fa fa-folder-open font-thin"
            , handler = onClick PickFiles
            , attrs = [ href "#" ]
            , disabled = not model.state.active
            }
        , div [ class "text-center opacity-75 text-sm mt-4" ]
            [ text texts.selectInfo
            ]
        ]
