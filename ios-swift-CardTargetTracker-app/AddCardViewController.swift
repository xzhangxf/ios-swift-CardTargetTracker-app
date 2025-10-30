//
//  AddCardViewController.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 24/10/25.
//
import UIKit
import UserNotifications

class AddCardViewController: UITableViewController {
    
    private let nameField = UITextField()
    private let targetField = UITextField()
    var onCardSaved: (() -> Void)?
    private let cycleSegment = UISegmentedControl(items: ["Calendar Month", "Statement Day"])
    private let statementDatePicker: UIDatePicker   = {
        let p = UIDatePicker()
        p.preferredDatePickerStyle = .wheels
        p.datePickerMode = .date
        p.timeZone = .current
        return p
    }()
    
    //cus the statementDatePicker
    private let monthDayPicker = UIPickerView()
    private var selectedMonth = Calendar.current.component(.month, from: Date())
    private var selectedDay = Calendar.current.component(.day, from: Date())
    private var CurrentYear: Int { Calendar.current.component(.year, from: Date()) }
    
    private let reminderSwitch = UISwitch()
    private let daysBeforePicker = UIPickerView()
    private let timePicker: UIDatePicker = {
        let p = UIDatePicker()
        p.preferredDatePickerStyle = .wheels
        p.datePickerMode = .time
        p.timeZone = .current
        return p
    }()
    
    private var editingCard: Card?
    private var isStatementMode: Bool = false
    private var isReminderOn: Bool = true
    private let daysBeforeData = Array(0...30)
    
    
    init(cardToEdit: Card? = nil) {
        self.editingCard = cardToEdit
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = editingCard == nil ? "Add Card" : "Edit Card"
        
        navigationItem.leftBarButtonItem =
        UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))
        navigationItem.rightBarButtonItem =
        UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        
        nameField.placeholder = "Card Name"
        nameField.clearButtonMode = .whileEditing
        
        targetField.placeholder = "Target Amount (e.g. 1000.00)"
        targetField.keyboardType = .decimalPad
        targetField.clearButtonMode = .whileEditing
        
        cycleSegment.selectedSegmentIndex = 0
        cycleSegment.addTarget(self, action: #selector(onCycleChanged), for: .valueChanged)
        
        let now = Date()
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: now)
        comps.year = Calendar.current.component(.year, from: now)
        let defaultDate = Calendar.current.date(from: comps) ?? now
        statementDatePicker.date = defaultDate
        
        reminderSwitch.addTarget(self, action: #selector(onReminderSwitch), for: .valueChanged)
        daysBeforePicker.dataSource = self
        daysBeforePicker.delegate = self
        

        
        if let defaultRow = daysBeforeData.firstIndex(of: 3) {
            daysBeforePicker.selectRow(defaultRow, inComponent: 0, animated: false)
        }
        
        if let c = editingCard {
            nameField.text = c.name
            targetField.text = String(format: "%.2f", Double(c.targetCents) / 100.0)
            switch c.cycle {
            case .monthly(let startDay):
                isStatementMode = startDay != 1
                cycleSegment.selectedSegmentIndex = isStatementMode ? 1 : 0
                let thisMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now))!
                let day = min(startDay, BillingCycle.maxDay(inMonthStarting: thisMonth, cal: .current))
                statementDatePicker.date = Calendar.current.date(bySetting: .day, value: day, of: thisMonth) ?? defaultDate
            case .custom:
                isStatementMode = true
                cycleSegment.selectedSegmentIndex = 1
            }
            isReminderOn = c.notifyDaysBefore > 0 || c.dailyReminderTime != nil
            reminderSwitch.isOn = isReminderOn
            if let row = daysBeforeData.firstIndex(of: max(0, c.notifyDaysBefore)) {
                daysBeforePicker.selectRow(row, inComponent: 0, animated: false)
            }
            if let t = c.dailyReminderTime,
               let d = Calendar.current.date(from: t) {
                timePicker.date = d
            }
        } else {
            reminderSwitch.isOn = isReminderOn
        }
        
        monthDayPicker.dataSource = self
        monthDayPicker.delegate = self
        let m = selectedMonth
        let d = min(selectedDay, maxDay(in: m, year: CurrentYear))
        monthDayPicker.reloadAllComponents()
        monthDayPicker.selectRow(m - 1, inComponent: 0, animated: false)
        monthDayPicker.reloadComponent(1)
        monthDayPicker.selectRow(d - 1, inComponent: 1, animated: false)
    }
    
    // Section 0: Basic (name, target)
    // Section 1: Cycle (segment) + (statement picker when needed)
    // Section 2: Reminder (switch) + (daysBefore picker + time picker when ON)
    override func numberOfSections(in tableView: UITableView) -> Int { 3 }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return isStatementMode ? 2 : 1
        case 2: return isReminderOn ? 3 : 1
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Basic"
        case 1: return "Billing Cycle"
        case 2: return "Reminder"
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
            
        case (0, 0):
            let cell = UITableViewCell()
            nameField.translatesAutoresizingMaskIntoConstraints = false
            nameField.inputAccessoryView = makeToolbar()
            cell.contentView.addSubview(nameField)
            NSLayoutConstraint.activate([
                nameField.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                nameField.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                nameField.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                nameField.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
                nameField.heightAnchor.constraint(equalToConstant: 44),
                
            ])
            return cell
        case (0, 1):
            let cell = UITableViewCell()
            targetField.translatesAutoresizingMaskIntoConstraints = false
            targetField.inputAccessoryView = makeToolbar()
            cell.contentView.addSubview(targetField)
            NSLayoutConstraint.activate([
                targetField.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                targetField.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                targetField.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                targetField.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
                targetField.heightAnchor.constraint(equalToConstant: 44),
            ])
            return cell
            
        case (1, 0):
            let cell = UITableViewCell()
            cell.selectionStyle = .none
            cycleSegment.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(cycleSegment)
            NSLayoutConstraint.activate([
                cycleSegment.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                cycleSegment.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                cycleSegment.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                cycleSegment.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
            ])
            return cell
            
        case (1, 1):
            let cell = UITableViewCell()
            cell.selectionStyle = .none
