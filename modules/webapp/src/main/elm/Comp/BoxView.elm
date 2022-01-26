module Comp.BoxView exposing (..)

import Comp.BoxQueryView
import Comp.BoxSummaryView
import Data.Box exposing (Box)
import Data.BoxContent exposing (BoxContent(..), MessageData)
import Data.Flags exposing (Flags)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, classList)
import Markdown
import Messages.Comp.BoxView exposing (Texts)
import Styles as S


type alias Model =
    { box : Box
    , content : ContentModel
    }


type ContentModel
    = ContentMessage Data.BoxContent.MessageData
    | ContentUpload (Maybe String)
    | ContentQuery Comp.BoxQueryView.Model
    | ContentSummary Comp.BoxSummaryView.Model


type Msg
    = QueryMsg Comp.BoxQueryView.Msg
    | SummaryMsg Comp.BoxSummaryView.Msg


init : Flags -> Box -> ( Model, Cmd Msg )
init flags box =
    let
        ( cm, cc ) =
            contentInit flags box.content
    in
    ( { box = box
      , content = cm
      }
    , cc
    )


contentInit : Flags -> BoxContent -> ( ContentModel, Cmd Msg )
contentInit flags content =
    case content of
        BoxMessage data ->
            ( ContentMessage data, Cmd.none )

        BoxUpload source ->
            ( ContentUpload source, Cmd.none )

        BoxQuery data ->
            let
                ( qm, qc ) =
                    Comp.BoxQueryView.init flags data
            in
            ( ContentQuery qm, Cmd.map QueryMsg qc )

        BoxSummary data ->
            let
                ( sm, sc ) =
                    Comp.BoxSummaryView.init flags data
            in
            ( ContentSummary sm, Cmd.map SummaryMsg sc )



--- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        QueryMsg lm ->
            case model.content of
                ContentQuery qm ->
                    let
                        ( cm, cc ) =
                            Comp.BoxQueryView.update lm qm
                    in
                    ( { model | content = ContentQuery cm }, Cmd.map QueryMsg cc )

                _ ->
                    unit model

        SummaryMsg lm ->
            case model.content of
                ContentSummary qm ->
                    let
                        ( cm, cc ) =
                            Comp.BoxSummaryView.update lm qm
                    in
                    ( { model | content = ContentSummary cm }, Cmd.map SummaryMsg cc )

                _ ->
                    unit model


unit : Model -> ( Model, Cmd Msg )
unit model =
    ( model, Cmd.none )



--- View


view : Texts -> Model -> Html Msg
view texts model =
    div
        [ classList [ ( S.box ++ "rounded", model.box.decoration ) ]
        , class (spanStyle model.box)
        , class "relative h-full"
        , classList [ ( "hidden", not model.box.visible ) ]
        ]
        [ boxHeader model
        , div [ class "px-2 py-1 h-5/6" ]
            [ boxContent texts model
            ]
        ]


boxHeader : Model -> Html Msg
boxHeader model =
    div
        [ class "border-b dark:border-slate-500 flex flex-row py-1 bg-blue-50 dark:bg-slate-700 rounded-t"
        , classList [ ( "hidden", not model.box.decoration || model.box.name == "" ) ]
        ]
        [ div [ class "flex text-lg tracking-medium italic px-2" ]
            [ text model.box.name
            ]
        ]


boxContent : Texts -> Model -> Html Msg
boxContent texts model =
    case model.content of
        ContentMessage m ->
            messageContent m

        ContentUpload sourceId ->
            Debug.todo "not implemented"

        ContentQuery qm ->
            Html.map QueryMsg
                (Comp.BoxQueryView.view texts.queryView qm)

        ContentSummary qm ->
            Html.map SummaryMsg
                (Comp.BoxSummaryView.view texts.summaryView qm)


spanStyle : Box -> String
spanStyle box =
    case box.colspan of
        1 ->
            ""

        2 ->
            "col-span-1 md:col-span-2"

        3 ->
            "col-span-1 md:col-span-3"

        4 ->
            "col-span-1 md:col-span-4"

        _ ->
            "col-span-1 md:col-span-5"


messageContent : MessageData -> Html msg
messageContent data =
    div [ class "markdown-preview" ]
        [ Markdown.toHtml [] data.title
        , Markdown.toHtml [] data.body
        ]
