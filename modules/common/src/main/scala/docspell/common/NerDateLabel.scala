/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import java.time.LocalDate

case class NerDateLabel(date: LocalDate, label: NerLabel) {}
