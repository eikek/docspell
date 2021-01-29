module Comp.TagForm exposing
    ( Model
    , Msg(..)
    , emptyModel
    , getTag
    , isValid
    , update
    , view
    , view2
    )

import Api.Model.Tag exposing (Tag)
import Comp.Basic as B
import Comp.Dropdown
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Styles as S
import Util.Maybe


type alias Model =
    { tag : Tag
    , name : String
    , allCategories : List String
    , catDropdown : Comp.Dropdown.Model String
    }


emptyModel : List String -> Model
emptyModel categories =
    { tag = Api.Model.Tag.empty
    , name = ""
    , allCategories = categories
    , catDropdown =
        let
            cm =
                Comp.Dropdown.makeSingleList
                    { makeOption = \s -> Comp.Dropdown.mkOption s s
                    , placeholder = "Select or define category..."
                    , options = categories
                    , selected = Nothing
                    }
        in
        { cm | searchable = \_ -> True }
    }


isValid : Model -> Bool
isValid model =
    model.name /= ""


getTag : Model -> Tag
getTag model =
    let
        cat =
            Comp.Dropdown.getSelected model.catDropdown
                |> List.head
                |> Maybe.withDefault model.catDropdown.filterString
    in
    Tag model.tag.id model.name (Util.Maybe.fromString cat) 0


type Msg
    = SetName String
    | SetCategory String
    | SetCategoryOptions (List String)
    | SetTag Tag
    | CatMsg (Comp.Dropdown.Msg String)


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        SetTag t ->
            let
                ( dm_, cmd_ ) =
                    Comp.Dropdown.update
                        (Comp.Dropdown.SetSelection
                            (List.filterMap identity [ t.category ])
                        )
                        model.catDropdown
            in
            ( { model | tag = t, name = t.name, catDropdown = dm_ }
            , Cmd.map CatMsg cmd_
            )

        SetName n ->
            ( { model | name = n }, Cmd.none )

        SetCategory n ->
            let
                ( dm_, cmd_ ) =
                    Comp.Dropdown.update (Comp.Dropdown.SetSelection [ n ]) model.catDropdown
            in
            ( { model | catDropdown = dm_ }, Cmd.map CatMsg cmd_ )

        SetCategoryOptions list ->
            let
                ( dm_, cmd_ ) =
                    Comp.Dropdown.update
                        (Comp.Dropdown.SetOptions list)
                        model.catDropdown
            in
            ( { model | catDropdown = dm_ }
            , Cmd.map CatMsg cmd_
            )

        CatMsg lm ->
            let
                ( dm_, cmd_ ) =
                    Comp.Dropdown.update lm model.catDropdown
            in
            ( { model | catDropdown = dm_ }, Cmd.map CatMsg cmd_ )


view : Model -> Html Msg
view model =
    div [ class "ui form" ]
        [ div
            [ classList
                [ ( "field", True )
                , ( "error", not (isValid model) )
                ]
            ]
            [ label [] [ text "Name*" ]
            , input
                [ type_ "text"
                , onInput SetName
                , placeholder "Name"
                , value model.name
                ]
                []
            ]
        , div [ class "field" ]
            [ label []
                [ text "Category" ]
            , Html.map CatMsg (Comp.Dropdown.viewSingle model.catDropdown)
            ]
        ]


view2 : Model -> Html Msg
view2 model =
    div
        [ class "flex flex-col" ]
        [ div [ class "mb-4" ]
            [ label
                [ for "tagname"
                , class S.inputLabel
                ]
                [ text "Name"
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , onInput SetName
                , placeholder "Name"
                , value model.name
                , id "tagname"
                , class S.textInput
                , classList
                    [ ( S.inputErrorBorder
                      , not (isValid model)
                      )
                    ]
                ]
                []
            ]
        , div [ class "mb-4" ]
            [ label
                [ class S.inputLabel
                ]
                [ text "Category"
                ]
            , Html.map CatMsg
                (Comp.Dropdown.viewSingle2
                    DS.mainStyle
                    model.catDropdown
                )
            ]
        ]
