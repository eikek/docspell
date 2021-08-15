{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Util.Item exposing
    ( concTemplate
    , corrTemplate
    )

import Api.Model.ItemLight exposing (ItemLight)
import Data.Fields
import Data.ItemTemplate as IT exposing (ItemTemplate)
import Data.UiSettings exposing (UiSettings)


corrTemplate : UiSettings -> ItemTemplate
corrTemplate settings =
    let
        fieldHidden f =
            Data.UiSettings.fieldHidden settings f

        hiddenTuple =
            ( fieldHidden Data.Fields.CorrOrg, fieldHidden Data.Fields.CorrPerson )
    in
    case hiddenTuple of
        ( True, True ) ->
            IT.empty

        ( True, False ) ->
            IT.corrPerson

        ( False, True ) ->
            IT.corrOrg

        ( False, False ) ->
            IT.correspondent


concTemplate : UiSettings -> ItemTemplate
concTemplate settings =
    let
        fieldHidden f =
            Data.UiSettings.fieldHidden settings f

        hiddenTuple =
            ( fieldHidden Data.Fields.ConcPerson, fieldHidden Data.Fields.ConcEquip )
    in
    case hiddenTuple of
        ( True, True ) ->
            IT.empty

        ( True, False ) ->
            IT.concEquip

        ( False, True ) ->
            IT.concPerson

        ( False, False ) ->
            IT.concerning
