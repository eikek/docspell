module Comp.SourceManage exposing
    ( Model
    , Msg(..)
    , init
    , update
    , view2
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.SourceAndTags exposing (SourceAndTags)
import Api.Model.SourceList exposing (SourceList)
import Comp.Basic as B
import Comp.MenuBar as MB
import Comp.SourceForm
import Comp.SourceTable exposing (SelectMode(..))
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onSubmit)
import Http
import Messages.SourceManageComp exposing (Texts)
import Ports
import QRCode
import Styles as S
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



--- View2


qrCodeView : Texts -> String -> Html msg
qrCodeView texts message =
    QRCode.encode message
        |> Result.map QRCode.toSvg
        |> Result.withDefault
            (Html.text texts.errorGeneratingQR)


view2 : Texts -> Flags -> UiSettings -> Model -> Html Msg
view2 texts flags settings model =
    case model.viewMode of
        None ->
            viewTable2 texts model

        Edit _ ->
            div [] (viewForm2 texts flags settings model)

        Display source ->
            viewLinks2 texts flags settings source


viewTable2 : Texts -> Model -> Html Msg
viewTable2 texts model =
    div [ class "relative flex flex-col" ]
        [ MB.view
            { start = []
            , end =
                [ MB.PrimaryButton
                    { tagger = InitNewSource
                    , title = texts.addSourceUrl
                    , icon = Just "fa fa-plus"
                    , label = texts.newSource
                    }
                ]
            , rootClasses = "mb-4"
            }
        , Html.map TableMsg (Comp.SourceTable.view2 texts.sourceTable model.sources)
        , B.loadingDimmer model.loading
        ]


viewLinks2 : Texts -> Flags -> UiSettings -> SourceAndTags -> Html Msg
viewLinks2 texts flags _ source =
    let
        appUrl =
            flags.config.baseUrl ++ "/app/upload/" ++ source.source.id

        apiUrl =
            flags.config.baseUrl ++ "/api/v1/open/upload/item/" ++ source.source.id

        styleUrl =
            "truncate px-2 py-2 border-0 border-t border-b border-r font-mono text-sm my-auto rounded-r border-gray-400 dark:border-bluegray-500"

        styleQr =
            "max-w-min dark:bg-bluegray-400 bg-gray-50 mx-auto md:mx-0"
    in
    div
        []
        [ h2 [ class S.header2 ]
            [ text (texts.publicUploads ++ ": ")
            , text source.source.abbrev
            , div [ class "opacity-50 text-sm" ]
                [ text source.source.id
                ]
            ]
        , MB.view
            { start =
                [ MB.SecondaryButton
                    { label = texts.basics.back
                    , icon = Just "fa fa-arrow-left"
                    , tagger = SetTableView
                    , title = texts.basics.backToList
                    }
                ]
            , end = []
            , rootClasses = "mb-4"
            }
        , p [ class "text-lg pt-2 opacity-75" ]
            [ text texts.sourceInfoText
            ]
        , p [ class "text-lg py-2 opacity-75" ]
            [ text (texts.itemsCreatedInfo source.source.counter)
            ]
        , h3
            [ class S.header3
            , class "mt-2"
            ]
            [ text texts.publicUploadPage
            ]
        , div [ class "" ]
            [ div [ class "flex flex-row" ]
                [ a
                    [ class S.secondaryBasicButtonPlain
                    , class "rounded-l border text-sm px-4 py-2"
                    , title texts.copyToClipboard
                    , href "#"
                    , Tuple.second appClipboardData
                        |> String.dropLeft 1
                        |> id
                    , attribute "data-clipboard-target" "#app-url"
                    ]
                    [ i [ class "fa fa-copy" ] []
                    ]
                , a
                    [ class S.secondaryBasicButtonPlain
                    , class "px-4 py-2 border-0 border-t border-b border-r text-sm"
                    , href appUrl
                    , target "_blank"
                    , title texts.openInNewTab
                    ]
                    [ i [ class "fa fa-external-link-alt" ] []
                    ]
                , div
                    [ id "app-url"
                    , class styleUrl
                    ]
                    [ text appUrl
                    ]
                ]
            ]
        , div [ class "py-2" ]
            [ div
                [ class S.border
                , class styleQr
                ]
                [ qrCodeView texts appUrl
                ]
            ]
        , h3
            [ class S.header3
            , class "mt-4"
            ]
            [ text texts.publicUploadUrl
            ]
        , div [ class "" ]
            [ div [ class "flex flex-row" ]
                [ a
                    [ class S.secondaryBasicButtonPlain
                    , class "px-4 py-2 rounded-l border text-sm"
                    , title texts.copyToClipboard
                    , href "#"
                    , Tuple.second apiClipboardData
                        |> String.dropLeft 1
                        |> id
                    , attribute "data-clipboard-target" "#api-url"
                    ]
                    [ i [ class "fa fa-copy" ] []
                    ]
                , div
                    [ class styleUrl
                    , id "api-url"
                    ]
                    [ text apiUrl
                    ]
                ]
            ]
        , div [ class "py-2" ]
            [ div
                [ class S.border
                , class styleQr
                ]
                [ qrCodeView texts apiUrl
                ]
            ]
        ]


viewForm2 : Texts -> Flags -> UiSettings -> Model -> List (Html Msg)
viewForm2 texts flags settings model =
    let
        newSource =
            model.formModel.source.source.id == ""

        dimmerSettings =
            Comp.YesNoDimmer.defaultSettings2 texts.reallyDeleteSource
    in
    [ if newSource then
        h3 [ class S.header2 ]
            [ text texts.createNewSource
            ]

      else
        h3 [ class S.header2 ]
            [ text model.formModel.source.source.abbrev
            , div [ class "opacity-50 text-sm" ]
                [ text "Id: "
                , text model.formModel.source.source.id
                ]
            ]
    , Html.form
        [ class "flex flex-col md:relative"
        , onSubmit Submit
        ]
        [ MB.view
            { start =
                [ MB.PrimaryButton
                    { tagger = Submit
                    , title = texts.basics.submitThisForm
                    , icon = Just "fa fa-save"
                    , label = texts.basics.submit
                    }
                , MB.SecondaryButton
                    { tagger = SetTableView
                    , title = texts.basics.backToList
                    , icon = Just "fa fa-arrow-left"
                    , label = texts.basics.cancel
                    }
                ]
            , end =
                if not newSource then
                    [ MB.DeleteButton
                        { tagger = RequestDelete
                        , title = texts.deleteThisSource
                        , icon = Just "fa fa-trash"
                        , label = texts.basics.delete
                        }
                    ]

                else
                    []
            , rootClasses = "mb-4"
            }
        , Html.map FormMsg
            (Comp.SourceForm.view2 flags texts.sourceForm settings model.formModel)
        , div
            [ classList
                [ ( S.errorMessage, True )
                , ( "hidden", Util.Maybe.isEmpty model.formError )
                ]
            ]
            [ Maybe.withDefault "" model.formError |> text
            ]
        , Html.map YesNoMsg
            (Comp.YesNoDimmer.viewN True
                dimmerSettings
                model.deleteConfirm
            )
        , B.loadingDimmer model.loading
        ]
    ]
