{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Comp.TagManage exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view2
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.Tag
import Api.Model.TagList exposing (TagList)
import Comp.Basic as B
import Comp.MenuBar as MB
import Comp.TagForm
import Comp.TagTable
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Data.TagOrder exposing (TagOrder)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onSubmit)
import Http
import Messages.Comp.TagManage exposing (Texts)
import Styles as S
import Util.Maybe
import Util.Tag
import Util.Update


type alias Model =
    { tagTableModel : Comp.TagTable.Model
    , tagFormModel : Comp.TagForm.Model
    , viewMode : ViewMode
    , formError : FormError
    , loading : Bool
    , deleteConfirm : Comp.YesNoDimmer.Model
    , query : String
    , order : TagOrder
    }


type FormError
    = FormErrorNone
    | FormErrorHttp Http.Error
    | FormErrorInvalid
    | FormErrorSubmit String


type ViewMode
    = Table
    | Form


emptyModel : Model
emptyModel =
    { tagTableModel = Comp.TagTable.emptyModel
    , tagFormModel = Comp.TagForm.emptyModel []
    , viewMode = Table
    , formError = FormErrorNone
    , loading = False
    , deleteConfirm = Comp.YesNoDimmer.emptyModel
    , query = ""
    , order = Data.TagOrder.NameAsc
    }


type Msg
    = TableMsg Comp.TagTable.Msg
    | FormMsg Comp.TagForm.Msg
    | LoadTags
    | TagResp String (Result Http.Error TagList)
    | SetViewMode ViewMode
    | InitNewTag
    | Submit
    | SubmitResp (Result Http.Error BasicResult)
    | YesNoMsg Comp.YesNoDimmer.Msg
    | RequestDelete
    | SetQuery String


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        TableMsg m ->
            let
                ( tm, tc, maybeOrder ) =
                    Comp.TagTable.update flags m model.tagTableModel

                newOrder =
                    Maybe.withDefault model.order maybeOrder

                ( m2, c2 ) =
                    ( { model
                        | tagTableModel = tm
                        , order = newOrder
                        , viewMode = Maybe.map (\_ -> Form) tm.selected |> Maybe.withDefault Table
                        , formError =
                            if Util.Maybe.nonEmpty tm.selected then
                                FormErrorNone

                            else
                                model.formError
                      }
                    , Cmd.map TableMsg tc
                    )

                ( m3, c3 ) =
                    case tm.selected of
                        Just tag ->
                            update flags (FormMsg (Comp.TagForm.SetTag tag)) m2

                        Nothing ->
                            ( m2, Cmd.none )

                ( m4, c4 ) =
                    if model.order == newOrder then
                        ( m3, Cmd.none )

                    else
                        update flags LoadTags m3
            in
            ( m4, Cmd.batch [ c2, c3, c4 ] )

        FormMsg m ->
            let
                ( m2, c2 ) =
                    Comp.TagForm.update flags m model.tagFormModel
            in
            ( { model | tagFormModel = m2 }, Cmd.map FormMsg c2 )

        LoadTags ->
            ( { model | loading = True }
            , Api.getTags flags model.query model.order (TagResp model.query)
            )

        TagResp query (Ok tags) ->
            let
                m2 =
                    { model | viewMode = Table, loading = False }

                cats =
                    Util.Tag.getCategories tags.items
            in
            Util.Update.andThen1
                [ update flags (TableMsg (Comp.TagTable.SetTags tags.items))
                , if query == "" then
                    update flags (FormMsg (Comp.TagForm.SetCategoryOptions cats))

                  else
                    \m -> ( m, Cmd.none )
                ]
                m2

        TagResp _ (Err _) ->
            ( { model | loading = False }, Cmd.none )

        SetViewMode m ->
            let
                m2 =
                    { model | viewMode = m }
            in
            case m of
                Table ->
                    update flags (TableMsg Comp.TagTable.Deselect) m2

                Form ->
                    ( m2, Cmd.none )

        InitNewTag ->
            let
                nm =
                    { model | viewMode = Form, formError = FormErrorNone }

                tag =
                    Api.Model.Tag.empty
            in
            update flags (FormMsg (Comp.TagForm.SetTag tag)) nm

        Submit ->
            let
                tag =
                    Comp.TagForm.getTag model.tagFormModel

                valid =
                    Comp.TagForm.isValid model.tagFormModel
            in
            if valid then
                ( { model | loading = True }, Api.postTag flags tag SubmitResp )

            else
                ( { model | formError = FormErrorInvalid }, Cmd.none )

        SubmitResp (Ok res) ->
            if res.success then
                let
                    ( m2, c2 ) =
                        update flags (SetViewMode Table) model

                    ( m3, c3 ) =
                        update flags LoadTags m2
                in
                ( { m3 | loading = False }, Cmd.batch [ c2, c3 ] )

            else
                ( { model | formError = FormErrorSubmit res.message, loading = False }, Cmd.none )

        SubmitResp (Err err) ->
            ( { model | formError = FormErrorHttp err, loading = False }, Cmd.none )

        RequestDelete ->
            update flags (YesNoMsg Comp.YesNoDimmer.activate) model

        YesNoMsg m ->
            let
                ( cm, confirmed ) =
                    Comp.YesNoDimmer.update m model.deleteConfirm

                tag =
                    Comp.TagForm.getTag model.tagFormModel

                cmd =
                    if confirmed then
                        Api.deleteTag flags tag.id SubmitResp

                    else
                        Cmd.none
            in
            ( { model | deleteConfirm = cm }, cmd )

        SetQuery str ->
            let
                m =
                    { model | query = str }
            in
            ( m, Api.getTags flags str model.order (TagResp str) )



