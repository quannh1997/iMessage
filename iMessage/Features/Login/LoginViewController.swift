//
//  LoginViewController.swift
//  iMessage
//
//  Created by Quan Nguyen on 10/26/20.
//

import UIKit
import RxSwift
import RxCocoa
import SVProgressHUD

class LoginViewController: BaseViewController {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var usernameValidateLabel: UILabel!
    @IBOutlet weak var passwordValidateLabel: UILabel!
    
    private let disposeBag = DisposeBag()
    private var currentUser = User(id: nil, username: nil, password: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        checkLastLogin()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func checkLastLogin() {
        guard let lastUser = LocalDatabaseManager.shared.getLastUser() else { return }
        let storyboard = UIStoryboard(name: "MainTabbarViewController", bundle: nil)
        let mainTabbarViewController = storyboard.instantiateViewController(withIdentifier: "MainTabbarViewController") as! MainTabbarViewController
        mainTabbarViewController.currentUser = lastUser
        self.navigationController?.pushViewController(mainTabbarViewController, animated: true)
    }
    
    override func setupObservables() {
        let activityIndicator = ActivityIndicator()
        
        registerButton.rx.tap
            .subscribe { [weak self] _ in
                guard let self = self else { return }
                let storyboard = UIStoryboard(name: "RegisterViewController", bundle: nil)
                let registerViewController = storyboard.instantiateViewController(withIdentifier: "RegisterViewController") as! RegisterViewController
                self.navigationController?.pushViewController(registerViewController, animated: true)
            }
            .disposed(by: disposeBag)
                
        let loginSuccess: Observable<(Bool, User?)> = validateLogin()
            .flatMapLatest { [weak self] (result, user) -> Observable<(Bool, User?)> in
                guard let self = self, let user = user else { return .empty() }
                return self.checkUserExited(user: user)
                    .trackActivity(activityIndicator)
        }
        
        loginSuccess.subscribe(onNext: { [weak self] (result, user) in
            guard let self = self, let user = user else { return }
            if result {
                let storyboard = UIStoryboard(name: "MainTabbarViewController", bundle: nil)
                let mainTabbarViewController = storyboard.instantiateViewController(withIdentifier: "MainTabbarViewController") as! MainTabbarViewController
                mainTabbarViewController.currentUser = user
                LocalDatabaseManager.shared.createUser(user: user)
                self.navigationController?.pushViewController(mainTabbarViewController, animated: true)
            } else {
                let uialert = UIAlertController(title: "Login fail", message: "Username or password not exited", preferredStyle: UIAlertController.Style.alert)
                uialert.addAction(UIAlertAction(title: "OK",
                                                style: UIAlertAction.Style.default,
                                                handler: nil))
                   self.present(uialert, animated: true, completion: nil)
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
    
    private func validateLogin() -> Observable<(Bool, User?)> {
        return loginButton.rx.tap
            .withLatestFrom(Observable.combineLatest(usernameTextField.rx.text, passwordTextField.rx.text))
            .flatMap { [weak self] (username, password) -> Observable<(Bool, User?)> in
                guard
                    let self = self,
                    let username = username,
                    let password = password
                else { return .empty() }
                if self.validateTextField(username: username, password: password)  {
                    return .just((true, User(id: nil,
                                             username: username,
                                             password: password)))
                } else {
                    return .just((false, nil))
                }
            }
    }
    
    private func checkUserExited(user: User) -> Observable<(Bool, User?)> {
        var userFounded = User(id: nil, username: nil, password: nil)
        return FirebaseDatabaseManager.shared.getAllUser()
            .map { users -> (Bool, User?) in
                guard !users.isEmpty else { return (false, nil) }
                var checker = false
                users.forEach { item in
                    if user.username == item.username && user.password == item.password {
                        checker = true
                        userFounded = item
                        return
                    }
                }
                return (checker, userFounded)
            }
    }
    
    private func validateTextField(username: String, password: String) -> Bool {
        let checkUsername = {
            return username.isAlphanumeric && username.count > 5
        }
        
        let checkPassword = {
            return password.isAlphanumeric && password.count > 5
        }
        
        return checkUsername() && checkPassword()
    }
    
    private func setupErrorLabel() {
        loginButton.rx.tap
            .withLatestFrom(usernameTextField.rx.text)
            .subscribe(onNext: { [weak self] username in
                guard let self = self, let username = username else { return }
                if !username.isAlphanumeric || username.count <= 5 {
                    self.usernameValidateLabel.text = "Username invalid"
                } else {
                    self.usernameValidateLabel.text = ""
                }
            })
            .disposed(by: disposeBag)
        
        loginButton.rx.tap
            .withLatestFrom(passwordTextField.rx.text)
            .subscribe(onNext: { [weak self] password in
                guard let self = self, let password = password else { return }
                if !password.isAlphanumeric || password.count <= 5 {
                    self.passwordValidateLabel.text = "Password invalid"
                } else {
                    self.passwordValidateLabel.text = ""
                }
            })
            .disposed(by: disposeBag)
    }
    
    override func setupViews() {
        passwordTextField.isSecureTextEntry = true
        setupErrorLabel()
    }
}
