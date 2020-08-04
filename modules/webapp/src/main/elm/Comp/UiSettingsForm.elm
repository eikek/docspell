module Comp.UiSettingsForm exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Api
import Api.Model.TagList exposing (TagList)
import Comp.ColorTagger
import Comp.IntField
import Data.Color exposing (Color)
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck)
import Http
import Util.List


type alias Model =
    { itemSearchPageSize : Maybe Int
    , searchPageSizeModel : Comp.IntField.Model
    , tagColors : Dict String Color
    , tagColorModel : Comp.ColorTagger.Model
    , nativePdfPreview : Bool
    , itemSearchNoteLength : Maybe Int
    , searchNoteLengthModel : Comp.IntField.Model
    }


init : Flags -> UiSettings -> ( Model, Cmd Msg )
init flags settings =
    ( { itemSearchPageSize = Just settings.itemSearchPageSize
      , searchPageSizeModel =
            Comp.IntField.init
                (Just 10)
                (Just flags.config.maxPageSize)
                False
                "Page size"
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
                "Max. Note Length"
      }
    , Api.getTags flags "" GetTagsResp
    )


type Msg
    = SearchPageSizeMsg Comp.IntField.Msg
    | TagColorMsg Comp.ColorTagger.Msg
    | GetTagsResp (Result Http.Error TagList)
    | TogglePdfPreview
    | NoteLengthMsg Comp.IntField.Msg



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
                    List.filterMap .category tl.items
                        |> Util.List.distinct
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



--- View


tagColorViewOpts : Comp.ColorTagger.ViewOpts
tagColorViewOpts =
    { renderItem =
        \( k, v ) ->
            span [ class ("ui label " ++ Data.Color.toString v) ]
                [ text k ]
    , label = "Choose color for tag categories"
    , description = Just "Tags can be represented differently based on their category."
    }


view : Flags -> UiSettings -> Model -> Html Msg
view flags _ model =
    div [ class "ui form" ]
        [ div [ class "ui dividing header" ]
            [ text "Item Search"
            ]
        , Html.map SearchPageSizeMsg
            (Comp.IntField.viewWithInfo
                ("Maximum results in one page when searching items. At most "
                    ++ String.fromInt flags.config.maxPageSize
                    ++ "."
                )
                model.itemSearchPageSize
                "field"
                model.searchPageSizeModel
            )
        , Html.map NoteLengthMsg
            (Comp.IntField.viewWithInfo
                ("Maximum size of the item notes to display in card view. Between 0 - "
                    ++ String.fromInt flags.config.maxNoteLength
                    ++ "."
                )
                model.itemSearchNoteLength
                "field"
                model.searchNoteLengthModel
            )
        , div [ class "ui dividing header" ]
            [ text "Item Detail"
            ]
        , div [ class "field" ]
            [ div [ class "ui checkbox" ]
                [ input
                    [ type_ "checkbox"
                    , onCheck (\_ -> TogglePdfPreview)
                    , checked model.nativePdfPreview
                    ]
                    []
                , label []
                    [ text "Browser-native PDF preview"
                    ]
                ]
            ]
        , div [ class "ui dividing header" ]
            [ text "Tag Category Colors"
            ]
        , Html.map TagColorMsg
            (Comp.ColorTagger.view
                model.tagColors
                tagColorViewOpts
                model.tagColorModel
            )
        ]
