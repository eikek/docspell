package docspell.joex.notify

import yamusca.implicits._

object MailTemplate {

  val text = mustache"""
## Hello {{{ account.user }}},

this is Docspell informing you about due items coming up.

{{#itemUri}}
{{#items}}
- [{{name}}]({{itemUri}}/{{id}}), due on *{{dueDate}}*
  (received on {{date}} via {{source}})
{{/items}}
{{/itemUri}}
{{^itemUri}}
{{#items}}
- *{{name}}*, due on *{{dueDate}}*
  (received on {{date}} via {{source}})
{{/items}}
{{/itemUri}}
{{#more}}
- (There are more due items, left out for brevity)
{{/more}}


Sincerly,
Docspell
"""

  def render(mc: MailContext): String =
    mc.render(text)
}
