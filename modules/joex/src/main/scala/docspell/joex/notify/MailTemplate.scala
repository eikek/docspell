package docspell.joex.notify

import yamusca.implicits._

object MailTemplate {

  val text = mustache"""
## Hello {{{ username }}},

this is Docspell informing you about your next due items coming up.

{{#itemUri}}
{{#items}}
- {{#overDue}}**(OVERDUE)** {{/overDue}}[{{name}}]({{itemUri}}/{{id}}),
  due {{dueIn}} on *{{dueDate}}*
  (received on {{date}} via {{source}})
{{/items}}
{{/itemUri}}
{{^itemUri}}
{{#items}}
- {{#overDue}}**(OVERDUE)** {{/overDue}}*{{name}}*,
  due {{dueIn}} on *{{dueDate}}*
  (received on {{date}} via {{source}})
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