//            statementDatePicker.translatesAutoresizingMaskIntoConstraints = false
//            cell.contentView.addSubview(statementDatePicker)
//            NSLayoutConstraint.activate([
//                statementDatePicker.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
//                statementDatePicker.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
//                statementDatePicker.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
//                statementDatePicker.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
//            ])
//            return cell

            let stack = UIStackView(arrangedSubviews: [monthDayPicker])
            stack.axis = .horizontal
            stack.alignment = .center
            stack.spacing = 12

            cell.contentView.addSubview(stack)
            stack.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                stack.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                stack.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
                monthDayPicker.heightAnchor.constraint(equalToConstant: 140)
            ])
            return cell
            
        case (2, 0):
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = "Enable Reminder"
            cell.selectionStyle = .none
            reminderSwitch.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(reminderSwitch)
            NSLayoutConstraint.activate([
                reminderSwitch.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                reminderSwitch.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor)
            ])
            return cell
        case (2, 1):
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.selectionStyle = .none
            let title = UILabel()
            title.text = "Days Before"
            title.setContentHuggingPriority(.required, for: .horizontal)
            
            let container = UIStackView(arrangedSubviews: [title, daysBeforePicker])
            container.axis = .horizontal
            container.alignment = .center
            container.spacing = 12
            
            cell.contentView.addSubview(container)
            container.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                container.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                container.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                container.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                container.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
                daysBeforePicker.heightAnchor.constraint(equalToConstant: 140)
            ])
            return cell
        case (2, 2):
            let cell = UITableViewCell()
            cell.selectionStyle = .none
            let title = UILabel()
            title.text = "Time"
            title.translatesAutoresizingMaskIntoConstraints = false
            
            timePicker.translatesAutoresizingMaskIntoConstraints = false
            
            cell.contentView.addSubview(title)
            cell.contentView.addSubview(timePicker)
            NSLayoutConstraint.activate([
                title.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                title.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                
                timePicker.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                timePicker.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                timePicker.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4),
                timePicker.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
            ])
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    @objc private func close() { dismiss(animated: true) }
    
    @objc private func onCycleChanged() {
        isStatementMode = (cycleSegment.selectedSegmentIndex == 1)
        tableView.performBatchUpdates({
            tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
        })
    }
    
    @objc private func onReminderSwitch() {
        isReminderOn = reminderSwitch.isOn
        tableView.performBatchUpdates({
            tableView.reloadSections(IndexSet(integer: 2), with: .automatic)
        })
    }
    
    @objc private func save() {
        guard let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty,
              let text = targetField.text?.replacingOccurrences(of: ",", with: ""),
              let amount = Double(text), amount > 0 else {
            let alert = UIAlertController(title: "Invalid Input", message: "Please enter name and target.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true); return
        }
        
        let cents = Int((amount * 100.0).rounded())
        
        let startDay: Int
        if isStatementMode {
            let comps = Calendar.current.dateComponents([.day], from: statementDatePicker.date)
            startDay = comps.day ?? 1
        } else {
            startDay = 1
        }
        
        let notifyDaysBefore: Int
        let timeComponents: DateComponents?
        if isReminderOn {
            notifyDaysBefore = daysBeforeData[daysBeforePicker.selectedRow(inComponent: 0)]
            let tComps = Calendar.current.dateComponents([.hour, .minute], from: timePicker.date)
            timeComponents = tComps
        } else {
            notifyDaysBefore = 0
            timeComponents = nil
        }
        
        if var c = editingCard {
            c.name = name
            c.targetCents = cents
            c.cycle = .monthly(startDay: startDay)
            c.notifyDaysBefore = notifyDaysBefore
            c.dailyReminderTime = timeComponents
            TransactionManager.shared.updateCard(c)
            NotificationScheduler.scheduleNextReminder(for: c)
        } else {
            let newCard = Card(
                name: name,
                targetCents: cents,
                cycle: .monthly(startDay: startDay),
                notifyDaysBefore: notifyDaysBefore,
                dailyReminderTime: timeComponents
            )
            TransactionManager.shared.addCard(newCard)
            NotificationScheduler.scheduleNextReminder(for: newCard)
        }
        onCardSaved?()
        dismiss(animated: true)
    }
    
    private func maxDay(in month: Int, year: Int) -> Int {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        let cal = Calendar.current
        let date = cal.date(from: comps)!
        let range = cal.range(of: .day, in: .month, for: date)!
        return range.count
    }
    
    private func makeToolbar() -> UIToolbar {
        let tb = UIToolbar()
        tb.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        ]
        tb.sizeToFit()
        return tb
    }
    @objc private func dismissKeyboard() { view.endEditing(true) }
}

