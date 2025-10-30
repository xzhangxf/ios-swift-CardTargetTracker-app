//
//  CardDetailViewController.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 24/10/25.
//

import UIKit

class CardDetailViewController: UITableViewController {
    
    
    private var card: Card
    private var tx: [Transaction] = []
    private var isManaging = false
    private var editItem: UIBarButtonItem!
    
    init(card: Card) {
        self.card = card
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = card.name
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        let addButton1 = UIButton(type: .system)
        addButton1.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton1.tintColor = .systemBlue
        addButton1.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        addButton1.addTarget(self, action: #selector(onAddTransaction), for: .touchUpInside)

        // Put custom button into the nav bar
        let add = UIBarButtonItem(customView: addButton1)

        editItem = UIBarButtonItem(title: "Edit",
                                   style: .plain,
                                   target: self,
                                   action: #selector(toggleManageMode))
        add.tintColor = .systemBlue
        navigationItem.rightBarButtonItems = [add, editItem]
//        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(onEdit))
        let addButton = UIButton(type: .system)
        addButton.setTitle("Add Transaction", for: .normal)
        addButton.addTarget(self, action: #selector(onAddTransaction), for: .touchUpInside)
        tableView.tableFooterView = addButton
        addButton.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 56)
        tableView.tableFooterView = addButton
        tableView.allowsSelectionDuringEditing = true
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
    
    private func reloadData() {
        tx = TransactionManager.shared.transactions(forCard: card.id).sorted { $0.date > $1.date }
        tableView.reloadData()
    }
    
    
    @objc private func toggleEditMode(){
        isManaging.toggle()
        navigationItem.rightBarButtonItem?.title = isManaging ? "Done" : "Edit"
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tx.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let t = tx[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var cfg = UIListContentConfiguration.valueCell()
        cfg.text = Money.toString(cents: t.amountCents)
        let df = DateFormatter()
        df.dateStyle = .medium; df.timeStyle = .none
        cfg.secondaryText = "\(t.category.rawValue.capitalized) · \(df.string(from: t.date))"
        cell.contentConfiguration = cfg
        //cell.accessoryType = .disclosureIndicator
        cell.accessoryType = isManaging ? .none : .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let t = tx[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        if isManaging {
            let vc = AddTransactionViewController(cardId: card.id, editingTransaction: t)
                       vc.onTransactionSaved = { [weak self] in self?.reloadData() }
                       present(UINavigationController(rootViewController: vc), animated: true)
        } else {
            let vc = TransactionDetailViewController(transaction: t)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        guard isManaging else { return nil }
        let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, done in
            let id = self.tx[indexPath.row].id
            TransactionManager.shared.deleteTransaction(id: id)
            self.tx.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }

    
   @objc private func onAddTransaction() {
        let vc = AddTransactionViewController(cardId: card.id)
       vc.onTransactionSaved = { [weak self] in
           self?.reloadData()
       }
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    @objc private func toggleManageMode() {
        isManaging.toggle()
        editItem.title = isManaging ? "Done" : "Edit"
        tableView.reloadData()
//        let vc = AddCardViewController(cardToEdit: card)
//        present(UINavigationController(rootViewController: vc), animated: true)
    }
}
