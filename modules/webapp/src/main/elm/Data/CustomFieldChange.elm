module Data.CustomFieldChange exposing
    ( CustomFieldChange(..)
    , CustomFieldValueCollect
    , collectValues
    , emptyCollect
    , fromItemValues
    , isValueChange
    , toFieldValues
    )

import Api.Model.CustomField exposing (CustomField)
import Api.Model.CustomFieldValue exposing (CustomFieldValue)
import Dict exposing (Dict)


type CustomFieldChange
    = NoFieldChange
    | FieldValueRemove CustomField
    | FieldValueChange CustomField String
    | FieldCreateNew


type CustomFieldValueCollect
    = CustomFieldValueCollect (Dict String String)


emptyCollect : CustomFieldValueCollect
emptyCollect =
    CustomFieldValueCollect Dict.empty


collectValues :
    CustomFieldChange
    -> CustomFieldValueCollect
    -> CustomFieldValueCollect
collectValues change collector =
    let
        dict =
            case collector of
                CustomFieldValueCollect d ->
                    d
    in
    case change of
        NoFieldChange ->
            collector

        FieldValueRemove f ->
            CustomFieldValueCollect (Dict.remove f.id dict)

        FieldValueChange f v ->
            CustomFieldValueCollect (Dict.insert f.id v dict)

        FieldCreateNew ->
            collector


toFieldValues : CustomFieldValueCollect -> List CustomFieldValue
toFieldValues dict =
    case dict of
        CustomFieldValueCollect d ->
            Dict.toList d
                |> List.map (\( k, v ) -> CustomFieldValue k v)


isValueChange : CustomFieldChange -> Bool
isValueChange change =
    case change of
        NoFieldChange ->
            False

        FieldValueRemove _ ->
            True

        FieldValueChange _ _ ->
            True

        FieldCreateNew ->
            False


fromItemValues : List { v | id : String, value : String } -> CustomFieldValueCollect
fromItemValues values =
    List.map (\e -> ( e.id, e.value )) values
        |> Dict.fromList
        |> CustomFieldValueCollect
