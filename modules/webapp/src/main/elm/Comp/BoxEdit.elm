{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.BoxEdit exposing
    ( BoxAction(..)
    , Model
    , Msg
    , UpdateResult
    , init
    , update
    , view
    )

import Comp.Basic as B
import Comp.BoxMessageEdit
import Comp.BoxQueryEdit
import Comp.BoxStatsEdit
import Comp.BoxUploadEdit
import Comp.FixedDropdown
import Comp.MenuBar as MB
import Data.Box exposing (Box)
import Data.BoxContent exposing (BoxContent(..))
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (Html, div, i, input, label, text)
import Html.Attributes exposing (class, classList, placeholder, type_, value)
import Html.Events exposing (onInput, onMouseEnter, onMouseLeave)
import Messages.Comp.BoxEdit exposing (Texts)
import Styles as S


type alias Model =
    { box : Box
    , content : ContentModel
    , colspanModel : Comp.FixedDropdown.Model Int
    , focus : Bool
    , deleteRequested : Bool
    }


type ContentModel
    = ContentMessage Comp.BoxMessageEdit.Model
    | ContentQuery Comp.BoxQueryEdit.Model
    | ContentStats Comp.BoxStatsEdit.Model
    | ContentUpload Comp.BoxUploadEdit.Model


type Msg
    = ToggleVisible
    | ToggleDecoration
    | SetName String
    | ColspanMsg (Comp.FixedDropdown.Msg Int)
    | MessageMsg Comp.BoxMessageEdit.Msg
    | UploadMsg Comp.BoxUploadEdit.Msg
    | QueryMsg Comp.BoxQueryEdit.Msg
    | StatsMsg Comp.BoxStatsEdit.Msg
    | SetFocus Bool
    | RequestDelete
    | DeleteBox
    | CancelDelete
    | MoveLeft
    | MoveRight


init : Flags -> Box -> ( Model, Cmd Msg, Sub Msg )
init flags box =
    let
        ( cm, cc, cs ) =
            contentInit flags box.content
    in
    ( { box = box
      , content = cm
      , colspanModel = Comp.FixedDropdown.init [ 1, 2, 3, 4, 5 ]
      , focus = False
      , deleteRequested = False
      }
    , cc
    , cs
    )


contentInit : Flags -> BoxContent -> ( ContentModel, Cmd Msg, Sub Msg )
contentInit flags content =
    case content of
        BoxMessage data ->
            ( ContentMessage (Comp.BoxMessageEdit.init data), Cmd.none, Sub.none )

        BoxUpload data ->
            let
                ( um, uc ) =
                    Comp.BoxUploadEdit.init flags data
            in
            ( ContentUpload um, Cmd.map UploadMsg uc, Sub.none )

        BoxQuery data ->
            let
                ( qm, qc, qs ) =
                    Comp.BoxQueryEdit.init flags data
            in
            ( ContentQuery qm, Cmd.map QueryMsg qc, Sub.map QueryMsg qs )

        BoxStats data ->
            let
                ( qm, qc, qs ) =
                    Comp.BoxStatsEdit.init flags data
            in
            ( ContentStats qm, Cmd.map StatsMsg qc, Sub.map StatsMsg qs )



--- Update


type BoxAction
    = BoxNoAction
    | BoxMoveLeft
    | BoxMoveRight
    | BoxDelete


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    , action : BoxAction
    }


