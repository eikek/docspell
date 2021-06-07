module Messages.Comp.CustomFieldMultiInput exposing
    ( Texts
    , de
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
