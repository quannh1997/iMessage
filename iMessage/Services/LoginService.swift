//
//  LoginService.swift
//  iMessage
//
//  Created by Quan Nguyen on 10/26/20.
//

import Foundation
import RxSwift

struct LoginService {
    private let disposeBag = DisposeBag()
    
    func login(username: String, password: String) -> Observable<Bool> {
        return Observable.create { observer -> Disposable in
            FirebaseDatabaseManager.shared.getAllUser()
                .subscribe(onNext: { users in
                    users.forEach { user in
                        if username == user.username && password == user.password {
                            observer.onNext(true)
                            observer.onCompleted()
                        } else {
                            observer.onNext(false)
                            observer.onCompleted()
                        }
                    }
                }, onError: { error in
                    observer.onError(error)
                    observer.onCompleted()
                })
                .disposed(by: disposeBag)
            return Disposables.create()
        }
    }
}
