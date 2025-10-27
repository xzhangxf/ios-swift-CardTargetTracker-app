//
//  SettingsViewController.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 27/10/25.
//

import UIKit

final class SettingsViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        tableView = UITableView(frame: .zero, style: .insetGrouped)
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 2 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { section == 0 ? 2 : 2 }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Notifications" : "Data"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        if indexPath.section == 0 {
            cell.textLabel?.text = (indexPath.row == 0) ? "Enable Notifications" : "Days Before Cycle Ends"
            if indexPath.row == 0 {
                let s = UISwitch()
                cell.accessoryView = s
            } else {
                cell.detailTextLabel?.text = "3"
                cell.accessoryType = .disclosureIndicator
            }
        } else {
            cell.textLabel?.text = (indexPath.row == 0) ? "Export Data (JSON)" : "Clear All Data"
            cell.textLabel?.textColor = (indexPath.row == 1) ? .systemRed : .label
        }
        return cell
    }
}
