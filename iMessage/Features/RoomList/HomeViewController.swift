//
//  HomeViewController.swift
//  iMessage
//
//  Created by Quan Nguyen on 10/9/20.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

typealias RoomSectionModel = SectionModel<String, Room>

class RoomListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var currentUsernameLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var logoutButton: UIButton!
    
    private let disposeBag = DisposeBag()
    var currentUser = User(id: nil, username: nil, password: nil)
    private var users = [User]()
        
    private lazy var dataSource = RxTableViewSectionedReloadDataSource<RoomSectionModel> { (_, tableView, indexpath, room) -> UITableViewCell in
        let cell = tableView.dequeueReusableCell(for: indexpath) as FriendTableViewCell
//        let friendTableViewCell = FriendTableViewCell()
        cell.configCell(name: room.name ?? "")
        return cell
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupTableView()
        setupDataSource()
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    func setupTableView() {
        tableView.register(cellType: FriendTableViewCell.self)
        tableView.tableFooterView = UIView()
    }
    
    private func setupDataSource() {
        let roomSectionModel = searchBar.rx.text
            .flatMap { query -> Observable<[RoomSectionModel]> in
                guard let userID = LocalDatabaseManager.shared.getLastUser()?.id else { return .empty() }
                return FirebaseDatabaseManager.shared.getAllRoom(userID: userID)
                    .map { rooms -> [RoomSectionModel] in
                        guard let query = query, query != "" else { return [RoomSectionModel(model: "", items: rooms)] }
                        let filterData = rooms.filter { ($0.name?.lowercased().contains(query.lowercased()) ?? true)
                        }
                        return [RoomSectionModel(model: "", items: filterData)]
                    }
            }
        
        roomSectionModel
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .flatMapLatest { indexPath -> Observable<Room?> in
                return roomSectionModel
                    .map { roomSectionModels -> Room? in
                        return roomSectionModels.first?.items[indexPath.row]
                    }
            }
            .subscribe(onNext: { [weak self] room in
                guard let self = self, let room = room  else { return }
                let storyboard = UIStoryboard(name: "MessageViewController", bundle: nil)
                let messageViewController = storyboard.instantiateViewController(withIdentifier: "MessageViewController") as! MessageViewController
                messageViewController.room = room
                self.navigationController?.pushViewController(messageViewController, animated: true)
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
