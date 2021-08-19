/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.joex.updatecheck

import docspell.common._

import com.github.eikek.calev.CalEvent
import emil.MailAddress
import yamusca.data.Template

final case class UpdateCheckConfig(
    enabled: Boolean,
    testRun: Boolean,
    schedule: CalEvent,
    senderAccount: AccountId,
    smtpId: Ident,
    recipients: List[MailAddress],
    subject: Template,
    body: Template
)