--- View2


view2 : Texts -> Model -> Html Msg
view2 texts model =
    if model.viewMode == Table then
        viewTable2 texts model

    else
        viewForm2 texts model


viewTable2 : Texts -> Model -> Html Msg
viewTable2 texts model =
    div [ class "flex flex-col" ]
        [ MB.view
            { start =
                [ MB.TextInput
                    { tagger = SetQuery
                    , value = model.query
                    , placeholder = texts.basics.searchPlaceholder
                    , icon = Just "fa fa-search"
                    }
                ]
            , end =
                [ MB.PrimaryButton
                    { tagger = InitNewTag
                    , title = texts.createNewTag
                    , icon = Just "fa fa-plus"
                    , label = texts.newTag
                    }
                ]
            , rootClasses = "mb-4"
            }
        , Html.map TableMsg (Comp.TagTable.view2 texts.tagTable model.order model.tagTableModel)
        , div
            [ classList
                [ ( "ui dimmer", True )
                , ( "active", model.loading )
                ]
            ]
            [ div [ class "ui loader" ] []
            ]
        ]


viewForm2 : Texts -> Model -> Html Msg
viewForm2 texts model =
    let
        newTag =
            model.tagFormModel.tag.id == ""

        dimmerSettings2 =
            Comp.YesNoDimmer.defaultSettings texts.reallyDeleteTag
                texts.basics.yes
                texts.basics.no
    in
    Html.form
        [ class "relative flex flex-col"
        , onSubmit Submit
        ]
        [ Html.map YesNoMsg
            (Comp.YesNoDimmer.viewN
                True
                dimmerSettings2
                model.deleteConfirm
            )
        , if newTag then
            h1 [ class S.header2 ]
                [ text texts.createNewTag
                ]

          else
            h1 [ class S.header2 ]
                [ text model.tagFormModel.tag.name
                , div [ class "opacity-50 text-sm" ]
                    [ text "Id: "
                    , text model.tagFormModel.tag.id
                    ]
                ]
        , MB.view
            { start =
                [ MB.PrimaryButton
                    { tagger = Submit
                    , title = "Submit this form"
                    , icon = Just "fa fa-save"
                    , label = texts.basics.submit
                    }
                , MB.SecondaryButton
                    { tagger = SetViewMode Table
                    , title = texts.basics.backToList
                    , icon = Just "fa fa-arrow-left"
                    , label = texts.basics.cancel
                    }
                ]
            , end =
                if not newTag then
                    [ MB.DeleteButton
                        { tagger = RequestDelete
                        , title = texts.deleteThisTag
                        , icon = Just "fa fa-trash"
                        , label = texts.basics.delete
                        }
                    ]

                else
                    []
            , rootClasses = "mb-4"
            }
        , div
            [ classList
                [ ( "hidden", model.formError == FormErrorNone )
                ]
            , class "my-2"
            , class S.errorMessage
            ]
            [ case model.formError of
                FormErrorNone ->
                    text ""

                FormErrorHttp err ->
                    text (texts.httpError err)

                FormErrorInvalid ->
                    text texts.correctFormErrors

                FormErrorSubmit m ->
                    text m
            ]
        , Html.map FormMsg (Comp.TagForm.view2 texts.tagForm model.tagFormModel)
        , B.loadingDimmer
            { active = model.loading
            , label = texts.basics.loading
            }
        ]
