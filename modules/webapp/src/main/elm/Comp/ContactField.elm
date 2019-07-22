module Comp.ContactField exposing (Model
                                  ,emptyModel
                                  ,getContacts
                                  ,Msg(..)
                                  ,update
                                  ,view
                                  )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Api.Model.Contact exposing (Contact)
import Data.ContactType exposing (ContactType)
import Comp.Dropdown

type alias Model =
    { items: List Contact
    , kind: Comp.Dropdown.Model ContactType
    , value: String
    }

emptyModel: Model
emptyModel =
    { items = []
    , kind = Comp.Dropdown.makeSingleList
             { makeOption = \ct -> { value = Data.ContactType.toString ct, text = Data.ContactType.toString ct }
             , placeholder = ""
             , options = Data.ContactType.all
             , selected = List.head Data.ContactType.all
             }
    , value = ""
    }

makeModel: List Contact -> Model
makeModel contacts =
    let
        em = emptyModel
    in
    { em | items = contacts }

getContacts: Model -> List Contact
getContacts model =
    List.filter (\c -> c.value /= "") model.items

type Msg
    = SetValue String
    | TypeMsg (Comp.Dropdown.Msg ContactType)
    | AddContact
    | Select Contact
    | SetItems (List Contact)

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        SetItems contacts ->
            ({model | items = contacts, value = "" }, Cmd.none)

        SetValue v ->
            ({model | value = v}, Cmd.none)

        TypeMsg m ->
            let
                (m1, c1) = Comp.Dropdown.update m model.kind
            in
                ({model|kind = m1}, Cmd.map TypeMsg c1)

        AddContact ->
            if model.value == "" then (model, Cmd.none)
            else
                let
                    kind = Comp.Dropdown.getSelected model.kind
                         |> List.head
                         |> Maybe.map Data.ContactType.toString
                         |> Maybe.withDefault ""
                in
                    ({model| items = (Contact "" model.value kind) :: model.items, value = ""}, Cmd.none)

        Select contact ->
            let
                newItems = List.filter (\c -> c /= contact) model.items
                (m1, c1) = Data.ContactType.fromString contact.kind
                           |> Maybe.map (\ct -> update (TypeMsg (Comp.Dropdown.SetSelection [ct])) model)
                           |> Maybe.withDefault (model, Cmd.none)
            in
                ({m1 | value = contact.value, items = newItems}, c1)

view: Model -> Html Msg
view model =
    div []
        [div [class "fields"]
             [div [class "four wide field"]
                  [Html.map TypeMsg (Comp.Dropdown.view model.kind)
                  ]
             ,div [class "twelve wide field"]
                  [div [class "ui action input"]
                       [input [type_ "text"
                              ,onInput SetValue
                              ,value model.value
                              ][]
                       ,a [class "ui button", onClick AddContact, href ""]
                           [text "Add"
                           ]
                       ]
                  ]
             ]
        ,div [classList [("field", True)
                        ,("invisible", List.isEmpty model.items)
                        ]
             ]
             [div [class "ui vertical secondary fluid menu"]
                  (List.map (renderItem model) model.items)
             ]
        ]


renderItem: Model -> Contact -> Html Msg
renderItem model contact =
    div [class "link item", onClick (Select contact) ]
        [i [class "delete icon"][]
        ,div [class "ui blue label"]
            [text contact.kind
            ]
        ,text contact.value
        ]
