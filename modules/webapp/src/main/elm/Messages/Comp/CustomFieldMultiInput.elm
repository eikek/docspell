module Messages.Comp.CustomFieldMultiInput exposing (Texts, gb)

import Messages.Comp.CustomFieldInput


type alias Texts =
    { customFieldInput : Messages.Comp.CustomFieldInput.Texts
    }


gb : Texts
gb =
    { customFieldInput = Messages.Comp.CustomFieldInput.gb
    }
