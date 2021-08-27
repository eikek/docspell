{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Comp.SourceForm exposing
    ( Model
    , Msg(..)
    , getSource
    , init
    , isValid
    , update
    , view2
    )

import Api
import Api.Model.FolderItem exposing (FolderItem)
import Api.Model.FolderList exposing (FolderList)
import Api.Model.IdName exposing (IdName)
import Api.Model.SourceAndTags exposing (SourceAndTags)
import Api.Model.Tag exposing (Tag)
import Api.Model.TagList exposing (TagList)
import Comp.Basic as B
import Comp.Dropdown exposing (isDropdownChangeMsg)
import Comp.FixedDropdown
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Data.FolderOrder
import Data.Language exposing (Language)
import Data.Priority exposing (Priority)
import Data.TagOrder
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onInput)
import Http
import Markdown
import Messages.Comp.SourceForm exposing (Texts)
import Styles as S
import Util.Folder exposing (mkFolderOption)
import Util.Maybe
import Util.Tag
import Util.Update


type alias Model =
    { source : SourceAndTags
    , abbrev : String
    , description : Maybe String
    , priorityModel : Comp.FixedDropdown.Model Priority
    , priority : Priority
    , enabled : Bool
    , folderModel : Comp.Dropdown.Model IdName
    , allFolders : List FolderItem
    , folderId : Maybe String
    , tagModel : Comp.Dropdown.Model Tag
    , fileFilter : Maybe String
    , languageModel : Comp.Dropdown.Model Language
    , language : Maybe String
    , attachmentsOnly : Bool
    }


