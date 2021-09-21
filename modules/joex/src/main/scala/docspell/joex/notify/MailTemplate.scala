/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.notify

import yamusca.implicits._

object MailTemplate {

  val text = mustache"""
Hello {{{ username }}},

this is Docspell informing you about your next due items coming up.

{{#itemUri}}
{{#items}}
- {{#overDue}}**(OVERDUE)** {{/overDue}}[{{name}}]({{itemUri}}/{{id}}),
  {{#overDue}}was {{/overDue}}due {{dueIn}} on *{{dueDate}}*; {{#corrOrg}}from {{corrOrg}}{{/corrOrg}}
  received on {{date}} via {{source}}
{{/items}}
{{/itemUri}}
{{^itemUri}}
{{#items}}
- {{#overDue}}**(OVERDUE)** {{/overDue}}*{{name}}*,
  {{#overDue}}was {{/overDue}}due {{dueIn}} on *{{dueDate}}*; {{#corrOrg}}from {{corrOrg}}{{/corrOrg}}
  received on {{date}} via {{source}}
{{/items}}
{{/itemUri}}
{{#more}}
- … more have been left out for brevity
{{/more}}


Sincerely yours,

Docspell
"""

  def render(mc: MailContext): String =
    mc.render(text)
}
