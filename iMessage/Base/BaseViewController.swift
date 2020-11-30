//
//  BaseViewController.swift
//  iMessage
//
//  Created by Quan Nguyen on 11/25/20.
//

import UIKit

class BaseViewController: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupObservables()
    }
    
    func setupViews() {
        setupBackBarButtonItem()
    }
    
    func setupObservables() {}
    
    private func setupBackBarButtonItem() {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
}