emptyModel : Model
emptyModel =
    { source = Api.Model.SourceAndTags.empty
    , abbrev = ""
    , description = Nothing
    , priorityModel =
        Comp.FixedDropdown.init Data.Priority.all
    , priority = Data.Priority.Low
    , enabled = False
    , folderModel = Comp.Dropdown.makeSingle
    , allFolders = []
    , folderId = Nothing
    , tagModel = Util.Tag.makeDropdownModel
    , fileFilter = Nothing
    , languageModel =
        Comp.Dropdown.makeSingleList
            { options = Data.Language.all
            , selected = Nothing
            }
    , language = Nothing
    , attachmentsOnly = False
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( emptyModel
    , Cmd.batch
        [ Api.getFolders flags "" Data.FolderOrder.NameAsc False GetFolderResp
        , Api.getTags flags "" Data.TagOrder.NameAsc GetTagResp
        ]
    )


isValid : Model -> Bool
isValid model =
    model.abbrev /= ""


getSource : Model -> SourceAndTags
getSource model =
    let
        st =
            model.source

        s =
            st.source

        tags =
            Comp.Dropdown.getSelected model.tagModel

        n =
            { s
                | abbrev = model.abbrev
                , description = model.description
                , enabled = model.enabled
                , priority = Data.Priority.toName model.priority
                , folder = model.folderId
                , fileFilter = model.fileFilter
                , language = model.language
                , attachmentsOnly = model.attachmentsOnly
            }
    in
    { st | source = n, tags = TagList (List.length tags) tags }


type Msg
    = SetAbbrev String
    | SetSource SourceAndTags
    | SetDescr String
    | ToggleEnabled
    | PrioDropdownMsg (Comp.FixedDropdown.Msg Priority)
    | GetFolderResp (Result Http.Error FolderList)
    | FolderDropdownMsg (Comp.Dropdown.Msg IdName)
    | GetTagResp (Result Http.Error TagList)
    | TagDropdownMsg (Comp.Dropdown.Msg Tag)
    | SetFileFilter String
    | LanguageMsg (Comp.Dropdown.Msg Language)
    | ToggleAttachmentsOnly



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        SetSource t ->
            let
                stpost =
                    model.source

                post =
                    stpost.source

                np =
                    { post
                        | id = t.source.id
                        , abbrev = t.source.abbrev
                        , description = t.source.description
                        , priority = t.source.priority
                        , enabled = t.source.enabled
                        , folder = t.source.folder
                        , fileFilter = t.source.fileFilter
                        , language = t.source.language
                    }

                newModel =
                    { model
                        | source = { stpost | source = np }
                        , abbrev = t.source.abbrev
                        , description = t.source.description
                        , priority =
                            Data.Priority.fromString t.source.priority
                                |> Maybe.withDefault Data.Priority.Low
                        , enabled = t.source.enabled
                        , folderId = t.source.folder
                        , fileFilter = t.source.fileFilter
                        , language = t.source.language
                    }

                mkIdName id =
                    List.filterMap
                        (\f ->
                            if f.id == id then
                                Just (IdName id f.name)

                            else
                                Nothing
                        )
                        model.allFolders

                sel =
                    case Maybe.map mkIdName t.source.folder of
                        Just idref ->
                            idref

                        Nothing ->
                            []

                langSel =
                    case Maybe.andThen Data.Language.fromString t.source.language of
                        Just lang ->
                            [ lang ]

                        Nothing ->
                            []

                tags =
                    Comp.Dropdown.SetSelection t.tags.items
            in
            Util.Update.andThen1
                [ update flags (FolderDropdownMsg (Comp.Dropdown.SetSelection sel))
                , update flags (TagDropdownMsg tags)
                , update flags (LanguageMsg (Comp.Dropdown.SetSelection langSel))
                ]
                newModel

        ToggleEnabled ->
            ( { model | enabled = not model.enabled }, Cmd.none )

        ToggleAttachmentsOnly ->
            ( { model | attachmentsOnly = not model.attachmentsOnly }, Cmd.none )

        SetAbbrev n ->
            ( { model | abbrev = n }, Cmd.none )

        SetDescr d ->
            ( { model | description = Util.Maybe.fromString d }
            , Cmd.none
            )

        PrioDropdownMsg m ->
            let
                ( m2, p2 ) =
                    Comp.FixedDropdown.update m model.priorityModel
            in
            ( { model
                | priorityModel = m2
                , priority = Maybe.withDefault model.priority p2
              }
            , Cmd.none
            )

        GetFolderResp (Ok fs) ->
            let
                model_ =
                    { model | allFolders = fs.items }

                mkIdName fitem =
                    IdName fitem.id fitem.name

                opts =
                    fs.items
                        |> List.map mkIdName
                        |> Comp.Dropdown.SetOptions
            in
            update flags (FolderDropdownMsg opts) model_

        GetFolderResp (Err _) ->
            ( model, Cmd.none )

        FolderDropdownMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.folderModel

                newModel =
                    { model | folderModel = m2 }

                idref =
                    Comp.Dropdown.getSelected m2 |> List.head

                model_ =
                    if isDropdownChangeMsg m then
                        { newModel | folderId = Maybe.map .id idref }

                    else
                        newModel
            in
            ( model_, Cmd.map FolderDropdownMsg c2 )

        GetTagResp (Ok list) ->
            let
                opts =
                    Comp.Dropdown.SetOptions list.items
            in
            update flags (TagDropdownMsg opts) model

        GetTagResp (Err _) ->
            ( model, Cmd.none )

        TagDropdownMsg lm ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update lm model.tagModel

                newModel =
                    { model | tagModel = m2 }
            in
            ( newModel, Cmd.map TagDropdownMsg c2 )

        SetFileFilter d ->
            ( { model | fileFilter = Util.Maybe.fromString d }
            , Cmd.none
            )

        LanguageMsg lm ->
            let
                ( dm, dc ) =
                    Comp.Dropdown.update lm model.languageModel

                newModel =
                    { model | languageModel = dm }

                lang =
                    Comp.Dropdown.getSelected dm |> List.head

                model_ =
                    if isDropdownChangeMsg lm then
                        { newModel | language = Maybe.map Data.Language.toIso3 lang }

                    else
                        newModel
            in
            ( model_
            , Cmd.map LanguageMsg dc
            )



--- View2


view2 : Flags -> Texts -> UiSettings -> Model -> Html Msg
view2 flags texts settings model =
    let
        folderCfg =
            { makeOption = mkFolderOption flags model.allFolders
            , placeholder = texts.basics.selectPlaceholder
            , labelColor = \_ -> \_ -> ""
            , style = DS.mainStyle
            }

        tagCfg =
            Util.Tag.tagSettings texts.basics.chooseTag DS.mainStyle

        languageCfg =
            { makeOption =
                \a ->
                    { text = texts.languageLabel a
                    , additional = ""
                    }
            , placeholder = texts.basics.selectPlaceholder
            , labelColor = \_ -> \_ -> ""
            , style = DS.mainStyle
            }

        priorityCfg =
            { display = Data.Priority.toName
            , icon = \_ -> Nothing
            , style = DS.mainStyle
            , selectPlaceholder = texts.basics.selectPlaceholder
            }
    in
    div [ class "flex flex-col" ]
        [ div [ class "mb-4" ]
            [ label
                [ for "source-abbrev"
                , class S.inputLabel
                ]
                [ text texts.basics.name
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , id "source-abbrev"
                , onInput SetAbbrev
                , placeholder texts.basics.name
                , value model.abbrev
                , class S.textInput
                , classList [ ( S.inputErrorBorder, not (isValid model) ) ]
                ]
                []
            ]
        , div [ class "mb-4" ]
            [ label
                [ for "source-descr"
                , class S.inputLabel
                ]
                [ text texts.description
                ]
            , textarea
                [ onInput SetDescr
                , model.description |> Maybe.withDefault "" |> value
                , rows 3
                , class S.textAreaInput
                , id "source-descr"
                ]
                []
            ]
        , div [ class "mb-4" ]
            [ label
                [ class "inline-flex items-center"
                , for "source-enabled"
                ]
                [ input
                    [ type_ "checkbox"
                    , onCheck (\_ -> ToggleEnabled)
                    , checked model.enabled
                    , class S.checkboxInput
                    , id "source-enabled"
                    ]
                    []
                , span [ class "ml-2" ]
                    [ text texts.enabled
                    ]
                ]
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text texts.priority
                ]
            , Html.map PrioDropdownMsg
                (Comp.FixedDropdown.viewStyled2
                    priorityCfg
                    False
                    (Just model.priority)
                    model.priorityModel
                )
            , div [ class "opacity-50 text-sm" ]
                [ text texts.priorityInfo
                ]
            ]
        , div
            [ class S.header2
            , class "mt-6"
            ]
            [ text texts.metadata
            ]
        , div
            [ class S.message
            , class "mb-4"
            ]
            [ text texts.metadataInfoText
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text texts.basics.folder
                ]
            , Html.map FolderDropdownMsg
                (Comp.Dropdown.view2
                    folderCfg
                    settings
                    model.folderModel
                )
            , div [ class "opacity-50 text-sm" ]
                [ text texts.folderInfo
                ]
            , div
                [ classList
                    [ ( "hidden", isFolderMember2 model )
                    ]
                , class S.message
                ]
                [ Markdown.toHtml [] texts.basics.folderNotOwnerWarning
                ]
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text texts.basics.tags
                ]
            , Html.map TagDropdownMsg
                (Comp.Dropdown.view2
                    tagCfg
                    settings
                    model.tagModel
                )
            , div [ class "opacity-50 text-sm" ]
                [ text texts.tagsInfo
                ]
            ]
        , div
            [ class "mb-4"
            ]
            [ label [ class S.inputLabel ]
                [ text texts.fileFilter ]
            , input
                [ type_ "text"
                , onInput SetFileFilter
                , placeholder texts.fileFilter
                , model.fileFilter
                    |> Maybe.withDefault ""
                    |> value
                , class S.textInput
                ]
                []
            , div [ class "opacity-50 text-sm" ]
                [ Markdown.toHtml [] texts.fileFilterInfo
                ]
            ]
        , div [ class "mb-4" ]
            [ label
                [ class "inline-flex items-center"
                , for "attachments-only"
                ]
                [ input
                    [ type_ "checkbox"
                    , onCheck (\_ -> ToggleAttachmentsOnly)
                    , checked model.attachmentsOnly
                    , class S.checkboxInput
                    , id "attachments-only"
                    ]
                    []
                , span [ class "ml-2" ]
                    [ text texts.attachmentsOnly
                    ]
                ]
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text (texts.language ++ ":")
                ]
            , Html.map LanguageMsg
                (Comp.Dropdown.view2
                    languageCfg
                    settings
                    model.languageModel
                )
            , div [ class "opacity-50 text-sm" ]
                [ text texts.languageInfo
                ]
            ]
        ]


isFolderMember2 : Model -> Bool
isFolderMember2 model =
    let
        selected =
            Comp.Dropdown.getSelected model.folderModel
                |> List.head
                |> Maybe.map .id
    in
    Util.Folder.isFolderMember model.allFolders selected
