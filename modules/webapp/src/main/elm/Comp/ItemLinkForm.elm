{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.ItemLinkForm exposing (Model, Msg, emptyModel, init, initWith, update, view)

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.ItemLight exposing (ItemLight)
import Api.Model.ItemLightGroup exposing (ItemLightGroup)
import Comp.ItemSearchInput
import Data.Flags exposing (Flags)
import Data.ItemQuery as IQ
import Data.ItemTemplate as IT
import Data.UiSettings exposing (UiSettings)
import Html exposing (Html, a, div, i, text)
import Html.Attributes exposing (class, classList, href, title)
import Html.Events exposing (onClick)
import Http
import Messages.Comp.ItemLinkForm exposing (Texts)
import Page exposing (Page(..))
import Styles as S


type alias Model =
    { itemSearchModel : Comp.ItemSearchInput.Model
    , relatedItems : List ItemLight
    , targetItemId : String
    , editMode : EditMode
    , formState : FormState
    }


type EditMode
    = AddRelated
    | RemoveRelated


type FormState
    = FormOk
    | FormHttpError Http.Error
    | FormError String


emptyModel : Model
emptyModel =
    let
        cfg =
            Comp.ItemSearchInput.defaultConfig
    in
    { itemSearchModel = Comp.ItemSearchInput.init cfg
    , relatedItems = []
    , targetItemId = ""
    , editMode = AddRelated
    , formState = FormOk
    }


type Msg
    = ItemSearchMsg Comp.ItemSearchInput.Msg
    | RelatedItemsResp (Result Http.Error ItemLightGroup)
    | UpdateRelatedResp (Result Http.Error BasicResult)
    | DeleteRelatedItem ItemLight
    | ToggleEditMode


initWith : String -> List ItemLight -> Model
initWith target related =
    let
        cfg =
            Comp.ItemSearchInput.defaultConfig
    in
    { itemSearchModel = Comp.ItemSearchInput.init cfg
    , relatedItems = related
    , targetItemId = target
    , editMode = AddRelated
    , formState = FormOk
    }


init : Flags -> String -> ( Model, Cmd Msg )
init flags itemId =
    let
        searchCfg =
            Comp.ItemSearchInput.defaultConfig
    in
    ( { itemSearchModel = Comp.ItemSearchInput.init searchCfg
      , relatedItems = []
      , targetItemId = itemId
      , editMode = AddRelated
      , formState = FormOk
      }
    , initCmd flags itemId
    )


initCmd : Flags -> String -> Cmd Msg
initCmd flags itemId =
    Api.getRelatedItems flags itemId RelatedItemsResp


excludeResults : Model -> Maybe IQ.ItemQuery
excludeResults model =
    let
        relatedIds =
            List.map .id model.relatedItems

        all =
            if model.targetItemId == "" then
                relatedIds

            else
                model.targetItemId :: relatedIds
    in
    case all of
        [] ->
            Nothing

        ids ->
            Just <| IQ.Not (IQ.ItemIdIn ids)



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update flags msg model =
    case msg of
        ItemSearchMsg lm ->
            case model.editMode of
                AddRelated ->
                    let
                        result =
                            Comp.ItemSearchInput.update flags (excludeResults model) lm model.itemSearchModel

                        cmd =
                            case result.selected of
                                Just item ->
                                    if model.targetItemId == "" then
                                        Cmd.none

                                    else
                                        Api.addRelatedItems flags
                                            { item = model.targetItemId
                                            , related = [ item.id ]
                                            }
                                            UpdateRelatedResp

                                Nothing ->
                                    Cmd.none
                    in
                    ( { model | itemSearchModel = result.model }
                    , Cmd.batch
                        [ Cmd.map ItemSearchMsg result.cmd
                        , cmd
                        ]
                    , Sub.map ItemSearchMsg result.sub
                    )

                RemoveRelated ->
                    ( model, Cmd.none, Sub.none )

        RelatedItemsResp (Ok list) ->
            ( { model
                | relatedItems = list.items
                , formState = FormOk
                , editMode =
                    if List.isEmpty list.items then
                        AddRelated

                    else
                        model.editMode
              }
            , Cmd.none
            , Sub.none
            )

        RelatedItemsResp (Err err) ->
            ( { model | formState = FormHttpError err }, Cmd.none, Sub.none )

        UpdateRelatedResp (Ok res) ->
            if res.success then
                ( { model | formState = FormOk }
                , initCmd flags model.targetItemId
                , Sub.none
                )

            else
                ( { model | formState = FormError res.message }, Cmd.none, Sub.none )

        UpdateRelatedResp (Err err) ->
            ( { model | formState = FormHttpError err }, Cmd.none, Sub.none )

        ToggleEditMode ->
            let
                next =
                    if model.editMode == RemoveRelated then
                        AddRelated

                    else
                        RemoveRelated
            in
            ( { model | editMode = next }, Cmd.none, Sub.none )

        DeleteRelatedItem item ->
            case model.editMode of
                RemoveRelated ->
                    if model.targetItemId == "" then
                        ( model, Cmd.none, Sub.none )

                    else
                        ( model, Api.removeRelatedItem flags model.targetItemId item.id UpdateRelatedResp, Sub.none )

                AddRelated ->
                    ( model, Cmd.none, Sub.none )



--- View


view : Texts -> UiSettings -> Model -> Html Msg
view texts settings model =
    div
        [ classList
            [ ( "bg-red-100 bg-opacity-25", model.editMode == RemoveRelated )
            , ( "dark:bg-orange-80 dark:bg-opacity-10", model.editMode == RemoveRelated )
            ]
        ]
        [ div [ class "relative" ]
            [ Html.map ItemSearchMsg
                (Comp.ItemSearchInput.view texts.itemSearchInput
                    settings
                    model.itemSearchModel
                    [ class "text-sm py-1 pr-6"
                    , classList [ ( "disabled", model.editMode == RemoveRelated ) ]
                    ]
                )
            , a
                [ classList
                    [ ( "hidden", Comp.ItemSearchInput.hasFocus model.itemSearchModel )
                    , ( "bg-red-600 text-white dark:bg-orange-500 dark:text-slate-900 ", model.editMode == RemoveRelated )
                    , ( "opacity-50", model.editMode == AddRelated )
                    , ( S.deleteButtonBase, model.editMode == AddRelated )
                    ]
                , class " absolute right-0 top-0 rounded-r py-1 px-2 h-full block text-sm"
                , href "#"
                , onClick ToggleEditMode
                ]
                [ i [ class "fa fa-trash " ] []
                ]
            , div
                [ class "absolute right-0 top-0 py-1 mr-1 w-4"
                , classList [ ( "hidden", not (Comp.ItemSearchInput.isSearching model.itemSearchModel) ) ]
                ]
                [ i [ class "fa fa-circle-notch animate-spin" ] []
                ]
            ]
        , case model.formState of
            FormOk ->
                viewRelatedItems texts settings model

            FormHttpError err ->
                div [ class S.errorText ]
                    [ text <| texts.httpError err
                    ]

            FormError msg ->
                div [ class S.errorText ]
                    [ text msg
                    ]
        ]


viewRelatedItems : Texts -> UiSettings -> Model -> Html Msg
viewRelatedItems texts settings model =
    div [ class "px-1.5 pb-0.5" ]
        (List.map (viewItem texts settings model) model.relatedItems)


viewItem : Texts -> UiSettings -> Model -> ItemLight -> Html Msg
viewItem texts _ model item =
    let
        mainTpl =
            IT.name

        tooltipTpl =
            IT.concat
                [ IT.dateShort
                , IT.literal ", "
                , IT.correspondent
                ]

        tctx =
            { dateFormatLong = texts.dateFormatLong
            , dateFormatShort = texts.dateFormatShort
            , directionLabel = texts.directionLabel
            }
    in
    case model.editMode of
        AddRelated ->
            a
                [ class "flex items-center my-2"
                , class S.link
                , Page.href (ItemDetailPage item.id)
                , title <| IT.render tooltipTpl tctx item
                ]
                [ i [ class "fa fa-link text-xs mr-1" ] []
                , IT.render mainTpl tctx item |> text
                ]

        RemoveRelated ->
            a
                [ class "flex items-center my-2"
                , class " text-red-600 hover:text-red-500 dark:text-orange-400 dark:hover:text-orange-300 "
                , href "#"
                , onClick (DeleteRelatedItem item)
                ]
                [ i [ class "fa fa-trash mr-2" ] []
                , IT.render mainTpl tctx item |> text
                ]
