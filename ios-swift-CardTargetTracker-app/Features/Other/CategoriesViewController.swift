//
//  CategoriesViewController.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 24/10/25.
//

import UIKit

final class CategoriesViewController: UITableViewController {
    private var rows: [(category: Category, cents: Int)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Category"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        rows = TransactionManager.shared.totalsByCategory(in: PeriodCalculator.window(preset: .thisMonth))
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let r = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var cfg = UIListContentConfiguration.valueCell()
        cfg.text = r.category.rawValue.capitalized
        cfg.secondaryText = Money.toString(cents: r.cents)
        cell.contentConfiguration = cfg
        return cell
    }
}
