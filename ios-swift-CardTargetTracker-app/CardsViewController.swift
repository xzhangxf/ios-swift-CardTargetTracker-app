//
//  CardsViewController.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 24/10/25.
//

import UIKit
import Foundation

class CardsViewController: UITableViewController {
    private var data: [Card] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cards"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .systemGroupedBackground

        let addItem = UIBarButtonItem(barButtonSystemItem: .add,
                                      target: self,
                                      action: #selector(addCard))
        addItem.tintColor = .systemBlue
        navigationItem.rightBarButtonItems = [ addItem,editButtonItem]
        tableView.allowsSelectionDuringEditing = true
        NotificationCenter.default.addObserver(forName: .dataStoreDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        data = TransactionManager.shared.allCards()
        tableView.reloadData()
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "cardCell2"
        let cell = tableView.dequeueReusableCell(withIdentifier: id) ?? UITableViewCell(style: .default, reuseIdentifier: id)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear

        // build once
        let containerTag = 9000
        let nameTag = 9001, daysTag = 9002, amountsTag = 9003, pctTag = 9004, progTag = 9005
        let container: UIView
        let nameLabel: UILabel, daysLabel: UILabel, amountsLabel: UILabel, percentLabel: UILabel
        let progress: UIProgressView

        if let c = cell.contentView.viewWithTag(containerTag) {
            container = c
            nameLabel    = container.viewWithTag(nameTag) as! UILabel
            daysLabel    = container.viewWithTag(daysTag) as! UILabel
            amountsLabel = container.viewWithTag(amountsTag) as! UILabel
            percentLabel = container.viewWithTag(pctTag) as! UILabel
            progress     = container.viewWithTag(progTag) as! UIProgressView
        } else {
            container = UIView(); container.tag = containerTag
            container.backgroundColor = .secondarySystemBackground
            container.layer.cornerRadius = 16
            container.layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
            container.layer.shadowOpacity = 1
            container.layer.shadowRadius = 8
            container.layer.shadowOffset = CGSize(width: 0, height: 2)

            nameLabel = UILabel(); nameLabel.tag = nameTag; nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
            daysLabel = UILabel(); daysLabel.tag = daysTag; daysLabel.font = .systemFont(ofSize: 14); daysLabel.textColor = .secondaryLabel; daysLabel.textAlignment = .right
            amountsLabel = UILabel(); amountsLabel.tag = amountsTag; amountsLabel.font = .systemFont(ofSize: 14); amountsLabel.textColor = .secondaryLabel
            percentLabel = UILabel(); percentLabel.tag = pctTag; percentLabel.font = .systemFont(ofSize: 14, weight: .semibold); percentLabel.textAlignment = .right
            progress = UIProgressView(progressViewStyle: .default); progress.tag = progTag; progress.trackTintColor = .systemGray5; progress.layer.cornerRadius = 3; progress.clipsToBounds = true

            cell.contentView.addSubview(container)
            [nameLabel, daysLabel, progress, amountsLabel, percentLabel].forEach { container.addSubview($0) }

            container.translatesAutoresizingMaskIntoConstraints = false
            [nameLabel, daysLabel, progress, amountsLabel, percentLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

            container.directionalLayoutMargins = .init(top: 12, leading: 16, bottom: 12, trailing: 16)
            let g = container.layoutMarginsGuide
            NSLayoutConstraint.activate([
                container.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                container.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
                container.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                container.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),

                nameLabel.topAnchor.constraint(equalTo: g.topAnchor),
                nameLabel.leadingAnchor.constraint(equalTo: g.leadingAnchor),

                daysLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
                daysLabel.trailingAnchor.constraint(equalTo: g.trailingAnchor),
                daysLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: 8),

                progress.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 12),
                progress.leadingAnchor.constraint(equalTo: g.leadingAnchor),
                progress.trailingAnchor.constraint(equalTo: g.trailingAnchor),
                progress.heightAnchor.constraint(equalToConstant: 6),

                amountsLabel.topAnchor.constraint(equalTo: progress.bottomAnchor, constant: 8),
                amountsLabel.leadingAnchor.constraint(equalTo: g.leadingAnchor),
                amountsLabel.bottomAnchor.constraint(equalTo: g.bottomAnchor),

                percentLabel.centerYAnchor.constraint(equalTo: amountsLabel.centerYAnchor),
                percentLabel.trailingAnchor.constraint(equalTo: g.trailingAnchor),
                percentLabel.leadingAnchor.constraint(greaterThanOrEqualTo: amountsLabel.trailingAnchor, constant: 8)
            ])
        }

        let card = data[indexPath.row]
        let window = BillingCycle.window(for: card)
        let spent = TransactionManager.shared.spentForCard(card.id, in: window)
        let daysLeft = BillingCycle.daysLeft(for: card)

        nameLabel.text = card.name
        daysLabel.text = "\(daysLeft) days left"
        amountsLabel.text = "\(Money.toString(cents: spent)) / \(Money.toString(cents: card.targetCents))"
        let pct = card.targetCents > 0 ? min(1.0, Float(spent) / Float(card.targetCents)) : 0
        progress.progress = pct
        percentLabel.text = "\(Int(round(pct*100)))%"
        percentLabel.textColor = pct >= 1 ? .systemGreen : .systemBlue
        progress.progressTintColor = pct >= 1 ? .systemGray2 : .systemGreen

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let card = data[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)

        if isEditing {
            let editVC = AddCardViewController(cardToEdit: card)
            editVC.onCardSaved = { [weak self] in self?.reloadData() }

            if let sheet = editVC.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 24
            }
            present(UINavigationController(rootViewController: editVC), animated: true)
        } else {
            show(CardDetailViewController(card: card), sender: self)
        }
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        guard isEditing else { return nil }
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            self?.deleteCard(at: indexPath)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }

    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteCard(at: indexPath)
        }
    }

    private func reloadData() {
        data = StorageManager.shared.loadCards() ?? []
        tableView.reloadData()
    }

    @objc private func addCard() {
        let vc = AddCardViewController()
        vc.onCardSaved = { [weak self] in self?.reloadData() }

        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }

    private func deleteCard(at indexPath: IndexPath) {
        let removed = data.remove(at: indexPath.row)
        StorageManager.shared.saveCards(data)
        TransactionManager.shared.deleteAllTransactions(forCard: removed.id)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    // MARK: - UI Helpers
    private func makeBluePlusItem() -> UIBarButtonItem {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "plus"), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = .systemBlue
        btn.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        btn.layer.cornerRadius = 16
        btn.addTarget(self, action: #selector(addCard), for: .touchUpInside)
        return UIBarButtonItem(customView: btn)
    }
}

//TODO: change the add card to the strart day and enter the cycle by hand by defalu is 30 days

//TODO: make the tranctaicon tape selelction look nice in the ui
//TODO: Set up the seeting in the have a inport json and export json and have a drak mode and light mode stwich and have a stwich for the notifications for all the notification which is the highter order for all the notifaction

//TODO: add on one or two Singapre cards model?



//TODO: if have time the settings can have a cumtize the backguround of the app and so on so fort or custemer the app teame maybe?
//TODO: The day layout can have a sort by the differ category and the catgory can have a tbale for that

