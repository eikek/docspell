/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.common

import java.time.LocalDate

case class NerDateLabel(date: LocalDate, label: NerLabel) {}
