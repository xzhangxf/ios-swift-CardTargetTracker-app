//
//  mainViewController.swift
//  Card Target Tracker
//
//  Created by Xufeng Zhang on 23/10/25.
//

import UIKit

class rootViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .systemBackground
        
     
        
        let Cards = UINavigationController(rootViewController: CardsViewController())
        Cards.tabBarItem = UITabBarItem(title: "Cards", image: UIImage(systemName: "creditcard"), selectedImage: nil)

        let daily = UINavigationController(rootViewController: DailyViewController())
        daily.tabBarItem = UITabBarItem(title: "Daily", image: UIImage(systemName: "calendar"), selectedImage: nil)

        let categories = UINavigationController(rootViewController: CategoriesViewController())
        categories.tabBarItem = UITabBarItem(title: "Categories", image: UIImage(systemName: "chart.pie"), selectedImage: nil)

        let settings = UINavigationController(rootViewController: SettingsViewController())
        settings.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape"), selectedImage: nil)

        viewControllers = [Cards, daily, categories, settings]
    }
}

