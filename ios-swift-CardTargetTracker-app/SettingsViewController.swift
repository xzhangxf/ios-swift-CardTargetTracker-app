//
//  SettingsViewController.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 27/10/25.
//

import UIKit
import UniformTypeIdentifiers //needed for UTType.json

final class SettingsViewController: UITableViewController, UIDocumentPickerDelegate {

    private enum Section: Int, CaseIterable {
        case appearance
        case data
        case danger
    }

    private let themeItems = AppTheme.allCases

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    override func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .appearance: return 1
        case .data:       return 2
        case .danger:     return 1
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .appearance: return "Appearance"
        case .data:       return "Data"
        case .danger:     return "Danger Zone"
        }
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var cfg = UIListContentConfiguration.valueCell()

        switch Section(rawValue: indexPath.section)! {
        case .appearance:
            cfg.text = "Theme"
            cell.contentConfiguration = cfg
            cell.selectionStyle = .none

            // segmented control
            let seg = UISegmentedControl(items: themeItems.map { $0.title })
            seg.selectedSegmentIndex = ThemeManager.shared.current.rawValue
            seg.addTarget(self, action: #selector(onThemeChanged(_:)), for: .valueChanged)
            seg.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(seg)
            NSLayoutConstraint.activate([
                seg.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                seg.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor)
            ])

        case .data:
            if indexPath.row == 0 {
                cfg.text = "Export JSON"
                cfg.secondaryText = "Share all cards & transactions"
                cell.accessoryType = .disclosureIndicator
            } else {
                cfg.text = "Import JSON"
                cfg.secondaryText = "Merge into existing data"
                cell.accessoryType = .disclosureIndicator
            }
            cell.contentConfiguration = cfg

        case .danger:
            cfg.text = "Clear All Data"
            cfg.secondaryText = "Delete all cards & transactions"
            cfg.textProperties.color = .systemRed
            cell.contentConfiguration = cfg
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Section(rawValue: indexPath.section)! {
        case .appearance:
            break
        case .data:
            if indexPath.row == 0 { exportJSON() }
            else { importJSON() }
        case .danger:
            confirmClearAll()
        }
    }

    @objc private func onThemeChanged(_ seg: UISegmentedControl) {
        guard let sel = AppTheme(rawValue: seg.selectedSegmentIndex) else { return }
        ThemeManager.shared.current = sel

        if let window = view.window ?? UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first {
            ThemeManager.shared.apply(to: window)
        }
    }

    private func exportJSON() {
        let backup = Backup.makeFromCurrentStore()
        guard let data = try? JSONEncoder.exportEncoder.encode(backup) else {
            toast("Failed to export.")
            return
        }
        let fmt = DateFormatter(); fmt.dateFormat = "yyyyMMdd_HHmmss"
        let name = "CardTargetBackup_\(fmt.string(from: Date())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            present(vc, animated: true)
        } catch {
            print("Write file failed.\(error)")
        }
    }

//    private func importJSON() {
//        let a = UIAlertController(title: "Import JSON?",
//                                  message: "This will REPLACE all current cards and transactions.",
//                                  preferredStyle: .alert)
//        a.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//        a.addAction(UIAlertAction(title: "Import", style: .destructive, handler: { _ in
//            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json], asCopy: true)
//            picker.delegate = self
//            picker.allowsMultipleSelection = false
//            self.present(picker, animated: true)
//        }))
//        present(a, animated: true)
//    }
    
    private func importJSON() {
        let a = UIAlertController(title: "Import JSON?",
                                  message: "This will MERGE with existing cards and transactions.",
                                  preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        a.addAction(UIAlertAction(title: "Import", style: .default, handler: { _ in
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json], asCopy: true)
            picker.delegate = self
            picker.allowsMultipleSelection = false
            self.present(picker, animated: true)
        }))
        present(a, animated: true)
    }

    

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        do {
            let data = try Data(contentsOf: url)
            let backup = try JSONDecoder.importDecoder.decode(Backup.self, from: data)
            let result = TransactionManager.shared.mergeImport(
                cards: backup.cards,
                transactions: backup.transactions,
                normalizeDateToDayStart: true
            )
            // Notify other screens to refresh
            NotificationCenter.default.post(name: .dataStoreDidChange, object: nil)
            let msg = """
            Cards: +\(result.addedCards), updated \(result.updatedCards)
            Transactions: +\(result.addedTx), updated \(result.updatedTx)
            Orphan skipped: \(result.orphanTx)
            """
            toast(msg)
        } catch {
            toast("Import failed. Invalid file?")
        }
    }


    private func confirmClearAll() {
        let a = UIAlertController(title: "Delete All Data?",
                                  message: "This will permanently remove all cards and transactions.",
                                  preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        a.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            let result = TransactionManager.shared.deleteAllData()
            NotificationCenter.default.post(name: .dataStoreDidChange, object: nil)
            self.toast("Deleted \(result.cards) cards and \(result.transactions) transactions.")
        }))
        present(a, animated: true)
    }

    private func toast(_ msg: String) {
        let a = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        present(a, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak a] in a?.dismiss(animated: true) }
    }
}

private struct Backup: Codable {
    var version: Int
    var exportedAt: Date
    var cards: [Card]
    var transactions: [Transaction]

    static func makeFromCurrentStore() -> Backup {
        return Backup(version: 1,
                      exportedAt: Date(),
                      cards: TransactionManager.shared.allCards(),
                      transactions: TransactionManager.shared.allTransactions())
    }
}

private extension JSONEncoder {
    static var exportEncoder: JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        e.dateEncodingStrategy = .iso8601
        return e
    }
}

private extension JSONDecoder {
    static var importDecoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}

extension Notification.Name {
    static let dataStoreDidChange = Notification.Name("dataStoreDidChange")
}

