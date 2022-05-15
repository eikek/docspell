{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.AddonArchiveForm exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , addonUrl : String
    , addonUrlPlaceholder : String
    , installInfoText : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , addonUrl = "Addon URL"
    , addonUrlPlaceholder = "e.g. https://github.com/some-user/project/refs/tags/1.0.zip"
    , installInfoText = "Only urls to remote addon zip files are supported."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , addonUrl = "Addon URL"
    , addonUrlPlaceholder = "z.B. https://github.com/some-user/project/refs/tags/1.0.zip"
    , installInfoText = "Nur URLs to externen zip Dateien werden unterstützt."
    }



-- TODO: translate-fr


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , addonUrl = "Addon URL"
    , addonUrlPlaceholder = "p.e. https://github.com/some-user/project/refs/tags/1.0.zip"
    , installInfoText = "Only urls to remote addon zip files are supported."
    }
