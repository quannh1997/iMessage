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

class RoomListViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var currentUsernameLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var logoutButton: UIButton!
    
    private let disposeBag = DisposeBag()
    var currentUser = User(id: nil, username: nil, password: nil)
    private var users = [User]()
        
    private lazy var dataSource = RxTableViewSectionedReloadDataSource<RoomSectionModel> { (_, tableView, indexpath, room) -> UITableViewCell in
        let cell = tableView.dequeueReusableCell(for: indexpath) as RoomTableViewCell
        guard let currentUserName = LocalDatabaseManager.shared.getLastUser()?.username else { return UITableViewCell() }
        let defaultName = room.users?.filter { $0 != currentUserName }.joined(separator: ", ")
        cell.configCell(name: defaultName ?? "")
        return cell
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupTableView()
    }

    func setupTableView() {
        tableView.register(cellType: RoomTableViewCell.self)
        tableView.tableFooterView = UIView()
    }
    
    override func setupObservables() {
        let roomSectionModel = searchBar.rx.text
            .flatMap { query -> Observable<[RoomSectionModel]> in
                guard let username = LocalDatabaseManager.shared.getLastUser()?.username else { return .empty() }
                return FirebaseDatabaseManager.shared.getAllRoom(username: username)
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
    
    override func setupViews() {
        currentUsernameLabel.text = currentUser.username
        
        logoutButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                LocalDatabaseManager.shared.removeAllUsers()
                self?.navigationController?.popToRootViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }

}