extension AddCardViewController: UIPickerViewDataSource, UIPickerViewDelegate {
//    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
//    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { daysBeforeData.count }
//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        let d = daysBeforeData[row]
//        return d == 0 ? "Same day" : "\(d) day(s)"
//    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if pickerView === monthDayPicker {
            return 2
        }
        if pickerView === daysBeforePicker {
            return 1
        }
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView === monthDayPicker {
            if component == 0 { return 12 } // 1~12 月
            return maxDay(in: selectedMonth, year: CurrentYear)
        }
        if pickerView === daysBeforePicker {
            return daysBeforeData.count
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
           if pickerView === monthDayPicker { return component == 0 ? 120 : 100 }
           return 200
       }

       func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
           return 32
       }

       func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
           if pickerView === monthDayPicker {
               if component == 0 { return "\(row + 1) 月" }
               return "\(row + 1) 日"
           }
           if pickerView === daysBeforePicker {
               let d = daysBeforeData[row]
               return d == 0 ? "Same day" : "\(d) day(s)"
           }
           return nil
       }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView === monthDayPicker {
            if component == 0 {
                selectedMonth = row + 1
                let maxD = maxDay(in: selectedMonth, year: CurrentYear)
                if selectedDay > maxD { selectedDay = maxD }
                pickerView.reloadComponent(1)
                pickerView.selectRow(selectedDay - 1, inComponent: 1, animated: true)
            } else {
                selectedDay = row + 1
            }
        }
    }
}
enum NotificationScheduler {
    static func scheduleNextReminder(for card: Card, ref: Date = Date(), calendar: Calendar = .current) {
        guard card.notifyDaysBefore >= 0, let time = card.dailyReminderTime else { return }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [card.id.uuidString])
        let window = BillingCycle.window(for: card, ref: ref, calendar: calendar)
        var triggerDate = calendar.date(byAdding: .day, value: -card.notifyDaysBefore, to: window.end) ?? ref
        var t = DateComponents()
        t.year = calendar.component(.year, from: triggerDate)
        t.month = calendar.component(.month, from: triggerDate)
        t.day = calendar.component(.day, from: triggerDate)
        t.hour = time.hour
        t.minute = time.minute
        triggerDate = calendar.date(from: t) ?? triggerDate
        if triggerDate <= ref {
            let nextWindow = BillingCycle.window(for: card, ref: calendar.date(byAdding: .day, value: 1, to: window.end) ?? ref, calendar: calendar)
            var d2 = calendar.date(byAdding: .day, value: -card.notifyDaysBefore, to: nextWindow.end) ?? ref
            var tt = DateComponents()
            tt.year = calendar.component(.year, from: d2)
            tt.month = calendar.component(.month, from: d2)
            tt.day = calendar.component(.day, from: d2)
            tt.hour = time.hour
            tt.minute = time.minute
            d2 = calendar.date(from: tt) ?? d2
            schedule(at: d2, title: card.name)
        } else {
            schedule(at: triggerDate, title: card.name)
        }

        func schedule(at date: Date, title: String) {
            let content = UNMutableNotificationContent()
            content.title = "Card Reminder"
            content.body = "\(title): cycle ends soon"
            content.sound = .default

            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

            let req = UNNotificationRequest(identifier: card.id.uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(req)
        }
    }
}

//so how the day dateComponents([.year, .month], from:) change the month to 1 of 00 00 and next moth is 1st + 1 month so dateCompionets is auto no need to count by hand
//maxDay function
// calendar.range = cal.range(of .day, in: .month, for: .date)!
// it will return a range like the vail day of the month
// use today date as the make and check the max range of the month can let the start day is x in the month as if satrt day is before this month x it means this month is passed and if it afther the x this menas the this month have not reach and when is = means satrt is today
//so the cycle next month and set the day to the startday use the min(strt Day, nxet monthdays)
//jpack compose
