module Comp.ContactField exposing
    ( Model
    , Msg(..)
    , emptyModel
    , getContacts
    , update
    , view
    , view1
    , view2
    )

import Api.Model.Contact exposing (Contact)
import Comp.Basic as B
import Comp.FixedDropdown
import Data.ContactType exposing (ContactType)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Styles as S


type alias Model =
    { items : List Contact
    , kind : Comp.FixedDropdown.Model ContactType
    , selectedKind : Maybe ContactType
    , value : String
    }


emptyModel : Model
emptyModel =
    { items = []
    , kind =
        Comp.FixedDropdown.initMap Data.ContactType.toString Data.ContactType.all
    , selectedKind = List.head Data.ContactType.all
    , value = ""
    }


getContacts : Model -> List Contact
getContacts model =
    List.filter (\c -> c.value /= "") model.items


makeDropdownItem : ContactType -> Comp.FixedDropdown.Item ContactType
makeDropdownItem ct =
    { id = ct
    , display = Data.ContactType.toString ct
    }


type Msg
    = SetValue String
    | TypeMsg (Comp.FixedDropdown.Msg ContactType)
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
                ( m1, sel ) =
                    Comp.FixedDropdown.update m model.kind

                newSel =
                    case sel of
                        Just _ ->
                            sel

                        Nothing ->
                            model.selectedKind
            in
            ( { model | kind = m1, selectedKind = newSel }
            , Cmd.none
            )

        AddContact ->
            if model.value == "" then
                ( model, Cmd.none )

            else
                case model.selectedKind of
                    Just k ->
                        let
                            contact =
                                { id = ""
                                , value = model.value
                                , kind = Data.ContactType.toString k
                                }
                        in
                        ( { model | items = contact :: model.items, value = "" }
                        , Cmd.none
                        )

                    Nothing ->
                        ( model, Cmd.none )

        Select contact ->
            let
                newItems =
                    List.filter (\c -> c /= contact) model.items
            in
            ( { model
                | value = contact.value
                , selectedKind = Data.ContactType.fromString contact.kind
                , items = newItems
              }
            , Cmd.none
            )


view : UiSettings -> Model -> Html Msg
view settings model =
    view1 settings False model


view1 : UiSettings -> Bool -> Model -> Html Msg
view1 _ compact model =
    div []
        [ div [ classList [ ( "fields", not compact ) ] ]
            [ div
                [ classList
                    [ ( "field", True )
                    , ( "four wide", not compact )
                    ]
                ]
                [ Html.map TypeMsg
                    (Comp.FixedDropdown.view
                        (Maybe.map makeDropdownItem model.selectedKind)
                        model.kind
                    )
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
                    , a [ class "ui button", onClick AddContact, href "#" ]
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



--- View2


view2 : Bool -> UiSettings -> Model -> Html Msg
view2 mobile _ model =
    div [ class "flex flex-col" ]
        [ div
            [ class "flex flex-col space-y-2"
            , classList [ ( " md:flex-row md:space-y-0 md:space-x-2", not mobile ) ]
            ]
            [ div
                [ classList [ ( "flex-none md:w-1/6", not mobile ) ]
                ]
                [ Html.map TypeMsg
                    (Comp.FixedDropdown.view2
                        (Maybe.map makeDropdownItem model.selectedKind)
                        model.kind
                    )
                ]
            , input
                [ type_ "text"
                , onInput SetValue
                , value model.value
                , class S.textInput
                , class "flex-grow"
                ]
                []
            , a
                [ class S.secondaryButton
                , class "shadow-none"
                , onClick AddContact
                , href "#"
                ]
                [ i [ class "fa fa-plus" ] []
                ]
            ]
        , div
            [ classList
                [ ( "hidden", List.isEmpty model.items )
                ]
            , class "flex flex-col space-y-2 mt-2 px-2 border-0 border-l dark:border-bluegray-600 "
            ]
            (List.map (renderItem2 mobile) model.items)
        ]


renderItem2 : Bool -> Contact -> Html Msg
renderItem2 mobile contact =
    div
        [ class "flex flex-row space-x-2 items-center"
        ]
        [ div [ class "mr-2 flex-nowrap" ]
            [ B.editLinkLabel (Select contact)
            ]
        , div
            [ class "inline-flex items-center" ]
            [ div
                [ class "label inline-block mr-2 hidden text-sm "
                , classList [ ( " sm:inline-block", not mobile ) ]
                ]
                [ text contact.kind
                ]
            , div [ class "font-mono my-auto inline-block truncate" ]
                [ text contact.value
                ]
            ]
        ]
