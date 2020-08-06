module Comp.ContactField exposing
    ( Model
    , Msg(..)
    , emptyModel
    , getContacts
    , update
    , view
    , view1
    )

import Api.Model.Contact exposing (Contact)
import Comp.Dropdown
import Data.ContactType exposing (ContactType)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)


type alias Model =
    { items : List Contact
    , kind : Comp.Dropdown.Model ContactType
    , value : String
    }


emptyModel : Model
emptyModel =
    { items = []
    , kind =
        Comp.Dropdown.makeSingleList
            { makeOption =
                \ct ->
                    { value = Data.ContactType.toString ct
                    , text = Data.ContactType.toString ct
                    , additional = ""
                    }
            , placeholder = ""
            , options = Data.ContactType.all
            , selected = List.head Data.ContactType.all
            }
    , value = ""
    }


getContacts : Model -> List Contact
getContacts model =
    List.filter (\c -> c.value /= "") model.items


type Msg
    = SetValue String
    | TypeMsg (Comp.Dropdown.Msg ContactType)
    | AddContact
    | Select Contact
    | SetItems (List Contact)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetItems contacts ->
            ( { model | items = contacts, value = "" }, Cmd.none )

        SetValue v ->
            ( { model | value = v }, Cmd.none )

        TypeMsg m ->
            let
                ( m1, c1 ) =
                    Comp.Dropdown.update m model.kind
            in
            ( { model | kind = m1 }, Cmd.map TypeMsg c1 )

        AddContact ->
            if model.value == "" then
                ( model, Cmd.none )

            else
                let
                    kind =
                        Comp.Dropdown.getSelected model.kind
                            |> List.head
                            |> Maybe.map Data.ContactType.toString
                in
                case kind of
                    Just k ->
                        ( { model | items = Contact "" model.value k :: model.items, value = "" }
                        , Cmd.none
                        )

                    Nothing ->
                        ( model, Cmd.none )

        Select contact ->
            let
                newItems =
                    List.filter (\c -> c /= contact) model.items

                ( m1, c1 ) =
                    Data.ContactType.fromString contact.kind
                        |> Maybe.map (\ct -> update (TypeMsg (Comp.Dropdown.SetSelection [ ct ])) model)
                        |> Maybe.withDefault ( model, Cmd.none )
            in
            ( { m1 | value = contact.value, items = newItems }, c1 )


view : UiSettings -> Model -> Html Msg
view settings model =
    view1 settings False model


view1 : UiSettings -> Bool -> Model -> Html Msg
view1 settings compact model =
    div []
        [ div [ classList [ ( "fields", not compact ) ] ]
            [ div
                [ classList
                    [ ( "field", True )
                    , ( "four wide", not compact )
                    ]
                ]
                [ Html.map TypeMsg (Comp.Dropdown.view settings model.kind)
                ]
            , div
                [ classList
                    [ ( "twelve wide", not compact )
                    , ( "field", True )
                    ]
                ]
                [ div [ class "ui action input" ]
                    [ input
                        [ type_ "text"
                        , onInput SetValue
                        , value model.value
                        ]
                        []
                    , a [ class "ui button", onClick AddContact, href "" ]
                        [ text "Add"
                        ]
                    ]
                ]
            ]
        , div
            [ classList
                [ ( "field", True )
                , ( "invisible", List.isEmpty model.items )
                ]
            ]
            [ div [ class "ui vertical secondary fluid menu" ]
                (List.map renderItem model.items)
            ]
        ]


renderItem : Contact -> Html Msg
renderItem contact =
    div [ class "link item", onClick (Select contact) ]
        [ i [ class "delete icon" ] []
        , div [ class "ui blue label" ]
            [ text contact.kind
            ]
        , text contact.value
        ]
