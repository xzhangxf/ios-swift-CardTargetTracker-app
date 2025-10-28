//
//  AddCardViewController.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 24/10/25.
//

import UIKit

final class AddCardViewController: UITableViewController {

    private let nameField = UITextField()
    private let targetField = UITextField()
    
    private let startDayStepper = UIStepper()
    private let startDayValueLabel = UILabel()
    private let notifSwitch = UISwitch()
    private let startDayLabel = UILabel()
    
    private var editingCard: Card?
    
    private let cycleSegment = UISegmentedControl(items: ["Calendar (1st)", "Statement/Billing"])
    private let reminderSwitch = UISwitch()
    private let reminderTimePicker: UIDatePicker = {
        let p = UIDatePicker()
        if #available(iOS 13.4, *) { p.preferredDatePickerStyle = .inline }
        p.datePickerMode = .time
        return p
    }()
    
    private var showReminderTimeRow = false

    init(cardToEdit: Card? = nil) {
        self.editingCard = cardToEdit
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = editingCard == nil ? "Add Card" : "Edit Card"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        
        tableView.keyboardDismissMode = .onDrag

        nameField.placeholder = "Card Name"
        nameField.autocapitalizationType = .words
        nameField.clearButtonMode = .whileEditing
        nameField.returnKeyType = .next
        
        targetField.placeholder = "Target Amount"
        targetField.keyboardType = .decimalPad
        targetField.clearButtonMode = .whileEditing
        addDoneToolbar(to: targetField)
        
        
        cycleSegment.selectedSegmentIndex = 0
        cycleSegment.addTarget(self, action: #selector(onCycleChanged), for: .valueChanged)
        
        startDayStepper.maximumValue = 31
        startDayStepper.minimumValue = 1
        startDayStepper.addTarget(self, action: #selector(onStepper), for: .valueChanged)
        startDayLabel.textColor = .secondaryLabel
        startDayLabel.font = .systemFont(ofSize: 15)
        
        reminderSwitch.addTarget(self, action: #selector(onReminderToggle), for: .valueChanged)
        reminderTimePicker.addTarget(self, action: #selector(onTimeChanged), for: .valueChanged)

        if let c = editingCard {
            nameField.text = c.name
            targetField.text = String(format: "%.2f", Double(c.targetCents) / 100.0)
            
            switch c.cycle {
            case .monthly(let startDay):
                if startDay == 1 {
                    cycleSegment.selectedSegmentIndex = 0
                } else {
                    cycleSegment.selectedSegmentIndex = 1
                    startDayStepper.value = Double(startDay)
                }
            case .custom:
                // If you ever use .custom in the UI later, map it here.
                cycleSegment.selectedSegmentIndex = 0
            }

            let notify = c.notifyDaysBefore > 0
            reminderSwitch.isOn = notify
            showReminderTimeRow = notify

            if let dc = c.dailyReminderTime,
               let date = Calendar.current.date(from: dc) {
                reminderTimePicker.date = date
            }
        } else {
            // sensible defaults
            cycleSegment.selectedSegmentIndex = 0 // calendar month
            startDayStepper.value = 2             // default if user chooses statement later
            reminderSwitch.isOn = false
            showReminderTimeRow = false
            // default reminder time 9:00
            var comps = DateComponents()
            comps.hour = 9; comps.minute = 0
            reminderTimePicker.date = Calendar.current.date(from: comps) ?? Date()
        }

        updateStartDayLabel()
    }
    
    private enum Section: Int, CaseIterable {
        case basics, cycle, reminder
    }

    override func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .basics: return 2                      // name, target
        case .cycle:  return cycleSegment.selectedSegmentIndex == 0 ? 1 : 2
            // row0: segmented control, row1: start day (only for statement mode)
        case .reminder: return showReminderTimeRow ? 2 : 1 // toggle, (optional) time
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .basics: return "Basics"
        case .cycle: return "Spending Cycle"
        case .reminder: return "Reminders"
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .cycle:
            return """
            • Calendar Month: counts 1st → last day of the month.\n\
            • Statement/Billing: counts from your chosen day each month. Example: 20th → next 19th.
            """
        case .reminder:
            return "“Remind 3 days before” uses your selected time. You can change this per card later."
        default:
            return nil
        }
    }
    
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.selectionStyle = .none

        switch Section(rawValue: indexPath.section)! {

        case .basics:
            if indexPath.row == 0 {
                cell.textLabel?.text = "Name"
                addField(nameField, into: cell)
            } else {
                cell.textLabel?.text = "Target"
                addField(targetField, into: cell)
                cell.detailTextLabel?.text = "SGD"
                cell.detailTextLabel?.textColor = .tertiaryLabel
            }

        case .cycle:
            if indexPath.row == 0 {
                cell.textLabel?.text = "Cycle"
                addAccessory(cycleSegment, into: cell)
            } else {
                cell.textLabel?.text = "Start day"
                let stack = UIStackView(arrangedSubviews: [startDayLabel, startDayStepper])
                stack.axis = .horizontal
                stack.alignment = .center
                stack.spacing = 12
                addAccessory(stack, into: cell)
            }

        case .reminder:
            if indexPath.row == 0 {
                cell.textLabel?.text = "Remind 3 days before"
                addAccessory(reminderSwitch, into: cell)
            } else {
                // time row
                cell.contentView.addSubview(reminderTimePicker)
                reminderTimePicker.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    reminderTimePicker.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                    reminderTimePicker.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                    reminderTimePicker.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 4),
                    reminderTimePicker.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -4)
                ])
            }
        }

        return cell
    }
    
    private func addField(_ field: UITextField, into cell: UITableViewCell) {
        field.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(field)
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor, constant: 100),
            field.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
            field.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 6),
            field.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -6),
            field.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    private func addAccessory(_ view: UIView, into cell: UITableViewCell) {
        view.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(view)
        NSLayoutConstraint.activate([
            view.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
            view.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
        ])
    }

    private func addDoneToolbar(to field: UITextField) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(endEditingNow))
        toolbar.items = [flex, done]
        field.inputAccessoryView = toolbar
    }

    @objc private func endEditingNow() { view.endEditing(true) }

    // MARK: - Actions
    @objc private func onCycleChanged() {
//        tableView.performBatchUpdates {
//            // show/hide start-day row
//        }
//        let s = Section.cycle.rawValue
//        let currentlyShownRows = tableView.numberOfRows(inSection: s)
//        let shouldShowRows = (sender.selectedSegmentIndex == 0) ? 1 : 2
//
//          tableView.beginUpdates()
//          if shouldShowRows > currentlyShownRows {
//              // Insert the "Start day" row at row 1
//              tableView.insertRows(at: [IndexPath(row: 1, section: s)], with: .fade)
//          } else if shouldShowRows < currentlyShownRows {
//              // Remove the "Start day" row at row 1
//              tableView.deleteRows(at: [IndexPath(row: 1, section: s)], with: .fade)
//          }
//        tableView.endUpdates()
        updateStartDayLabel()
    }

    @objc private func onStepper() { updateStartDayLabel() }

    private func updateStartDayLabel() {
        let v = Int(startDayStepper.value)
        if cycleSegment.selectedSegmentIndex == 0 {
            // Calendar month fixed at 1st
            startDayLabel.text = "1 (Calendar month)"
        } else {
            startDayLabel.text = "\(v)"
        }
    }

    @objc private func onReminderToggle() {
        showReminderTimeRow = reminderSwitch.isOn
        tableView.performBatchUpdates {
            if showReminderTimeRow {
                tableView.insertRows(at: [IndexPath(row: 1, section: Section.reminder.rawValue)], with: .fade)
            } else {
                tableView.deleteRows(at: [IndexPath(row: 1, section: Section.reminder.rawValue)], with: .fade)
            }
        }
    }

    @objc private func onTimeChanged() {
        // nothing special; picked value is read on save
    }

    // MARK: - Save / Close
    @objc private func close() { dismiss(animated: true) }

    @objc private func save() {
        // Validate inputs
        guard let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            showAlert("Please enter a card name."); return
        }
        guard
            let raw = targetField.text?.replacingOccurrences(of: ",", with: ""),
            let amount = Double(raw), amount > 0
        else {
            showAlert("Please enter a valid target amount (e.g. 1000.00)."); return
        }

        // Build model
        let cents = Int((amount * 100.0).rounded())

        let cycle: CycleType = {
            if cycleSegment.selectedSegmentIndex == 0 { // Calendar month
                return .monthly(startDay: 1)
            } else {
                let day = max(1, min(31, Int(startDayStepper.value)))
                return .monthly(startDay: day)
            }
        }()

        let notifyDays = reminderSwitch.isOn ? 3 : 0

        let dailyTime: DateComponents? = {
            guard reminderSwitch.isOn else { return nil }
            let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTimePicker.date)
            return comps
        }()

        if var c = editingCard {
            c.name = name
            c.targetCents = cents
            c.cycle = cycle
            c.notifyDaysBefore = notifyDays
            c.dailyReminderTime = dailyTime
            TransactionManager.shared.updateCard(c)
        } else {
            let newCard = Card(
                id: UUID(),
                name: name,
                targetCents: cents,
                cycle: cycle,
                notifyDaysBefore: notifyDays,
                dailyReminderTime: dailyTime,
                isActive: true
            )
            TransactionManager.shared.addCard(newCard)
        }

        dismiss(animated: true)
    }

    private func showAlert(_ msg: String) {
        let a = UIAlertController(title: "Invalid Input", message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}
    

//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = UITableViewCell()
//        switch indexPath.row {
//        case 0:
//            cell.contentView.addSubview(nameField)
//            nameField.translatesAutoresizingMaskIntoConstraints = false
//            NSLayoutConstraint.activate([
//                nameField.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
//                nameField.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
//                nameField.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
//                nameField.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
//                nameField.heightAnchor.constraint(equalToConstant: 44)
//            ])
//        default:
//            cell.contentView.addSubview(targetField)
//            targetField.translatesAutoresizingMaskIntoConstraints = false
//            NSLayoutConstraint.activate([
//                targetField.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
//                targetField.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
//                targetField.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
//                targetField.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
//                targetField.heightAnchor.constraint(equalToConstant: 44)
//            ])
//        }
//        return cell
//    }
//
//    @objc private func close() { dismiss(animated: true) }
//
//    @objc private func save() {
//        guard let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty,
//              let text = targetField.text?.replacingOccurrences(of: ",", with: ""),
//              let amount = Double(text), amount > 0 else {
//            let alert = UIAlertController(title: "Invalid Input", message: "Please enter name and target.", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "OK", style: .default))
//            present(alert, animated: true)
//            return
//        }
//        let cents = Int((amount * 100.0).rounded())
//        let startDay = Int(startDayStepper.value)
//
//
//        
//        if var editingCard = editingCard {
//            editingCard.name = name
//            editingCard.targetCents = cents
//            TransactionManager.shared.updateCard(editingCard)
//        } else {
//            let newCard = Card(
//                name: name,
//                targetCents: cents,
//                cycle: .monthly(startDay: startDay),
//                notifyDaysBefore: notifSwitch.isOn ? 3 : 0,
//                dailyReminderTime: nil
//            )
//        }
//        dismiss(animated: true)
//    }
//}
