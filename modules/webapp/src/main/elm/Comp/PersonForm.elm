module Comp.PersonForm exposing
    ( Model
    , Msg(..)
    , emptyModel
    , getPerson
    , isValid
    , update
    , view
    )

import Api.Model.Person exposing (Person)
import Comp.AddressForm
import Comp.ContactField
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onInput)


type alias Model =
    { org : Person
    , name : String
    , addressModel : Comp.AddressForm.Model
    , contactModel : Comp.ContactField.Model
    , notes : Maybe String
    , concerning : Bool
    }


emptyModel : Model
emptyModel =
    { org = Api.Model.Person.empty
    , name = ""
    , addressModel = Comp.AddressForm.emptyModel
    , contactModel = Comp.ContactField.emptyModel
    , notes = Nothing
    , concerning = False
    }


isValid : Model -> Bool
isValid model =
    model.name /= ""


getPerson : Model -> Person
getPerson model =
    let
        o =
            model.org
    in
    { o
        | name = model.name
        , address = Comp.AddressForm.getAddress model.addressModel
        , contacts = Comp.ContactField.getContacts model.contactModel
        , notes = model.notes
        , concerning = model.concerning
    }


type Msg
    = SetName String
    | SetPerson Person
    | AddressMsg Comp.AddressForm.Msg
    | ContactMsg Comp.ContactField.Msg
    | SetNotes String
    | SetConcerning Bool


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        SetPerson t ->
            let
                ( m1, c1 ) =
                    update flags (AddressMsg (Comp.AddressForm.SetAddress t.address)) model

                ( m2, c2 ) =
                    update flags (ContactMsg (Comp.ContactField.SetItems t.contacts)) m1
            in
            ( { m2
                | org = t
                , name = t.name
                , notes = t.notes
                , concerning = t.concerning
              }
            , Cmd.batch [ c1, c2 ]
            )

        AddressMsg am ->
            let
                ( m1, c1 ) =
                    Comp.AddressForm.update am model.addressModel
            in
            ( { model | addressModel = m1 }, Cmd.map AddressMsg c1 )

        ContactMsg m ->
            let
                ( m1, c1 ) =
                    Comp.ContactField.update m model.contactModel
            in
            ( { model | contactModel = m1 }, Cmd.map ContactMsg c1 )

        SetName n ->
            ( { model | name = n }, Cmd.none )

        SetNotes str ->
            ( { model
                | notes =
                    if str == "" then
                        Nothing

                    else
                        Just str
              }
            , Cmd.none
            )

        SetConcerning _ ->
            ( { model | concerning = not model.concerning }, Cmd.none )


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
        , div [ class "inline field" ]
            [ div [ class "ui checkbox" ]
                [ input
                    [ type_ "checkbox"
                    , checked model.concerning
                    , onCheck SetConcerning
                    ]
                    []
                , label [] [ text "Use for concerning person suggestion only" ]
                ]
            ]
        , h3 [ class "ui dividing header" ]
            [ text "Address"
            ]
        , Html.map AddressMsg (Comp.AddressForm.view model.addressModel)
        , h3 [ class "ui dividing header" ]
            [ text "Contacts"
            ]
        , Html.map ContactMsg (Comp.ContactField.view model.contactModel)
        , h3 [ class "ui dividing header" ]
            [ text "Notes"
            ]
        , div [ class "field" ]
            [ textarea
                [ onInput SetNotes
                , Maybe.withDefault "" model.notes |> value
                ]
                []
            ]
        ]
