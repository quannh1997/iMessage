//
//  UserListViewController.swift
//  iMessage
//
//  Created by Quan Nguyen on 10/30/20.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

typealias UserSectionModel = SectionModel<String, User>

class UserListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var currentUsernameLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var logoutButton: UIButton!
    
    
    private let disposeBag = DisposeBag()
    var currentUser = User(id: nil, username: nil, password: nil)
    private var users = [User]()
    
    private lazy var dataSource = RxTableViewSectionedReloadDataSource<UserSectionModel> { (_, tableView, indexpath, user) -> UITableViewCell in
        let cell = tableView.dequeueReusableCell(for: indexpath) as UserTableViewCell
        cell.configCell(name: user.username ?? "")
        return cell
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupTableView()
        setupDataSource()
        setupView()
    }
    
    func setupTableView() {
//        tableView.dataSource = nil
        tableView.delegate = self
        tableView.register(cellType: UserTableViewCell.self)
        tableView.tableFooterView = UIView()
    }
    
    private func setupDataSource() {
        guard let username = LocalDatabaseManager.shared.getLastUser()?.username else { return }
        let allRoom = FirebaseDatabaseManager.shared.getAllRoom(username: username)
        
        let userSectionModel = searchBar.rx.text
            .flatMap { query -> Observable<[UserSectionModel]> in
                guard let userID = LocalDatabaseManager.shared.getLastUser()?.id else { return .empty() }
                return FirebaseDatabaseManager.shared.getAllUser()
                    .map { $0.filter { $0.id != userID } }
                    .map { users -> [UserSectionModel] in
                        guard let query = query, query != "" else { return [UserSectionModel(model: "", items: users)] }
                        let filterData = users.filter { ($0.username?.lowercased().contains(query.lowercased()) ?? true)
                        }
                        return [UserSectionModel(model: "", items: filterData)]
                    }
            }
        
        userSectionModel
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .flatMapLatest { indexPath -> Observable<User?> in
                return userSectionModel
                    .map { userSectionModels -> User? in
                        return userSectionModels.first?.items[indexPath.row]
                    }
            }
            .subscribe(onNext: { [weak self] user in
                guard let self = self, let user = user  else { return }
                let storyboard = UIStoryboard(name: "MessageViewController", bundle: nil)
                let messageViewController = storyboard.instantiateViewController(withIdentifier: "MessageViewController") as! MessageViewController
                var checker = false
                allRoom.take(1).subscribe(onNext: { rooms in
                    rooms.forEach { room in
                        guard let usernames = room.users, let username = user.username  else { return }
                        if usernames.contains(username) {
                            checker = true
                            messageViewController.room = room
                            self.navigationController?.pushViewController(messageViewController, animated: true)
                            return
                        } 
                    }
                    if checker == false {
                        messageViewController.room.users?.append(user.username ?? "")
                        self.navigationController?.pushViewController(messageViewController, animated: true)
                    }
                })
                .disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
    }
    
    private func setupView() {
        currentUsernameLabel.text = currentUser.username
        
        logoutButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                LocalDatabaseManager.shared.removeAllUsers()
                self?.navigationController?.popToRootViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
}

extension UserListViewController: UITableViewDelegate {
}
