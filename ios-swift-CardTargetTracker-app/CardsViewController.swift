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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let c = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var cfg = UIListContentConfiguration.subtitleCell()
        cfg.text = c.name
        let spent = TransactionManager.shared.spentForCard(c.id, in: PeriodCalculator.window(preset: .thisMonth))
        cfg.secondaryText = "\(Money.toString(cents: spent)) / \(Money.toString(cents: c.targetCents))"
        cell.contentConfiguration = cfg
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        show(CardDetailViewController(card: data[indexPath.row]), sender: self)
    }

    @objc private func addCard() {
        let vc = AddCardViewController()
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    
}

