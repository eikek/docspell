module Comp.BoxQueryView exposing (Model, Msg, init, reloadData, update, view)

import Api
import Api.Model.ItemLight exposing (ItemLight)
import Api.Model.ItemLightList exposing (ItemLightList)
import Api.Model.ItemQuery exposing (ItemQuery)
import Comp.Basic
import Data.BoxContent exposing (QueryData, SearchQuery(..))
import Data.Flags exposing (Flags)
import Data.ItemTemplate as IT
import Data.Items
import Data.SearchMode
import Html exposing (Html, a, div, i, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class, classList)
import Http
import Messages.Comp.BoxQueryView exposing (Texts)
import Page exposing (Page(..))
import Styles


type alias Model =
    { results : ViewResult
    , meta : QueryData
    }


type ViewResult
    = Loading
    | Loaded ItemLightList
    | Failed Http.Error


type Msg
    = ItemsResp (Result Http.Error ItemLightList)
    | ReloadData


init : Flags -> QueryData -> ( Model, Cmd Msg )
init flags data =
    ( { results = Loading
      , meta = data
      }
    , dataCmd flags data
    )


reloadData : Msg
reloadData =
    ReloadData



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Bool )
update flags msg model =
    case msg of
        ItemsResp (Ok list) ->
            ( { model | results = Loaded list }, Cmd.none, False )

        ItemsResp (Err err) ->
            ( { model | results = Failed err }, Cmd.none, False )

        ReloadData ->
            ( model, dataCmd flags model.meta, True )



--- View


view : Texts -> Model -> Html Msg
view texts model =
    case model.results of
        Loading ->
            div [ class "h-24 " ]
                [ Comp.Basic.loadingDimmer
                    { label = ""
                    , active = True
                    }
                ]

        Failed err ->
            div
                [ class "py-4"
                , class Styles.errorMessage
                ]
                [ text texts.errorOccurred
                , text ": "
                , text (texts.httpError err)
                ]

        Loaded list ->
            if list.groups == [] then
                viewEmpty texts

            else
                viewItems texts model.meta list


viewItems : Texts -> QueryData -> ItemLightList -> Html Msg
viewItems texts meta list =
    let
        items =
            Data.Items.flatten list
    in
    table [ class "w-full divide-y dark:divide-slate-500" ]
        (viewItemHead meta ++ [ tbody [] <| List.map (viewItemRow texts meta) items ])


viewItemHead : QueryData -> List (Html Msg)
viewItemHead meta =
    case meta.header of
        [] ->
            []

        labels ->
            [ thead []
                [ tr []
                    (List.map (\n -> th [ class "text-left text-sm" ] [ text n ]) labels)
                ]
            ]


viewItemRow : Texts -> QueryData -> ItemLight -> Html Msg
viewItemRow texts meta item =
    let
        ( col1, cols ) =
            getColumns meta

        render tpl =
            IT.render tpl texts.templateCtx item

        td1 =
            td [ class "py-2 px-1" ]
                [ a
                    [ class Styles.link
                    , Page.href (ItemDetailPage item.id)
                    ]
                    [ text (render col1)
                    ]
                ]

        tdRem index col =
            td
                [ class "py-2 px-1"
                , classList [ ( "hidden md:table-cell", index > 1 ) ]
                ]
                [ text (render col)
                ]
    in
    tr []
        (td1 :: List.indexedMap tdRem cols)


viewEmpty : Texts -> Html Msg
viewEmpty texts =
    div [ class "flex justify-center items-center h-full" ]
        [ div [ class "px-4 py-4 text-center align-middle text-lg" ]
            [ i [ class "fa fa-smile font-thin mr-2" ] []
            , text texts.noResults
            ]
        ]



--- Helpers


getColumns : QueryData -> ( IT.ItemTemplate, List IT.ItemTemplate )
getColumns meta =
    case meta.columns of
        x :: xs ->
            ( x, xs )

        [] ->
            ( IT.name, [ IT.correspondent, IT.dateShort ] )


mkQuery : String -> QueryData -> ItemQuery
mkQuery q meta =
    { query = q
    , limit = Just meta.limit
    , offset = Nothing
    , searchMode = Just <| Data.SearchMode.asString Data.SearchMode.Normal
    , withDetails = Just meta.details
    }


dataCmd : Flags -> QueryData -> Cmd Msg
dataCmd flags data =
    case data.query of
        SearchQueryString q ->
            Api.itemSearch flags (mkQuery q data) ItemsResp

        SearchQueryBookmark bmId ->
            Api.itemSearchBookmark flags (mkQuery bmId data) ItemsResp