update : Flags -> Msg -> Model -> UpdateResult
update flags msg model =
    case msg of
        MessageMsg lm ->
            case model.content of
                ContentMessage m ->
                    let
                        ( mm, data ) =
                            Comp.BoxMessageEdit.update lm m

                        boxn =
                            model.box

                        box_ =
                            { boxn | content = BoxMessage data }
                    in
                    { model = { model | content = ContentMessage mm, box = box_ }
                    , cmd = Cmd.none
                    , sub = Sub.none
                    , action = BoxNoAction
                    }

                _ ->
                    unit model

        UploadMsg lm ->
            case model.content of
                ContentUpload m ->
                    let
                        ( um, data ) =
                            Comp.BoxUploadEdit.update lm m

                        boxn =
                            model.box

                        box_ =
                            { boxn | content = BoxUpload data }
                    in
                    { model = { model | content = ContentUpload um, box = box_ }
                    , cmd = Cmd.none
                    , sub = Sub.none
                    , action = BoxNoAction
                    }

                _ ->
                    unit model

        QueryMsg lm ->
            case model.content of
                ContentQuery m ->
                    let
                        result =
                            Comp.BoxQueryEdit.update flags lm m

                        boxn =
                            model.box

                        box_ =
                            { boxn | content = BoxQuery result.data }
                    in
                    { model = { model | content = ContentQuery result.model, box = box_ }
                    , cmd = Cmd.map QueryMsg result.cmd
                    , sub = Sub.map QueryMsg result.sub
                    , action = BoxNoAction
                    }

                _ ->
                    unit model

        StatsMsg lm ->
            case model.content of
                ContentStats m ->
                    let
                        result =
                            Comp.BoxStatsEdit.update flags lm m

                        boxn =
                            model.box

                        box_ =
                            { boxn | content = BoxStats result.data }
                    in
                    { model = { model | content = ContentStats result.model, box = box_ }
                    , cmd = Cmd.map StatsMsg result.cmd
                    , sub = Sub.map StatsMsg result.sub
                    , action = BoxNoAction
                    }

                _ ->
                    unit model

        ColspanMsg lm ->
            let
                ( cm, num ) =
                    Comp.FixedDropdown.update lm model.colspanModel

                boxn =
                    model.box

                box_ =
                    { boxn | colspan = Maybe.withDefault boxn.colspan num }
            in
            unit { model | box = box_, colspanModel = cm }

        ToggleVisible ->
            let
                box =
                    model.box

                box_ =
                    { box | visible = not box.visible }
            in
            unit { model | box = box_ }

        ToggleDecoration ->
            let
                box =
                    model.box

                box_ =
                    { box | decoration = not box.decoration }
            in
            unit { model | box = box_ }

        SetName name ->
            let
                box =
                    model.box

                box_ =
                    { box | name = name }
            in
            unit { model | box = box_ }

        SetFocus flag ->
            unit { model | focus = flag }

        RequestDelete ->
            unit { model | deleteRequested = True }

        DeleteBox ->
            UpdateResult model Cmd.none Sub.none BoxDelete

        CancelDelete ->
            unit { model | deleteRequested = False }

        MoveLeft ->
            UpdateResult model Cmd.none Sub.none BoxMoveLeft

        MoveRight ->
            UpdateResult model Cmd.none Sub.none BoxMoveRight


unit : Model -> UpdateResult
unit model =
    UpdateResult model Cmd.none Sub.none BoxNoAction



--- View


view : Texts -> Flags -> UiSettings -> Model -> Html Msg
view texts flags settings model =
    div
        [ class (S.box ++ "rounded md:relative")
        , class " h-full"
        , classList [ ( "ring ring-opacity-50 ring-blue-600 dark:ring-sky-600", model.focus ) ]
        , onMouseEnter (SetFocus True)
        , onMouseLeave (SetFocus False)
        ]
        [ B.contentDimmer model.deleteRequested
            (div [ class "flex flex-col" ]
                [ div [ class "text-xl" ]
                    [ i [ class "fa fa-info-circle mr-2" ] []
                    , text texts.reallyDeleteBox
                    ]
                , div [ class "mt-4 flex flex-row items-center space-x-2" ]
                    [ MB.viewItem <|
                        MB.DeleteButton
                            { tagger = DeleteBox
                            , title = ""
                            , label = texts.basics.yes
                            , icon = Just "fa fa-check"
                            }
                    , MB.viewItem <|
                        MB.SecondaryButton
                            { tagger = CancelDelete
                            , title = ""
                            , label = texts.basics.no
                            , icon = Just "fa fa-times"
                            }
                    ]
                ]
            )
        , boxHeader texts model
        , formHeader (texts.boxContent.forContent model.box.content)
        , div [ class "mb-4 pl-2" ]
            [ metaForm texts flags model
            ]
        , formHeader texts.contentProperties
        , div [ class "pl-4 pr-2 py-2 h-5/6" ]
            [ boxContent texts flags settings model
            ]
        ]


