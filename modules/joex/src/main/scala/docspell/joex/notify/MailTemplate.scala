package docspell.joex.notify

import yamusca.implicits._

object MailTemplate {

  val text = mustache"""
## Hello {{{ account.user }}},

this is Docspell informing you about due items coming up.

{{#items}}
- *{{name}}*, due on *{{dueDate}}*
  (received on {{date}} via {{source}})
{{/items}}
{{#more}}
- ...
{{/more}}


Sincerly,
Docspell
"""

  def render(mc: MailContext): String =
    mc.render(text)
}
