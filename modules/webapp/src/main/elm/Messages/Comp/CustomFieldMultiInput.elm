{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.CustomFieldMultiInput exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Messages.Comp.CustomFieldInput


type alias Texts =
    { customFieldInput : Messages.Comp.CustomFieldInput.Texts
    }


gb : Texts
gb =
    { customFieldInput = Messages.Comp.CustomFieldInput.gb
    }


de : Texts
de =
    { customFieldInput = Messages.Comp.CustomFieldInput.de
    }


fr : Texts
fr =
    { customFieldInput = Messages.Comp.CustomFieldInput.fr
    }