formHeader : String -> Html msg
formHeader heading =
    div
        [ class "mx-2 border-b dark:border-slate-500 text-lg mt-1"
        ]
        [ text heading
        ]


metaForm : Texts -> Flags -> Model -> Html Msg
metaForm texts _ model =
    let
        colspanCfg =
            { display = String.fromInt
            , icon = \_ -> Nothing
            , selectPlaceholder = ""
            , style = DS.mainStyle
            }
    in
    div [ class "my-1 px-2 " ]
        [ div []
            [ label [ class S.inputLabel ]
                [ text texts.basics.name
                ]
            , input
                [ type_ "text"
                , placeholder texts.namePlaceholder
                , class S.textInput
                , value model.box.name
                , onInput SetName
                ]
                []
            ]
        , div [ class "mt-1" ]
            [ MB.viewItem <|
                MB.Checkbox
                    { tagger = \_ -> ToggleVisible
                    , label = texts.visible
                    , value = model.box.visible
                    , id = ""
                    }
            ]
        , div [ class "mt-1" ]
            [ MB.viewItem <|
                MB.Checkbox
                    { tagger = \_ -> ToggleDecoration
                    , label = texts.decorations
                    , value = model.box.decoration
                    , id = ""
                    }
            ]
        , div [ class "mt-1" ]
            [ label [ class S.inputLabel ]
                [ text texts.colspan ]
            , Html.map ColspanMsg
                (Comp.FixedDropdown.viewStyled2
                    colspanCfg
                    False
                    (Just model.box.colspan)
                    model.colspanModel
                )
            ]
        ]


boxHeader : Texts -> Model -> Html Msg
boxHeader texts model =
    div
        [ class "flex flex-row py-1 bg-blue-50 dark:bg-slate-700 rounded-t"
        ]
        [ div [ class "flex flex-row items-center text-lg tracking-medium italic px-2" ]
            [ i
                [ class (Data.Box.boxIcon model.box)
                , class "mr-2"
                ]
                []
            , text model.box.name
            ]
        , div [ class "flex flex-grow justify-end pr-1" ]
            [ MB.viewItem <|
                MB.CustomButton
                    { tagger = MoveLeft
                    , title = texts.moveToLeft
                    , label = ""
                    , icon = Just "fa fa-arrow-left"
                    , inputClass =
                        [ ( S.secondaryBasicButton, True )
                        , ( "text-xs", True )
                        ]
                    }
            , MB.viewItem <|
                MB.CustomButton
                    { tagger = MoveRight
                    , title = texts.moveToRight
                    , label = ""
                    , icon = Just "fa fa-arrow-right"
                    , inputClass =
                        [ ( S.secondaryBasicButton, True )
                        , ( "text-xs mr-3", True )
                        ]
                    }
            , MB.viewItem <|
                MB.CustomButton
                    { tagger = RequestDelete
                    , title = texts.deleteBox
                    , label = ""
                    , icon = Just "fa fa-trash"
                    , inputClass =
                        [ ( S.deleteButton, True )
                        , ( "text-xs", True )
                        ]
                    }
            ]
        ]


boxContent : Texts -> Flags -> UiSettings -> Model -> Html Msg
boxContent texts flags settings model =
    case model.content of
        ContentMessage m ->
            Html.map MessageMsg
                (Comp.BoxMessageEdit.view texts.messageEdit m)

        ContentUpload m ->
            Html.map UploadMsg
                (Comp.BoxUploadEdit.view texts.uploadEdit m)

        ContentQuery m ->
            Html.map QueryMsg
                (Comp.BoxQueryEdit.view texts.queryEdit settings m)

        ContentStats m ->
            Html.map StatsMsg
                (Comp.BoxStatsEdit.view texts.statsEdit settings m)
