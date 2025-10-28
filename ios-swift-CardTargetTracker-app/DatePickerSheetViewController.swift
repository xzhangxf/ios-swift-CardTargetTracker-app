//
//  DatePickerSheetViewController.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 28/10/25.
//

import UIKit

final class DatePickerSheetViewController: UIViewController {
    // Public
    var initialDate: Date = Date()
    var onPicked: ((Date) -> Void)?

    // UI
    private let datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        if #available(iOS 14.0, *) { dp.preferredDatePickerStyle = .inline }
        return dp
    }()
    private let doneButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Done", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        datePicker.date = initialDate
        doneButton.addTarget(self, action: #selector(didTapDone), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [datePicker, doneButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            doneButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let sheet = presentationController as? UISheetPresentationController {
            if #available(iOS 16.0, *) {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 24
            } else {
                sheet.detents = [.medium()]
            }
        }
    }

    @objc private func didTapDone() {
        onPicked?(datePicker.date)
        dismiss(animated: true)
    }
}
