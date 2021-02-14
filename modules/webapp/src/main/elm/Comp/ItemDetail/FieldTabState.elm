module Comp.ItemDetail.FieldTabState exposing (tabState)

import Comp.CustomFieldMultiInput
import Comp.Tabs as TB
import Data.Fields
import Data.UiSettings exposing (UiSettings)
import Set exposing (Set)


tabState :
    UiSettings
    -> Set String
    -> Maybe Comp.CustomFieldMultiInput.Model
    -> (TB.Tab msg -> msg)
    -> TB.Tab msg
    -> ( TB.State, msg )
tabState settings openTabs cfmodel toggle tab =
    let
        isHidden f =
            Data.UiSettings.fieldHidden settings f

        hidden =
            case tab.title of
                "Tags" ->
                    isHidden Data.Fields.Tag

                "Folder" ->
                    isHidden Data.Fields.Folder

                "Correspondent" ->
                    isHidden Data.Fields.CorrOrg && isHidden Data.Fields.CorrPerson

                "Concerning" ->
                    isHidden Data.Fields.ConcEquip && isHidden Data.Fields.ConcPerson

                "Custom Fields" ->
                    isHidden Data.Fields.CustomFields
                        || (Maybe.map Comp.CustomFieldMultiInput.isEmpty cfmodel
                                |> Maybe.withDefault False
                           )

                "Date" ->
                    isHidden Data.Fields.Date

                "Due Date" ->
                    isHidden Data.Fields.DueDate

                "Direction" ->
                    isHidden Data.Fields.Direction

                _ ->
                    False

        state =
            if hidden then
                TB.Hidden

            else if Set.member tab.title openTabs then
                TB.Open

            else
                TB.Closed
    in
    ( state, toggle tab )
