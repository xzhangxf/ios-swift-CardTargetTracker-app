//
//  DailyViewController.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 24/10/25.
//

import UIKit

class DailyViewController: UITableViewController {
    private var sections: [(day: Date, items: [Transaction], totalCents: Int)] = []

    override func viewDidLoad()
    {
        super.viewDidLoad()
        title = "Date"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        sections = TransactionManager.shared.groupByDay(in: PeriodCalculator.window(preset: .thisMonth))
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        sections.count
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        let df = DateFormatter(); df.dateStyle = .medium; df.timeStyle = .none
        let s = sections[section]
        return "\(df.string(from: s.day)) · \(Money.toString(cents: s.totalCents))"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let t = sections[indexPath.section].items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var cfg = UIListContentConfiguration.valueCell()
        cfg.text = Money.toString(cents: t.amountCents)
        cfg.secondaryText = "\(t.category.rawValue.capitalized)"
        cell.contentConfiguration = cfg
        return cell
    }
}
