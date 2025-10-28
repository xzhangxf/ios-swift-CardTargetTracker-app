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
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addCard))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        data = TransactionManager.shared.allCards()
        tableView.reloadData()
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }
    
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let c = data[indexPath.row]
//        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
//        var cfg = UIListContentConfiguration.subtitleCell()
//        cfg.text = c.name
//        let spent = TransactionManager.shared.spentForCard(c.id, in: PeriodCalculator.window(preset: .thisMonth))
//        cfg.secondaryText = "\(Money.toString(cents: spent)) / \(Money.toString(cents: c.targetCents))"
//        cell.contentConfiguration = cfg
//        cell.accessoryType = .disclosureIndicator
//        return cell
//    }
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "cardCell2"
        let cell = tableView.dequeueReusableCell(withIdentifier: id) ?? UITableViewCell(style: .default, reuseIdentifier: id)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        tableView.backgroundColor = .systemGroupedBackground

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

        // configure values
        let card = data[indexPath.row]
        let window = BillingCycle.window(for: card)  // per-card accurate window
        let spent = TransactionManager.shared.spentForCard(card.id, in: window)
        let daysLeft = BillingCycle.daysLeft(for: card)
//        let spent = TransactionManager.shared.spentForCard(card.id, in: PeriodCalculator.window(preset: .thisMonth))
//        let daysLeft = Self.daysLeftInMonth()
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
        show(CardDetailViewController(card: data[indexPath.row]), sender: self)
    }
    
    
    private func reloadData() {
        data = StorageManager.shared.loadCards() ?? []
        tableView.reloadData()
    }
    
    @objc private func addCard() {
        let vc = AddCardViewController()
        
        vc.onCardSaved = { [weak self] in
            self?.reloadData()
        }
        
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        let nav = UINavigationController(rootViewController: vc)
//        present(nav, animated: true)
        present(nav, animated: true)
    }
    
    private static func daysLeftInMonth(calendar: Calendar = .current) -> Int {
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let startNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        let endThisMonth = calendar.date(byAdding: .day, value: -1, to: startNextMonth)!
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now),
                                           to: calendar.startOfDay(for: endThisMonth)).day ?? 0
        return max(0, days + 1)
    }
    
}


//TODO: add the edit button in the navagion bar to sawp left to delet and to tap on top to edit the card same foe the transacation

//TODO: change the add card to the strart day and enter the cycle by hand by defalu is 30 days

