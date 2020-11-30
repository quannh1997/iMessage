//
//  RegisterViewController.swift
//  iMessage
//
//  Created by Quan Nguyen on 10/27/20.
//

import UIKit
import RxCocoa
import RxSwift
import SVProgressHUD

class RegisterViewController: BaseViewController {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTexField: UITextField!
    @IBOutlet weak var usernameValidateLabel: UILabel!
    @IBOutlet weak var passwordValidateLabel: UILabel!
    @IBOutlet weak var confirmPasswordValidateLabel: UILabel!
    @IBOutlet weak var registerButton: UIButton!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupErrorLabel()
        handleLogin()
        // Do any additional setup after loading the view.
    }
    
    private func validateRegister() -> Observable<(Bool, User?)> {
        return registerButton.rx.tap
            .withLatestFrom(Observable.combineLatest(usernameTextField.rx.text, passwordTextField.rx.text, confirmPasswordTexField.rx.text))
            .flatMap { [weak self] (username, password, passwordConfirm) -> Observable<(Bool, User?)> in
                guard
                    let self = self,
                    let username = username,
                    let password = password,
                    let passwordConfirm = passwordConfirm
                else { return .empty() }
                if self.validateTextField(username: username, password: password, passwordConfirm: passwordConfirm)  {
                    return .just((true, User(id: nil,
                                             username: username,
                                             password: password)))
                } else {
                    return .just((false, nil))
                }
            }
    }
    
    private func validateTextField(username: String, password: String, passwordConfirm: String) -> Bool {
        let checkUsername = {
            return username.isAlphanumeric && username.count > 5
        }
        
        let checkPassword = {
            return password.isAlphanumeric && password.count > 5
        }
        
        let checkPasswordConfirm = {
            return password == passwordConfirm
        }
        
        return checkUsername() && checkPassword() && checkPasswordConfirm()
    }
    
    private func setupErrorLabel() {
        registerButton.rx.tap
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
        
        registerButton.rx.tap
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
        
        registerButton.rx.tap
            .withLatestFrom(Observable.combineLatest(passwordTextField.rx.text, confirmPasswordTexField.rx.text))
            .subscribe(onNext: { [weak self] (password, passwordConfirm) in
                guard let self = self,
                      let passwordConfirm = passwordConfirm,
                      let password = password
                else { return }
                if password != passwordConfirm {
                    self.confirmPasswordValidateLabel.text = "Password confirm not equal"
                } else {
                    self.confirmPasswordValidateLabel.text = ""
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func handleLogin() {
        let activityIndicator = ActivityIndicator()
        
        let registerSuccess = validateRegister()
            .flatMapLatest { [weak self] (result, user) -> Observable<(Bool, User?)> in
                guard let self = self, let user = user else { return .empty() }
                return self.checkUsernameExited(user: user)
                    .map { checker -> (Bool, User?) in
                        return (checker,user)
                    }
                    .trackActivity(activityIndicator)
        }
        
        registerSuccess.subscribe(onNext: { [weak self] (result, user) in
            guard let self = self, let user = user else { return }
            if result {
                let uialert = UIAlertController(title: "Register fail", message: "Username exited", preferredStyle: UIAlertController.Style.alert)
                uialert.addAction(UIAlertAction(title: "OK",
                                                style: UIAlertAction.Style.default,
                                                handler: nil))
                   self.present(uialert, animated: true, completion: nil)
            } else {
                FirebaseDatabaseManager.shared.createUser(user: user)
                let uialert = UIAlertController(title: "Register successfully", message: "Login now?", preferredStyle: UIAlertController.Style.alert)
                uialert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                uialert.addAction(UIAlertAction(title: "OK",
                                                style: .default,
                                                handler: { _ in
                                                    let storyboard = UIStoryboard(name: "HomeViewController", bundle: nil)
                                                    let homeViewController = storyboard.instantiateViewController(withIdentifier: "HomeViewController") as! RoomListViewController
                                                    homeViewController.currentUser = user
                                                    self.navigationController?.pushViewController(homeViewController, animated: true)
                                                }))
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
    
    private func checkUsernameExited(user: User) -> Observable<Bool> {
        return FirebaseDatabaseManager.shared.getAllUser()
            .map { users -> Bool in
                guard !users.isEmpty else { return false }
                let usernames = users.map{ $0.username }
                return usernames.contains(user.username)
            }
    }
    
    override func setupViews() {
        passwordTextField.isSecureTextEntry = true
        confirmPasswordTexField.isSecureTextEntry = true
    }

}
