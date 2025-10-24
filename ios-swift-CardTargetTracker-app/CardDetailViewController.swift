//
//  CardDetailViewController.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 24/10/25.
//

import UIKit

class CardDetailViewController: UITableViewController {
    
    
    private var card: Card
    private var tx: [Transition] = []
    
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
        tableView.register(UITableViewController.self, forCellReuseIdentifier: "cell")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(onEdit))
        let addButton = UIButton(type: .system)
        addButton.setTitle("Add Transition", for: .normal)
        addButton.addTarget(self, action: #selector(onAddTransition), for: .touchUpInside)
        tableView.tableFooterView = addButton
        addButton.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 56)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
    
    
    private func reloadData() {
        let all = TransactionManager.shared.transactions.filter{ $0.cardId == card.id}
        tx = all.sorted{ $0.date > $1.date}
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
        
    }
    
    
   @objc private func onAddTransition() {
        let vc = AddTransactionViewController(cardId: card.id)
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    @objc private func onEdit() {
        let vc = AddCardViewController(cardToEdit: card)
        present(UINavigationController(rootViewController: vc), animated: true)
    }
}
    
    
    
}
