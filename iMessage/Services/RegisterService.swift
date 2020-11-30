//
//  RegisterService.swift
//  iMessage
//
//  Created by Quan Nguyen on 10/26/20.
//

import Foundation
import RxSwift

struct Register {
    private let disposeBag = DisposeBag()
    
    func Register(user: User) -> Observable<Bool> {
        return Observable.create { observer -> Disposable in
            FirebaseDatabaseManager.shared.getAllUser()
                .subscribe(onNext: { users in
                    users.forEach { user in
                        guard let username = user.username else { return }
                        if user.username == username {
                            FirebaseDatabaseManager.shared.createUser(user: user)
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
