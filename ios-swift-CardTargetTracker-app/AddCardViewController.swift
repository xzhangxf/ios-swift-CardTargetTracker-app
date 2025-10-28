//
//  AddCardViewController.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 24/10/25.
//

import UIKit

final class AddCardViewController: UITableViewController {

    // MARK: - UI: Basics
    private let nameField = UITextField()
    private let targetField = UITextField()

    // MARK: - UI: Cycle
    private let cycleSegment = UISegmentedControl(items: ["Calendar (1st)", "Statement"])
    private let closingDayStepper = UIStepper()
    private let closingDayLabel = UILabel()

    // MARK: - UI: Reminder
    private let notifyDaysStepper = UIStepper()   // 0..15 (0 = off)
    private let notifyDaysLabel = UILabel()       // "Off" / "3 days before"
    private let reminderTimePicker: UIDatePicker = {
        let p = UIDatePicker()
        if #available(iOS 13.4, *) { p.preferredDatePickerStyle = .inline }
        p.datePickerMode = .time
        return p
    }()

    // MARK: - Preview
    private let previewLabel = UILabel()

    // MARK: - State
    private var editingCard: Card?
    private var showTimeRow = false

    // MARK: - Init
    init(cardToEdit: Card? = nil) {
        self.editingCard = cardToEdit
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = editingCard == nil ? "Add Card" : "Edit Card"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        tableView.keyboardDismissMode = .onDrag

        // Basics
        nameField.placeholder = "Card Name"
        nameField.autocapitalizationType = .words
        nameField.clearButtonMode = .whileEditing
        nameField.returnKeyType = .next

        targetField.placeholder = "Target Amount"
        targetField.keyboardType = .decimalPad
        targetField.clearButtonMode = .whileEditing
        addDoneToolbar(to: targetField)

        // Cycle UI
        cycleSegment.addTarget(self, action: #selector(onCycleChanged(_:)), for: .valueChanged)

        closingDayStepper.minimumValue = 1
        closingDayStepper.maximumValue = 31
        closingDayStepper.addTarget(self, action: #selector(onClosingDayChanged), for: .valueChanged)
        closingDayLabel.textColor = .secondaryLabel
        closingDayLabel.font = .systemFont(ofSize: 15)

        // Reminder UI
        notifyDaysStepper.minimumValue = 0
        notifyDaysStepper.maximumValue = 15
        notifyDaysStepper.addTarget(self, action: #selector(onNotifyDaysChanged), for: .valueChanged)
        notifyDaysLabel.textColor = .secondaryLabel
        notifyDaysLabel.font = .systemFont(ofSize: 15)

        reminderTimePicker.addTarget(self, action: #selector(onTimeChanged), for: .valueChanged)

        // Preview label
        previewLabel.textAlignment = .left
        previewLabel.textColor = .secondaryLabel
        previewLabel.numberOfLines = 0
        previewLabel.font = .systemFont(ofSize: 14)

        // Defaults / Prefill
        if let c = editingCard {
            nameField.text = c.name
            targetField.text = String(format: "%.2f", Double(c.targetCents) / 100.0)
            switch c.cycle {
            case .monthly(let startDay):
                if startDay == 1 {
                    cycleSegment.selectedSegmentIndex = 0
                } else {
                    cycleSegment.selectedSegmentIndex = 1
                    let closing = (startDay == 1) ? 31 : (startDay - 1)
                    closingDayStepper.value = Double(closing)
                }
            case .custom:
                cycleSegment.selectedSegmentIndex = 0
            }

            let days = max(0, c.notifyDaysBefore)
            notifyDaysStepper.value = Double(days)
            showTimeRow = days > 0

            if let dc = c.dailyReminderTime, let date = Calendar.current.date(from: dc) {
                reminderTimePicker.date = date
            } else {
                var comps = DateComponents(); comps.hour = 9; comps.minute = 0
                reminderTimePicker.date = Calendar.current.date(from: comps) ?? Date()
            }
        } else {
            cycleSegment.selectedSegmentIndex = 0
            closingDayStepper.value = 25
            notifyDaysStepper.value = 0
            showTimeRow = false
            var comps = DateComponents(); comps.hour = 9; comps.minute = 0
            reminderTimePicker.date = Calendar.current.date(from: comps) ?? Date()
        }

        refreshCycleLabel()
        refreshNotifyLabel()
        refreshPreview()
    }

    // MARK: - Sections
    private enum Section: Int, CaseIterable { case basics, cycle, reminder }

    override func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .basics:   return 2
        case .cycle:    return cycleSegment.selectedSegmentIndex == 0 ? 1 : 1 /* mode */ + 1 /* closing row */
        case .reminder: return showTimeRow ? 2 : 1 // days-before (+ time)
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .basics: return "Basics"
        case .cycle: return "Spending Cycle"
        case .reminder: return "Reminders"
        }
    }

//    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
//        switch Section(rawValue: section)! {
//        case .cycle:
//            return nil
//        case .reminder:
//            return nil
//        default:
//            return nil
//        }
//    }

    // Custom footer with preview
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard Section(rawValue: section) == .reminder else { return nil }
        let container = UIView()
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(previewLabel)
        NSLayoutConstraint.activate([
            previewLabel.leadingAnchor.constraint(equalTo: container.layoutMarginsGuide.leadingAnchor),
            previewLabel.trailingAnchor.constraint(equalTo: container.layoutMarginsGuide.trailingAnchor),
            previewLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            previewLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10)
        ])
        return container
    }
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return Section(rawValue: section) == .reminder ? UITableView.automaticDimension : 0.01
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
//                cell.detailTextLabel?.text = "SGD"
//                cell.detailTextLabel?.textColor = .tertiaryLabel
            }

        case .cycle:
            if indexPath.row == 0 {
                cell.textLabel?.text = "Mode"
                addAccessory(cycleSegment, into: cell)
            } else {
                cell.textLabel?.text = "Closing day"
                let stack = UIStackView(arrangedSubviews: [closingDayLabel, closingDayStepper])
                stack.axis = .horizontal
                stack.alignment = .center
                stack.spacing = 12
                addAccessory(stack, into: cell)
                cell.accessoryType = .disclosureIndicator   // tap to pop calendar
            }

        case .reminder:
            if indexPath.row == 0 {
                cell.textLabel?.text = "Days before"
                let stack = UIStackView(arrangedSubviews: [notifyDaysLabel, notifyDaysStepper])
                stack.axis = .horizontal
                stack.alignment = .center
                stack.spacing = 12
                addAccessory(stack, into: cell)
                cell.accessoryType = .disclosureIndicator   // tap to pop calendar for next date
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

    // MARK: - Selection: present calendars in a sheet
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section)! {
        case .cycle:
            if cycleSegment.selectedSegmentIndex == 1, indexPath.row == 1 {
                presentCalendarSheet(title: "", initial: dateForDay(Int(closingDayStepper.value))) { picked in
                    let day = Calendar.current.component(.day, from: picked)
                    self.closingDayStepper.value = Double(day)
                    self.refreshCycleLabel()
                    self.refreshPreview()
                }
            }
        case .reminder:
            if indexPath.row == 0 {
                // choose a concrete date; we'll convert to “days before”
                let isCalendar = (cycleSegment.selectedSegmentIndex == 0)
                let chosenClosing = Int(closingDayStepper.value)
                let nextClose = nextClosingDate(from: Date(), modeIsCalendar: isCalendar, chosenClosingDay: chosenClosing)

                presentCalendarSheet(title: "", initial: Date()) { picked in
                    let cal = Calendar.current
                    // derive delta in whole days
                    let delta = max(0, min(15, cal.dateComponents([.day],
                        from: cal.startOfDay(for: picked),
                        to: cal.startOfDay(for: nextClose)).day ?? 0))
                    self.notifyDaysStepper.value = Double(delta)

                    // toggle time row if needed
                    let shouldShow = delta > 0
                    if shouldShow != self.showTimeRow {
                        self.showTimeRow = shouldShow
                        let s = Section.reminder.rawValue
                        self.tableView.beginUpdates()
                        if shouldShow {
                            self.tableView.insertRows(at: [IndexPath(row: 1, section: s)], with: .fade)
                        } else {
                            self.tableView.deleteRows(at: [IndexPath(row: 1, section: s)], with: .fade)
                        }
                        self.tableView.endUpdates()
                    }
                    self.refreshNotifyLabel()
                    self.refreshPreview()
                }
            }
        default: break
        }
    }

    // MARK: - UI helpers
    private func addField(_ field: UITextField, into cell: UITableViewCell) {
        field.translatesAutoresizingMaskIntoConstraints = false
        field.backgroundColor = .secondarySystemGroupedBackground
        field.layer.cornerRadius = 10
        field.clipsToBounds = true
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 36))
        field.leftViewMode = .always
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

    // MARK: - Sheet date pickers
    private func presentCalendarSheet(title: String, initial: Date, onDone: @escaping (Date) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)

        let picker = UIDatePicker()
        if #available(iOS 13.4, *) { picker.preferredDatePickerStyle = .inline } // calendar style
        picker.datePickerMode = .date
        picker.date = initial

        alert.view.addSubview(picker)
        picker.translatesAutoresizingMaskIntoConstraints = false
        let height: CGFloat = 310
        alert.view.heightAnchor.constraint(equalToConstant: height).isActive = true
        NSLayoutConstraint.activate([
            picker.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor, constant: 8),
            picker.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor, constant: -8),
            picker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 8),
            picker.heightAnchor.constraint(equalToConstant: height - 60)
        ])

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { _ in
            onDone(picker.date)
        }))

        // iPad safety
        if let pop = alert.popoverPresentationController {
            pop.sourceView = self.view
            pop.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY-10, width: 1, height: 1)
            pop.permittedArrowDirections = []
        }
        present(alert, animated: true)
    }

    private func dateForDay(_ day: Int) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month], from: Date())
        let last = lastDayCount(of: Date())
        comps.day = min(max(1, day), last)
        return Calendar.current.date(from: comps) ?? Date()
    }

    // MARK: - Actions
    @objc private func onCycleChanged(_ sender: UISegmentedControl) {
        let s = Section.cycle.rawValue
        let current = tableView.numberOfRows(inSection: s)
        let target = (sender.selectedSegmentIndex == 0) ? 1 : 2
        tableView.beginUpdates()
        if current < target {
            tableView.insertRows(at: [IndexPath(row: 1, section: s)], with: .fade)
        } else if current > target {
            tableView.deleteRows(at: [IndexPath(row: 1, section: s)], with: .fade)
        }
        tableView.endUpdates()
        refreshCycleLabel()
        refreshPreview()
    }

    @objc private func onClosingDayChanged() {
        refreshCycleLabel()
        refreshPreview()
    }

    @objc private func onNotifyDaysChanged() {
        let shouldShow = Int(notifyDaysStepper.value) > 0
        let s = Section.reminder.rawValue
        let current = tableView.numberOfRows(inSection: s)
        let target = shouldShow ? 2 : 1
        tableView.beginUpdates()
        if current < target {
            tableView.insertRows(at: [IndexPath(row: 1, section: s)], with: .fade)
        } else if current > target {
            tableView.deleteRows(at: [IndexPath(row: 1, section: s)], with: .fade)
        }
        tableView.endUpdates()
        showTimeRow = shouldShow
        refreshNotifyLabel()
        refreshPreview()
    }

    @objc private func onTimeChanged() {
        refreshPreview()
    }

    // MARK: - Label/Preview Refresh
    private func refreshCycleLabel() {
        if cycleSegment.selectedSegmentIndex == 0 {
            closingDayLabel.text = "—"
        } else {
            let closing = Int(closingDayStepper.value)
            let start = (closing == 31) ? 1 : (closing + 1)
            closingDayLabel.text = "\(closing)  (start on \(start))"
        }
    }

    private func refreshNotifyLabel() {
        let d = Int(notifyDaysStepper.value)
        notifyDaysLabel.text = d == 0 ? "Off" : "\(d) day\(d == 1 ? "" : "s") before"
    }

    private func refreshPreview() {
        let isCalendar = (cycleSegment.selectedSegmentIndex == 0)
        let chosenClosing = Int(closingDayStepper.value)
        let daysBefore = Int(notifyDaysStepper.value)
        let timeComps = (daysBefore > 0)
            ? Calendar.current.dateComponents([.hour, .minute], from: reminderTimePicker.date)
            : nil

        if let date = nextReminderDate(from: Date(),
                                       modeIsCalendar: isCalendar,
                                       chosenClosingDay: chosenClosing,
                                       notifyDaysBefore: daysBefore,
                                       time: timeComps) {
            let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short
            previewLabel.text = "Next reminder: \(f.string(from: date))"
        } else {
            let nextClose = nextClosingDate(from: Date(),
                                            modeIsCalendar: isCalendar,
                                            chosenClosingDay: chosenClosing)
            let f = DateFormatter(); f.dateStyle = .medium
            previewLabel.text = "Next closing: \(f.string(from: nextClose))"
        }
    }

    // MARK: - Save / Close
    @objc private func close() { dismiss(animated: true) }

    @objc private func save() {
        // Validate
        guard let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            showAlert("Please enter a card name."); return
        }
        guard
            let raw = targetField.text?.replacingOccurrences(of: ",", with: ""),
            let amount = Double(raw), amount > 0
        else {
            showAlert("Please enter a valid target amount (e.g. 1000.00)."); return
        }

        let cents = Int((amount * 100.0).rounded())
        let cycle: CycleType = {
            if cycleSegment.selectedSegmentIndex == 0 { return .monthly(startDay: 1) }
            let closing = max(1, min(31, Int(closingDayStepper.value)))
            let start = (closing == 31) ? 1 : (closing + 1)
            return .monthly(startDay: start)
        }()

        let notifyDays = Int(notifyDaysStepper.value)
        let dailyTime: DateComponents? = (notifyDays > 0)
            ? Calendar.current.dateComponents([.hour, .minute], from: reminderTimePicker.date)
            : nil

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

    // MARK: - Monthly math helpers
    private func lastDayCount(of date: Date) -> Int {
        let cal = Calendar.current
        let range = cal.range(of: .day, in: .month, for: date)!
        return range.count
    }
    private func closingDate(inSameMonthAs baseMonthDate: Date,
                             modeIsCalendar: Bool,
                             chosenClosingDay: Int) -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month], from: baseMonthDate)
        let last = lastDayCount(of: baseMonthDate)
        comps.day = modeIsCalendar ? last : min(max(1, chosenClosingDay), last)
        return cal.date(from: comps)!
    }
    private func nextClosingDate(from: Date,
                                 modeIsCalendar: Bool,
                                 chosenClosingDay: Int) -> Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: from)
        let thisMonthClosing = closingDate(inSameMonthAs: today,
                                           modeIsCalendar: modeIsCalendar,
                                           chosenClosingDay: chosenClosingDay)
        if today <= thisMonthClosing { return thisMonthClosing }
        let nextMonth = cal.date(byAdding: .month, value: 1, to: today)!
        return closingDate(inSameMonthAs: nextMonth,
                           modeIsCalendar: modeIsCalendar,
                           chosenClosingDay: chosenClosingDay)
    }
    private func nextReminderDate(from now: Date,
                                  modeIsCalendar: Bool,
                                  chosenClosingDay: Int,
                                  notifyDaysBefore: Int,
                                  time: DateComponents?) -> Date? {
        guard notifyDaysBefore > 0 else { return nil }
        let cal = Calendar.current
        let close = nextClosingDate(from: now, modeIsCalendar: modeIsCalendar, chosenClosingDay: chosenClosingDay)
        guard let raw = cal.date(byAdding: .day, value: -notifyDaysBefore, to: close) else { return nil }
        if let h = time?.hour, let m = time?.minute {
            var c = cal.dateComponents([.year, .month, .day], from: raw)
            c.hour = h; c.minute = m
            return cal.date(from: c)
        }
        return raw
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


//jpack compose
