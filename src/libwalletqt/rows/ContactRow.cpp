// SPDX-License-Identifier: BSD-3-Clause
// SPDX-FileCopyrightText: The Monero Project

#include "ContactRow.h"

qsizetype ContactRow::getRow() const {
    return m_row;
}

const QString& ContactRow::getAddress() const {
    return m_address;
}

const QString& ContactRow::getLabel() const {
    return m_label;
}