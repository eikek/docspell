{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Data.PdfMode exposing
    ( de
    , fr
    , ja
    , gb
    )

import Data.Pdf exposing (PdfMode(..))


gb : PdfMode -> String
gb st =
    case st of
        Detect ->
            "Detect automatically"

        Native ->
            "Use the browser's native PDF view"

        Server ->
            "Use cross-browser fallback"


de : PdfMode -> String
de st =
    case st of
        Detect ->
            "Automatisch ermitteln"

        Native ->
            "Browsernative Darstellung"

        Server ->
            "Browserübergreifende Ersatzdarstellung"


fr : PdfMode -> String
fr st =
    case st of
        Detect ->
            "Détecter automatiquement"

        Native ->
            "Utiliser le support pdf natif du navigateur"

        Server ->
            "Utiliser le mode compatibilité"


ja : PdfMode -> String
ja st =
    case st of
        Detect ->
            "自動検出"

        Native ->
            "ブラウザ標準のPDFビューアを使用"

        Server ->
            "クロスブラウザ用のフォールバックを使用"
