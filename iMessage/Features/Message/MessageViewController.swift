//
//  MessageViewController.swift
//  iMessage
//
//  Created by Quan Nguyen on 10/9/20.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import SVProgressHUD

typealias MessageSectionModel = SectionModel<String, Message>

class MessageViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var uploadImageButton: UIButton!
    @IBOutlet weak var buttonBackgroundView: UIView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBAction func uploadImage(_ sender: UIButton) {
        self.imagePicker.present(from: sender)
    }
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var updateButton: UIButton!
    
    var data = [Message]()
    var room = Room(id: nil, name: nil, users: [], messages: nil)
    var contents = [String]()
    var imagePicker: ImagePicker!
    private let buttonBackgroundHidenEvent = BehaviorSubject<Bool>(value: true)
    private var selectedMessage: Message?
    private let isSelectedMessage = PublishSubject<Bool>()
    private let loadNewestMessage = BehaviorSubject<Void>(value: ())
    private let loadMoreMessage = PublishSubject<Void>()
    private let allMessages = BehaviorRelay<[Message]>(value: [])
    private var isLoadMoreEnabled = true
    
    let disposeBag = DisposeBag()
    
    private lazy var dataSource = RxTableViewSectionedReloadDataSource<MessageSectionModel> { [weak self] (_, tableView, indexpath, message) -> UITableViewCell in
        if message.userID == LocalDatabaseManager.shared.getLastUser()?.id {
            guard let self = self else { return UITableViewCell() }
            let cell = tableView.dequeueReusableCell(for: indexpath) as SendedMessageTableViewCell
            cell.configCell(message: message)
            cell.isSelectedMessage
                .subscribe(onNext: { [weak self] selectedMessage in
                    guard let self = self else { return }
                    self.selectedMessage = selectedMessage
                    self.isSelectedMessage.onNext(true)
                    self.buttonBackgroundHidenEvent.onNext(false)
                    self.buttonBackgroundView.setView(hidden: false)
                    self.buttonBackgroundView.setupShadow()
                })
                .disposed(by: self.disposeBag)
            self.buttonBackgroundHidenEvent
                .subscribe(onNext: { result in
                    if result {
                        cell.handleUnselect()
                    }
                })
                .disposed(by: self.disposeBag)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(for: indexpath) as ReceivedMessageTableViewCell
            cell.configCell(message: message)
            return cell
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        setupNavigationTitle()
        setupTableView()
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
        setupTapGesture()
        addKeyboardNotification()
        // comment
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func addKeyboardNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        var keyboardHeight: CGFloat = 0
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardSize.height
        }
        tableView.contentInset = UIEdgeInsets(top: keyboardHeight, left: 0, bottom: 0, right: 0)
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func setupTapGesture() {
        let mytapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.view.addGestureRecognizer(mytapGestureRecognizer)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer){
        buttonBackgroundView.setView(hidden: true)
        buttonBackgroundHidenEvent.onNext(true)
        view.endEditing(true)
    }
    
    func deteteMessage(id: String) {
        let uialert = UIAlertController(title: "Are you sure?", message: "", preferredStyle: .alert)
        uialert.addAction(UIAlertAction(title: "Delete",
                                        style: .default,
                                        handler: { _ in
                                            guard let roomID = self.room.id else  { return }
                                            let error = FirebaseDatabaseManager.shared.deleteMessage(roomID: roomID, messageID: id)
                                            if let error = error {
                                                print(error.localizedDescription)
                                            }
                                            self.buttonBackgroundView.setView(hidden: true)
                                            self.buttonBackgroundHidenEvent.onNext(true)
                                        }))
        uialert.addAction(UIAlertAction(title: "Cancel",
                                        style: .cancel,
                                        handler: { [weak self]_ in
                                            guard let self = self else  { return }
                                            self.buttonBackgroundView.setView(hidden: true)
                                            self.buttonBackgroundHidenEvent.onNext(true)
                                        }))
        self.present(uialert, animated: true, completion: nil)
    }
    
    func setupNavigationTitle() {
        guard let currentUserName = LocalDatabaseManager.shared.getLastUser()?.username else { return }
        title = room.users?.filter { $0 != currentUserName }.joined(separator: ", ")
    }
    
    func setupTableView() {
        tableView.register(cellType: ReceivedMessageTableViewCell.self)
        tableView.register(cellType: SendedMessageTableViewCell.self)
        tableView.delegate = self
    }
    
    func createMessage(content: String?, image: UIImage? = nil) {
        let currentUser = LocalDatabaseManager.shared.getLastUser()
        guard let userID = currentUser?.id, let username = currentUser?.username else { return }
        if let roomID = room.id {
            FirebaseDatabaseManager.shared.createMessage(message: Message(content: content, userID: userID), roomID: roomID, image: image)
        } else {
            room.users?.append(username)
            let newRoomID = FirebaseDatabaseManager.shared.createRoom(room: self.room)
            room.id = newRoomID
            var messages = allMessages.value
            let newMessage = Message(content: content, userID: userID)
            messages.append(newMessage)
            allMessages.accept(messages)
            FirebaseDatabaseManager.shared.createMessage(message: Message(content: content, userID: userID), roomID: newRoomID, image: image)
        }
    }
    
    func editMessage(content: String) {
        guard let roomID = room.id, var selectedMessage = selectedMessage else { return }
        selectedMessage.content = content
        selectedMessage.updatedTime = NSDate().timeIntervalSince1970
        let error = FirebaseDatabaseManager.shared.editMessage(roomID: roomID, newMessage: selectedMessage)
        if let error = error {
            print(error.localizedDescription)
        }
    }
    
    override func setupObservables() {
        let activityIndicator = ActivityIndicator()
        var count: UInt = 0
        
        let firstLoad = loadNewestMessage
            .flatMap { [weak self] _ -> Observable<[Message]> in
                guard let self = self, let roomID = self.room.id else { return .just([]) }
                return FirebaseDatabaseManager.shared.getNewestMessage(roomID: roomID)
                    .do(onNext: { (_, messagesCount) in
                        count = messagesCount
                    })
                    .map { $0.0 }
                    .trackActivity(activityIndicator)
            }
        
        firstLoad
            .subscribe(onNext: { [weak self] messages in
                guard let self = self else { return }
                self.allMessages.accept(messages)
            })
            .disposed(by: disposeBag)
        
        let loadMore = loadMoreMessage
            .flatMap { [weak self] _ -> Observable<[Message]> in
                guard
                    let self = self,
                    let roomID = self.room.id,
                    let fromKey = self.data.first?.id
                else { return .just([]) }
                return FirebaseDatabaseManager.shared.loadMoreMessage(roomID: roomID, fromKey: fromKey)
                    .do(onNext: { (messages, messageCount) in
                        count += messageCount
                    })
                    .map { $0.0 }
                    .trackActivity(activityIndicator)
            }
        
        loadMore
            .subscribe (onNext: { [weak self] messages in
                guard let self = self else { return }
                if self.allMessages.value.count <= count && count != 0 {
                    self.isLoadMoreEnabled = true
                    let messagesLoaded = Array(messages + self.allMessages.value)
                    self.allMessages.accept(messagesLoaded)
                    self.tableView.scrollToRow(at: IndexPath(row: messages.count, section: 0), at: .top, animated: false)
                } else {
                    self.isLoadMoreEnabled = false
                }
            })
            .disposed(by: disposeBag)
        
        allMessages.skip(1)
            .do(onNext: { [weak self] allMessages in
                guard let self = self else { return }
                if self.data.isEmpty && allMessages.count > 0 {
                    DispatchQueue.main.async {
                        self.tableView.scrollTableViewToBottom(animated: false)
                    }
                }
                self.data = allMessages
            })
            .map({ allMessages -> [MessageSectionModel] in
                return [MessageSectionModel(model: "", items: allMessages)]
            })
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        sendButton.rx.tap
            .subscribe { [weak self] _ in
                guard let self = self else { return }
                if let content = self.textField.text {
                    if content.isEmpty {
                        return
                    }
                    self.createMessage(content: content)
                    self.textField.text = nil
                    self.buttonBackgroundHidenEvent.onNext(true)
                }
            }
            .disposed(by: disposeBag)
        
        updateButton.rx.tap
            .subscribe { [weak self] _ in
                guard let self = self else { return }
                if let content = self.textField.text {
                    if content.isEmpty {
                        return
                    }
                    self.editMessage(content: content)
                    self.textField.text = nil
                    self.updateButton.isHidden = true
                    self.sendButton.isHidden = false
                    self.buttonBackgroundHidenEvent.onNext(true)
                }
            }
            .disposed(by: disposeBag)
        
        buttonBackgroundHidenEvent
            .subscribe(onNext: { [weak self] result in
                guard let self = self else { return }
                if !result {
                    if (self.selectedMessage?.imageURL) != nil {
                        self.editButton.isHidden = true
                    } else {
                        self.editButton.isHidden = false
                    }
                    
                    self.deleteButton.rx.tap
                        .subscribe(onNext: { [weak self] _ in
                            guard let self = self, let id = self.selectedMessage?.id else { return }
                            self.deteteMessage(id: id)
                        })
                        .disposed(by: self.disposeBag)
                    
                    self.editButton.rx.tap
                        .subscribe(onNext: { [weak self] _ in
                            guard let self = self, let oldContent = self.selectedMessage?.content else { return }
                            self.textField.text = oldContent
                            self.buttonBackgroundView.setView(hidden: true)
                            self.textField.becomeFirstResponder()
                            self.sendButton.isHidden = true
                            self.updateButton.isHidden = false
                        })
                        .disposed(by: self.disposeBag)
                }
            })
            .disposed(by: disposeBag)
        
        activityIndicator.asObservable()
            .subscribe(onNext: { isProgressing in
                if isProgressing {
                    SVProgressHUD.show()
                } else {
                    SVProgressHUD.dismiss()
                }
            })
            .disposed(by: disposeBag)
        
    }
    
}

extension MessageViewController: UITableViewDelegate {
    //    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    //        if indexPath.row == 0 && isLoadMoreEnabled {
    //            print("load more")
    //            loadMoreMessage.onNext(())
    //        }
    //    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if tableView.contentOffset.y == 0 && isLoadMoreEnabled {
            print("load more")
            loadMoreMessage.onNext(())
        }
    }
}

extension MessageViewController: ImagePickerDelegate {
    
    func didSelect(image: UIImage?) {
        createMessage(content: nil, image: image)
    }
}
