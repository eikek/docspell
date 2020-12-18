module Comp.SourceManage exposing
    ( Model
    , Msg(..)
    , init
    , update
    , view
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.SourceAndTags exposing (SourceAndTags)
import Api.Model.SourceList exposing (SourceList)
import Api.Model.SourceTagIn exposing (SourceTagIn)
import Comp.SourceForm
import Comp.SourceTable exposing (SelectMode(..))
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onSubmit)
import Http
import Ports
import QRCode
import Util.Http
import Util.Maybe


type alias Model =
    { formModel : Comp.SourceForm.Model
    , viewMode : SelectMode
    , formError : Maybe String
    , loading : Bool
    , deleteConfirm : Comp.YesNoDimmer.Model
    , sources : List SourceAndTags
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( fm, fc ) =
            Comp.SourceForm.init flags
    in
    ( { formModel = fm
      , viewMode = None
      , formError = Nothing
      , loading = False
      , deleteConfirm = Comp.YesNoDimmer.emptyModel
      , sources = []
      }
    , Cmd.batch
        [ Cmd.map FormMsg fc
        , Ports.initClipboard appClipboardData
        , Ports.initClipboard apiClipboardData
        ]
    )


appClipboardData : ( String, String )
appClipboardData =
    ( "app-url", "#app-url-copy-to-clipboard-btn" )


apiClipboardData : ( String, String )
apiClipboardData =
    ( "api-url", "#api-url-copy-to-clipboard-btn" )


type Msg
    = TableMsg Comp.SourceTable.Msg
    | FormMsg Comp.SourceForm.Msg
    | LoadSources
    | SourceResp (Result Http.Error SourceList)
    | InitNewSource
    | Submit
    | SubmitResp (Result Http.Error BasicResult)
    | YesNoMsg Comp.YesNoDimmer.Msg
    | RequestDelete
    | SetTableView



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        TableMsg m ->
            let
                ( tc, sel ) =
                    Comp.SourceTable.update flags m

                ( m2, c2 ) =
                    ( { model
                        | viewMode = sel
                        , formError =
                            if Comp.SourceTable.isEdit sel then
                                model.formError

                            else
                                Nothing
                      }
                    , Cmd.map TableMsg tc
                    )

                ( m3, c3 ) =
                    case sel of
                        Edit source ->
                            update flags (FormMsg (Comp.SourceForm.SetSource source)) m2

                        Display _ ->
                            ( m2, Cmd.none )

                        None ->
                            ( m2, Cmd.none )
            in
            ( m3, Cmd.batch [ c2, c3 ] )

        FormMsg m ->
            let
                ( m2, c2 ) =
                    Comp.SourceForm.update flags m model.formModel
            in
            ( { model | formModel = m2 }, Cmd.map FormMsg c2 )

        LoadSources ->
            ( { model | loading = True }, Api.getSources flags SourceResp )

        SourceResp (Ok sources) ->
            ( { model
                | viewMode = None
                , loading = False
                , sources = sources.items
              }
            , Cmd.none
            )

        SourceResp (Err _) ->
            ( { model | loading = False }, Cmd.none )

        SetTableView ->
            ( { model | viewMode = None }, Cmd.none )

        InitNewSource ->
            let
                source =
                    Api.Model.SourceAndTags.empty

                nm =
                    { model | viewMode = Edit source, formError = Nothing }
            in
            update flags (FormMsg (Comp.SourceForm.SetSource source)) nm

        Submit ->
            let
                source =
                    Comp.SourceForm.getSource model.formModel

                valid =
                    Comp.SourceForm.isValid model.formModel
            in
            if valid then
                ( { model | loading = True }, Api.postSource flags source SubmitResp )

            else
                ( { model | formError = Just "Please correct the errors in the form." }, Cmd.none )

        SubmitResp (Ok res) ->
            if res.success then
                let
                    ( m2, c2 ) =
                        update flags SetTableView model

                    ( m3, c3 ) =
                        update flags LoadSources m2
                in
                ( { m3 | loading = False }, Cmd.batch [ c2, c3 ] )

            else
                ( { model | formError = Just res.message, loading = False }, Cmd.none )

        SubmitResp (Err err) ->
            ( { model | formError = Just (Util.Http.errorToString err), loading = False }, Cmd.none )

        RequestDelete ->
            update flags (YesNoMsg Comp.YesNoDimmer.activate) model

        YesNoMsg m ->
            let
                ( cm, confirmed ) =
                    Comp.YesNoDimmer.update m model.deleteConfirm

                src =
                    Comp.SourceForm.getSource model.formModel

                cmd =
                    if confirmed then
                        Api.deleteSource flags src.source.id SubmitResp

                    else
                        Cmd.none
            in
            ( { model | deleteConfirm = cm }, cmd )



--- View


qrCodeView : String -> Html msg
qrCodeView message =
    QRCode.encode message
        |> Result.map QRCode.toSvg
        |> Result.withDefault
            (Html.text "Error generating QR-Code")


view : Flags -> UiSettings -> Model -> Html Msg
view flags settings model =
    case model.viewMode of
        None ->
            viewTable model

        Edit _ ->
            div [] (viewForm flags settings model)

        Display source ->
            viewLinks flags settings source


viewTable : Model -> Html Msg
viewTable model =
    div []
        [ button [ class "ui basic button", onClick InitNewSource ]
            [ i [ class "plus icon" ] []
            , text "Create new"
            ]
        , Html.map TableMsg (Comp.SourceTable.view model.sources)
        , div
            [ classList
                [ ( "ui dimmer", True )
                , ( "active", model.loading )
                ]
            ]
            [ div [ class "ui loader" ] []
            ]
        ]


viewLinks : Flags -> UiSettings -> SourceAndTags -> Html Msg
viewLinks flags _ source =
    let
        appUrl =
            flags.config.baseUrl ++ "/app/upload/" ++ source.source.id

        apiUrl =
            flags.config.baseUrl ++ "/api/v1/open/upload/item/" ++ source.source.id
    in
    div
        []
        [ h3 [ class "ui dividing header" ]
            [ text "Public Uploads: "
            , text source.source.abbrev
            , div [ class "sub header" ]
                [ text source.source.id
                ]
            ]
        , p []
            [ text "This source defines URLs that can be used by anyone to send files to "
            , text "you. There is a web page that you can share or the API url can be used "
            , text "with other clients."
            ]
        , p []
            [ text "There have been "
            , String.fromInt source.source.counter |> text
            , text " items created through this source."
            ]
        , h4 [ class "ui header" ]
            [ text "Public Upload Page"
            ]
        , div [ class "ui attached message" ]
            [ div [ class "ui fluid left action input" ]
                [ a
                    [ class "ui left icon button"
                    , title "Copy to clipboard"
                    , href "#"
                    , Tuple.second appClipboardData
                        |> String.dropLeft 1
                        |> id
                    , attribute "data-clipboard-target" "#app-url"
                    ]
                    [ i [ class "copy icon" ] []
                    ]
                , a
                    [ class "ui icon button"
                    , href appUrl
                    , target "_blank"
                    , title "Open in new tab/window"
                    ]
                    [ i [ class "link external icon" ] []
                    ]
                , input
                    [ type_ "text"
                    , id "app-url"
                    , value appUrl
                    , readonly True
                    ]
                    []
                ]
            ]
        , div [ class "ui attached segment" ]
            [ div [ class "qr-code" ]
                [ qrCodeView appUrl
                ]
            ]
        , h4 [ class "ui header" ]
            [ text "Public API Upload URL"
            ]
        , div [ class "ui attached message" ]
            [ div [ class "ui fluid left action input" ]
                [ a
                    [ class "ui left icon button"
                    , title "Copy to clipboard"
                    , href "#"
                    , Tuple.second apiClipboardData
                        |> String.dropLeft 1
                        |> id
                    , attribute "data-clipboard-target" "#api-url"
                    ]
                    [ i [ class "copy icon" ] []
                    ]
                , input
                    [ type_ "text"
                    , value apiUrl
                    , readonly True
                    , id "api-url"
                    ]
                    []
                ]
            ]
        , div [ class "ui attached segment" ]
            [ div [ class "qr-code" ]
                [ qrCodeView apiUrl
                ]
            ]
        , div [ class "ui divider" ] []
        , button
            [ class "ui button"
            , onClick SetTableView
            ]
            [ text "Back"
            ]
        ]


viewForm : Flags -> UiSettings -> Model -> List (Html Msg)
viewForm flags settings model =
    let
        newSource =
            model.formModel.source.source.id == ""
    in
    [ if newSource then
        h3 [ class "ui top attached header" ]
            [ text "Create new source"
            ]

      else
        h3 [ class "ui top attached header" ]
            [ text ("Edit: " ++ model.formModel.source.source.abbrev)
            , div [ class "sub header" ]
                [ text "Id: "
                , text model.formModel.source.source.id
                ]
            ]
    , Html.form [ class "ui attached segment", onSubmit Submit ]
        [ Html.map YesNoMsg (Comp.YesNoDimmer.view model.deleteConfirm)
        , Html.map FormMsg (Comp.SourceForm.view flags settings model.formModel)
        , div
            [ classList
                [ ( "ui error message", True )
                , ( "invisible", Util.Maybe.isEmpty model.formError )
                ]
            ]
            [ Maybe.withDefault "" model.formError |> text
            ]
        , div [ class "ui horizontal divider" ] []
        , button [ class "ui primary button", type_ "submit" ]
            [ text "Submit"
            ]
        , a [ class "ui secondary button", onClick SetTableView, href "#" ]
            [ text "Cancel"
            ]
        , if not newSource then
            a [ class "ui right floated red button", href "#", onClick RequestDelete ]
                [ text "Delete" ]

          else
            span [] []
        , div
            [ classList
                [ ( "ui dimmer", True )
                , ( "active", model.loading )
                ]
            ]
            [ div [ class "ui loader" ] []
            ]
        ]
    ]
