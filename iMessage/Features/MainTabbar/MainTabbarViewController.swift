//
//  MainTabbarViewController.swift
//  iMessage
//
//  Created by Quan Nguyen on 10/30/20.
//

import UIKit

class MainTabbarViewController: UITabBarController {
    var currentUser = User(id: nil, username: nil, password: nil)

    @IBOutlet weak var mainTabbar: UITabBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainTabbar.tintColor = .white
        tabBarItem.title = ""
        setupTabbar()
        setupTabbarItem()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    func setupTabbar() {
        let roomListStoryboard = UIStoryboard(name: "RoomListViewController", bundle: nil)
        let roomListViewController = roomListStoryboard.instantiateViewController(withIdentifier: "RoomListViewController") as! RoomListViewController
        roomListViewController.currentUser = currentUser
        
        let userListStoryboard = UIStoryboard(name: "UserListViewController", bundle: nil)
        let userListViewController = userListStoryboard.instantiateViewController(withIdentifier: "UserListViewController") as! UserListViewController
        userListViewController.currentUser = currentUser
        
        self.viewControllers = [roomListViewController, userListViewController]
    }
    
    func setupTabbarItem() {
        let myTabBarItem1 = (self.tabBar.items?[0])! as UITabBarItem
        myTabBarItem1.image = UIImage(systemName: "message")?.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        myTabBarItem1.selectedImage = UIImage(systemName: "message.fill")?.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        
        let myTabBarItem2 = (self.tabBar.items?[1])! as UITabBarItem
        myTabBarItem2.image = UIImage(systemName: "person")?.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        myTabBarItem2.selectedImage = UIImage(systemName: "person.fill")?.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
    }
}
