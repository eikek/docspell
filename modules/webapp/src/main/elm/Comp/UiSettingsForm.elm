{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Comp.UiSettingsForm exposing
    ( Model
    , Msg
    , init
    , update
    , view2
    )

import Api
import Api.Model.TagList exposing (TagList)
import Comp.BasicSizeField
import Comp.ColorTagger
import Comp.FieldListSelect
import Comp.FixedDropdown
import Comp.IntField
import Comp.MenuBar as MB
import Comp.Tabs
import Data.BasicSize exposing (BasicSize)
import Data.Color exposing (Color)
import Data.DropdownStyle as DS
import Data.Fields exposing (Field)
import Data.Flags exposing (Flags)
import Data.ItemTemplate as IT exposing (ItemTemplate)
import Data.UiSettings exposing (ItemPattern, Pos(..), UiSettings)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Markdown
import Messages
import Messages.Comp.UiSettingsForm exposing (Texts)
import Messages.UiLanguage exposing (UiLanguage)
import Set exposing (Set)
import Styles as S
import Util.Maybe
import Util.Tag


type alias Model =
    { itemSearchPageSize : Maybe Int
    , searchPageSizeModel : Comp.IntField.Model
    , tagColors : Dict String Color
    , tagColorModel : Comp.ColorTagger.Model
    , nativePdfPreview : Bool
    , itemSearchNoteLength : Maybe Int
    , searchNoteLengthModel : Comp.IntField.Model
    , searchMenuFolderCount : Maybe Int
    , searchMenuFolderCountModel : Comp.IntField.Model
    , searchMenuTagCount : Maybe Int
    , searchMenuTagCountModel : Comp.IntField.Model
    , searchMenuTagCatCount : Maybe Int
    , searchMenuTagCatCountModel : Comp.IntField.Model
    , formFields : List Field
    , itemDetailShortcuts : Bool
    , cardPreviewSize : BasicSize
    , cardTitlePattern : PatternModel
    , cardSubtitlePattern : PatternModel
    , showPatternHelp : Bool
    , searchStatsVisible : Bool
    , sideMenuVisible : Bool
    , powerSearchEnabled : Bool
    , uiLangModel : Comp.FixedDropdown.Model UiLanguage
    , uiLang : UiLanguage
    , openTabs : Set String
    }


type alias PatternModel =
    { pattern : Maybe String
    , current : ItemTemplate
    , result : Result String ItemTemplate
    }


initPatternModel : ItemPattern -> PatternModel
initPatternModel ip =
    { pattern = Just ip.pattern
    , current = ip.template
    , result = Ok ip.template
    }


updatePatternModel : PatternModel -> String -> PatternModel
updatePatternModel pm str =
    let
        result =
            case IT.readTemplate str of
                Just t ->
                    Ok t

                Nothing ->
                    Err "Template invalid, check for unclosed variables."

        p =
            Util.Maybe.fromString str
    in
    { pattern = p
    , current = Result.withDefault pm.current result
    , result = result
    }


init : Flags -> UiSettings -> ( Model, Cmd Msg )
init flags settings =
    ( { itemSearchPageSize = Just settings.itemSearchPageSize
      , searchPageSizeModel =
            Comp.IntField.init
                (Just 10)
                (Just flags.config.maxPageSize)
                False
      , tagColors = settings.tagCategoryColors
      , tagColorModel =
            Comp.ColorTagger.init
                []
                Data.Color.all
      , nativePdfPreview = settings.nativePdfPreview
      , itemSearchNoteLength = Just settings.itemSearchNoteLength
      , searchNoteLengthModel =
            Comp.IntField.init
                (Just 0)
                (Just flags.config.maxNoteLength)
                False
      , searchMenuFolderCount = Just settings.searchMenuFolderCount
      , searchMenuFolderCountModel =
            Comp.IntField.init
                (Just 0)
                (Just 2000)
                False
      , searchMenuTagCount = Just settings.searchMenuTagCount
      , searchMenuTagCountModel =
            Comp.IntField.init
                (Just 0)
                (Just 2000)
                False
      , searchMenuTagCatCount = Just settings.searchMenuTagCatCount
      , searchMenuTagCatCountModel =
            Comp.IntField.init
                (Just 0)
                (Just 2000)
                False
      , formFields = settings.formFields
      , itemDetailShortcuts = settings.itemDetailShortcuts
      , cardPreviewSize = settings.cardPreviewSize
      , cardTitlePattern = initPatternModel settings.cardTitleTemplate
      , cardSubtitlePattern = initPatternModel settings.cardSubtitleTemplate
      , showPatternHelp = False
      , searchStatsVisible = settings.searchStatsVisible
      , sideMenuVisible = settings.sideMenuVisible
      , powerSearchEnabled = settings.powerSearchEnabled
      , uiLang = settings.uiLang
      , uiLangModel =
            Comp.FixedDropdown.init Messages.UiLanguage.all
      , openTabs = Set.empty
      }
    , Api.getTags flags "" GetTagsResp
    )


type Msg
    = SearchPageSizeMsg Comp.IntField.Msg
    | TagColorMsg Comp.ColorTagger.Msg
    | GetTagsResp (Result Http.Error TagList)
    | TogglePdfPreview
    | NoteLengthMsg Comp.IntField.Msg
    | SearchMenuFolderMsg Comp.IntField.Msg
    | SearchMenuTagMsg Comp.IntField.Msg
    | SearchMenuTagCatMsg Comp.IntField.Msg
    | FieldListMsg Comp.FieldListSelect.Msg
    | ToggleItemDetailShortcuts
    | CardPreviewSizeMsg Comp.BasicSizeField.Msg
    | SetCardTitlePattern String
    | SetCardSubtitlePattern String
    | TogglePatternHelpMsg
    | ToggleSearchStatsVisible
    | ToggleAkkordionTab String
    | ToggleSideMenuVisible
    | TogglePowerSearch
    | UiLangMsg (Comp.FixedDropdown.Msg UiLanguage)



--- Update


update : UiSettings -> Msg -> Model -> ( Model, Maybe UiSettings )
update sett msg model =
    case msg of
        SearchPageSizeMsg lm ->
            let
                ( m, n ) =
                    Comp.IntField.update lm model.searchPageSizeModel

                nextSettings =
                    Maybe.map (\sz -> { sett | itemSearchPageSize = sz }) n

                model_ =
                    { model
                        | searchPageSizeModel = m
                        , itemSearchPageSize = n
                    }
            in
            ( model_, nextSettings )

        NoteLengthMsg lm ->
            let
                ( m, n ) =
                    Comp.IntField.update lm model.searchNoteLengthModel

                nextSettings =
                    Maybe.map (\len -> { sett | itemSearchNoteLength = len }) n

                model_ =
                    { model
                        | searchNoteLengthModel = m
                        , itemSearchNoteLength = n
                    }
            in
            ( model_, nextSettings )

        SearchMenuFolderMsg lm ->
            let
                ( m, n ) =
                    Comp.IntField.update lm model.searchMenuFolderCountModel

                nextSettings =
                    Maybe.map (\len -> { sett | searchMenuFolderCount = len }) n

                model_ =
                    { model
                        | searchMenuFolderCountModel = m
                        , searchMenuFolderCount = n
                    }
            in
            ( model_, nextSettings )

        SearchMenuTagMsg lm ->
            let
                ( m, n ) =
                    Comp.IntField.update lm model.searchMenuTagCountModel

                nextSettings =
                    Maybe.map (\len -> { sett | searchMenuTagCount = len }) n

                model_ =
                    { model
                        | searchMenuTagCountModel = m
                        , searchMenuTagCount = n
                    }
            in
            ( model_, nextSettings )

        SearchMenuTagCatMsg lm ->
            let
                ( m, n ) =
                    Comp.IntField.update lm model.searchMenuTagCatCountModel

                nextSettings =
                    Maybe.map (\len -> { sett | searchMenuTagCatCount = len }) n

                model_ =
                    { model
                        | searchMenuTagCatCountModel = m
                        , searchMenuTagCatCount = n
                    }
            in
            ( model_, nextSettings )

        TagColorMsg lm ->
            let
                ( m_, d_ ) =
                    Comp.ColorTagger.update lm model.tagColorModel

                nextSettings =
                    Maybe.map (\tc -> { sett | tagCategoryColors = tc }) d_

                model_ =
                    { model
                        | tagColorModel = m_
                        , tagColors = Maybe.withDefault model.tagColors d_
                    }
            in
            ( model_, nextSettings )

        TogglePdfPreview ->
            let
                flag =
                    not model.nativePdfPreview
            in
            ( { model | nativePdfPreview = flag }
            , Just { sett | nativePdfPreview = flag }
            )

        GetTagsResp (Ok tl) ->
            let
                categories =
                    Util.Tag.getCategories tl.items
            in
            ( { model
                | tagColorModel =
                    Comp.ColorTagger.init
                        categories
                        Data.Color.all
              }
            , Nothing
            )

        GetTagsResp (Err _) ->
            ( model, Nothing )

        FieldListMsg lm ->
            let
                selected =
                    Comp.FieldListSelect.update lm model.formFields

                newSettings =
                    { sett | formFields = selected }
            in
            ( { model | formFields = selected }
            , if selected /= model.formFields then
                Just newSettings

              else
                Nothing
            )

        ToggleItemDetailShortcuts ->
            let
                flag =
                    not model.itemDetailShortcuts
            in
            ( { model | itemDetailShortcuts = flag }
            , Just { sett | itemDetailShortcuts = flag }
            )

        CardPreviewSizeMsg lm ->
            let
                next =
                    Comp.BasicSizeField.update lm
                        |> Maybe.withDefault model.cardPreviewSize

                newSettings =
                    if next /= model.cardPreviewSize then
                        Just { sett | cardPreviewSize = next }

                    else
                        Nothing
            in
            ( { model | cardPreviewSize = next }
            , newSettings
            )

        SetCardTitlePattern str ->
            let
                pm =
                    model.cardTitlePattern

                pm_ =
                    updatePatternModel pm str

                newSettings =
                    if pm_.pattern /= Just sett.cardTitleTemplate.pattern then
                        Just
                            { sett
                                | cardTitleTemplate =
                                    ItemPattern
                                        (Maybe.withDefault "" pm_.pattern)
                                        pm_.current
                            }

                    else
                        Nothing
            in
            ( { model | cardTitlePattern = pm_ }, newSettings )

        SetCardSubtitlePattern str ->
            let
                pm =
                    model.cardSubtitlePattern

                pm_ =
                    updatePatternModel pm str

                newSettings =
                    if pm_.pattern /= Just sett.cardSubtitleTemplate.pattern then
                        Just
                            { sett
                                | cardSubtitleTemplate =
                                    ItemPattern
                                        (Maybe.withDefault "" pm_.pattern)
                                        pm_.current
                            }

                    else
                        Nothing
            in
            ( { model | cardSubtitlePattern = pm_ }, newSettings )

        TogglePatternHelpMsg ->
            ( { model | showPatternHelp = not model.showPatternHelp }, Nothing )

        ToggleSearchStatsVisible ->
            let
                flag =
                    not model.searchStatsVisible
            in
            ( { model | searchStatsVisible = flag }
            , Just { sett | searchStatsVisible = flag }
            )

        ToggleAkkordionTab name ->
            let
                tabs =
                    if Set.member name model.openTabs then
                        Set.remove name model.openTabs

                    else
                        Set.insert name model.openTabs
            in
            ( { model | openTabs = tabs }
            , Nothing
            )

        ToggleSideMenuVisible ->
            let
                next =
                    not model.sideMenuVisible
            in
            ( { model | sideMenuVisible = next }
            , Just { sett | sideMenuVisible = next }
            )

        TogglePowerSearch ->
            let
                next =
                    not model.powerSearchEnabled
            in
            ( { model | powerSearchEnabled = next }
            , Just { sett | powerSearchEnabled = next }
            )

        UiLangMsg lm ->
            let
                ( m, sel ) =
                    Comp.FixedDropdown.update lm model.uiLangModel

                newLang =
                    Maybe.withDefault model.uiLang sel
            in
            ( { model | uiLangModel = m, uiLang = newLang }
            , if newLang == model.uiLang then
                Nothing

              else
                Just { sett | uiLang = newLang }
            )



--- View2


tagColorViewOpts2 : Texts -> Comp.ColorTagger.ViewOpts
tagColorViewOpts2 texts =
    { renderItem =
        \( name, v ) ->
            span [ class "flex inline-flex items-center" ]
                [ span [ class "mr-2" ] [ text name ]
                , span [ class (" label " ++ Data.Color.toString2 v) ]
                    [ text (texts.colorLabel v)
                    ]
                ]
    , colorLabel = texts.colorLabel
    , label = texts.chooseTagColorLabel
    , description = Just texts.tagColorDescription
    , selectPlaceholder = texts.basics.selectPlaceholder
    }


view2 : Texts -> Flags -> UiSettings -> Model -> Html Msg
view2 texts flags settings model =
    let
        state tab =
            if Set.member tab.name model.openTabs then
                { folded = Comp.Tabs.Open
                , look = Comp.Tabs.Normal
                }

            else
                { folded = Comp.Tabs.Closed
                , look = Comp.Tabs.Normal
                }
    in
    div [ class "flex flex-col" ]
        [ Comp.Tabs.akkordion
            Comp.Tabs.defaultStyle
            (\t -> ( state t, ToggleAkkordionTab t.name ))
            (settingFormTabs texts flags settings model)
        ]


settingFormTabs : Texts -> Flags -> UiSettings -> Model -> List (Comp.Tabs.Tab Msg)
settingFormTabs texts flags _ model =
    let
        langCfg =
            { display = \lang -> Messages.get lang |> .label
            , icon = \lang -> Just (Messages.get lang |> .flagIcon)
            , style = DS.mainStyle
            , selectPlaceholder = texts.basics.selectPlaceholder
            }
    in
    [ { name = "general"
      , title = texts.general
      , titleRight = []
      , info = Nothing
      , body =
            [ div [ class "mb-4 " ]
                [ MB.viewItem <|
                    MB.Checkbox
                        { id = "uisetting-sidemenu-visible"
                        , label = texts.showSideMenuByDefault
                        , tagger = \_ -> ToggleSideMenuVisible
                        , value = model.sideMenuVisible
                        }
                ]
            , div [ class "mb-4" ]
                [ label [ class S.inputLabel ] [ text texts.uiLanguage ]
                , Html.map UiLangMsg
                    (Comp.FixedDropdown.viewStyled2
                        langCfg
                        False
                        (Just model.uiLang)
                        model.uiLangModel
                    )
                ]
            ]
      }
    , { name = "item-search"
      , title = texts.itemSearch
      , titleRight = []
      , info = Nothing
      , body =
            [ Html.map SearchPageSizeMsg
                (Comp.IntField.view
                    { label = texts.maxResultsPerPage
                    , info = texts.maxResultsPerPageInfo flags.config.maxPageSize
                    , number = model.itemSearchPageSize
                    , classes = "mb-4"
                    }
                    model.searchPageSizeModel
                )
            , div [ class "mb-4" ]
                [ MB.viewItem <|
                    MB.Checkbox
                        { id = "uisetting-searchstats-visible"
                        , value = model.searchStatsVisible
                        , tagger = \_ -> ToggleSearchStatsVisible
                        , label = texts.showBasicSearchStatsByDefault
                        }
                ]
            , div [ class "mb-4" ]
                [ MB.viewItem <|
                    MB.Checkbox
                        { id = "uisetting-powersearch-enabled"
                        , value = model.powerSearchEnabled
                        , tagger = \_ -> TogglePowerSearch
                        , label = texts.enablePowerSearch
                        }
                ]
            ]
      }
    , { name = "item-cards"
      , title = texts.itemCards
      , titleRight = []
      , info = Nothing
      , body =
            [ Html.map NoteLengthMsg
                (Comp.IntField.view
                    { label = texts.maxNoteSize
                    , info = texts.maxNoteSizeInfo flags.config.maxNoteLength
                    , number = model.itemSearchNoteLength
                    , classes = "mb-4"
                    }
                    model.searchNoteLengthModel
                )
            , Html.map CardPreviewSizeMsg
                (Comp.BasicSizeField.view2
                    "mb-4"
                    texts.sizeOfItemPreview
                    model.cardPreviewSize
                )
            , div [ class "mb-4" ]
                [ label [ class S.inputLabel ]
                    [ text texts.cardTitlePattern
                    , a
                        [ class "float-right"
                        , class S.link
                        , title texts.togglePatternHelpText
                        , href "#"
                        , onClick TogglePatternHelpMsg
                        ]
                        [ i [ class "fa fa-question" ] []
                        ]
                    ]
                , input
                    [ type_ "text"
                    , Maybe.withDefault "" model.cardTitlePattern.pattern |> value
                    , onInput SetCardTitlePattern
                    , class S.textInput
                    ]
                    []
                ]
            , div [ class "mb-4" ]
                [ label [ class S.inputLabel ]
                    [ text texts.cardSubtitlePattern
                    , a
                        [ class "float-right"
                        , class S.link
                        , title texts.togglePatternHelpText
                        , href "#"
                        , onClick TogglePatternHelpMsg
                        ]
                        [ i [ class "fa fa-question" ] []
                        ]
                    ]
                , input
                    [ type_ "text"
                    , Maybe.withDefault "" model.cardSubtitlePattern.pattern |> value
                    , onInput SetCardSubtitlePattern
                    , class S.textInput
                    ]
                    []
                ]
            , Markdown.toHtml
                [ classList
                    [ ( "hidden", not model.showPatternHelp )
                    ]
                , class S.message
                , class "markdown-preview"
                ]
                texts.templateHelpMessage
            ]
      }
    , { name = "search-menu"
      , title = texts.searchMenu
      , titleRight = []
      , info = Nothing
      , body =
            [ Html.map SearchMenuTagMsg
                (Comp.IntField.view
                    { label = texts.searchMenuTagCount
                    , info = texts.searchMenuTagCountInfo
                    , number = model.searchMenuTagCount
                    , classes = "mb-4"
                    }
                    model.searchMenuTagCountModel
                )
            , Html.map SearchMenuTagCatMsg
                (Comp.IntField.view
                    { label = texts.searchMenuCatCount
                    , info = texts.searchMenuCatCountInfo
                    , number = model.searchMenuTagCatCount
                    , classes = "mb-4"
                    }
                    model.searchMenuTagCatCountModel
                )
            , Html.map SearchMenuFolderMsg
                (Comp.IntField.view
                    { label = texts.searchMenuFolderCount
                    , info = texts.searchMenuFolderCountInfo
                    , number = model.searchMenuFolderCount
                    , classes = "mb-4"
                    }
                    model.searchMenuFolderCountModel
                )
            ]
      }
    , { name = "item-detail"
      , title = texts.itemDetail
      , titleRight = []
      , info = Nothing
      , body =
            [ div [ class "mb-4" ]
                [ MB.viewItem <|
                    MB.Checkbox
                        { tagger = \_ -> TogglePdfPreview
                        , label = texts.browserNativePdfView
                        , value = model.nativePdfPreview
                        , id = "uisetting-pdfpreview-toggle"
                        }
                ]
            , div [ class "mb-4" ]
                [ MB.viewItem <|
                    MB.Checkbox
                        { tagger = \_ -> ToggleItemDetailShortcuts
                        , label = texts.keyboardShortcutLabel
                        , value = model.itemDetailShortcuts
                        , id = "uisetting-itemdetailshortcuts-toggle"
                        }
                ]
            ]
      }
    , { name = "tag-category-colors"
      , title = texts.tagCategoryColors
      , titleRight = []
      , info = Nothing
      , body =
            [ Html.map TagColorMsg
                (Comp.ColorTagger.view2
                    model.tagColors
                    (tagColorViewOpts2 texts)
                    model.tagColorModel
                )
            ]
      }
    , { name = "fields"
      , title = texts.fields
      , titleRight = []
      , info = Nothing
      , body =
            [ span [ class "opacity-50 text-sm" ]
                [ text texts.fieldsInfo
                ]
            , Html.map FieldListMsg
                (Comp.FieldListSelect.view2
                    { classes = "px-2"
                    , fieldLabel = texts.fieldLabel
                    }
                    model.formFields
                )
            ]
      }
    ]
