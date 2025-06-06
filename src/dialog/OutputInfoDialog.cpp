// SPDX-License-Identifier: BSD-3-Clause
// SPDX-FileCopyrightText: The Monero Project

#include "OutputInfoDialog.h"
#include "ui_OutputInfoDialog.h"

#include "utils/Utils.h"

OutputInfoDialog::OutputInfoDialog(const CoinsInfo &cInfo, QWidget *parent)
        : WindowModalDialog(parent)
        , ui(new Ui::OutputInfoDialog)
{
    ui->setupUi(this);

    QFont font = Utils::getMonospaceFont();
    ui->label_pubKey->setFont(font);
    ui->label_keyImage->setFont(font);
    ui->label_txid->setFont(font);
    ui->label_address->setFont(font);

    ui->label_pubKey->setText(cInfo.pubKey);
    ui->label_keyImage->setText(cInfo.keyImage);
    ui->label_txid->setText(cInfo.hash);
    ui->label_address->setText(cInfo.address);

    QString status = cInfo.spent ? "spent" : (cInfo.frozen ? "frozen" : "unspent");
    ui->label_status->setText(status);
    ui->label_amount->setText(QString("%1 XMR").arg(cInfo.displayAmount()));
    ui->label_creationHeight->setText(QString::number(cInfo.blockHeight));
    ui->label_globalIndex->setText(QString::number(cInfo.globalOutputIndex));
    ui->label_internalIndex->setText(QString::number(cInfo.internalOutputIndex));

    QString spentHeight = QVariant(cInfo.spentHeight).toString();
    if (spentHeight == "0") spentHeight = "n/a";
    ui->label_spentHeight->setText(spentHeight);

    this->adjustSize();
}

OutputInfoDialog::~OutputInfoDialog() = default;