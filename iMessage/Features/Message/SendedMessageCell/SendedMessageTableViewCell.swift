//
//  SendedMessageTableViewCell.swift
//  iMessage
//
//  Created by Quan Nguyen on 10/15/20.
//

import UIKit
import Reusable
import Kingfisher
import RxSwift

class SendedMessageTableViewCell: UITableViewCell, NibReusable {
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var messageBackgroundView: UIView!
    @IBOutlet weak var messageImageView: UIImageView!
    
    let reloadTableView = PublishSubject<Void>()
    let isSelectedMessage = PublishSubject<Message>()
    var message: Message?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        setupLongPressGesture()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        messageImageView.image = nil
    }
    
    func setupLongPressGesture() {
        let longPressGesture:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        longPressGesture.minimumPressDuration = 0.5
        if messageImageView.image == nil {
            messageBackgroundView.addGestureRecognizer(longPressGesture)
        } else {
            messageImageView.isUserInteractionEnabled = true
            messageImageView.addGestureRecognizer(longPressGesture)
        }
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard let message = self.message else { return }
        if gestureRecognizer.state == .began {
            isSelectedMessage.onNext(message)
            messageBackgroundView.backgroundColor = UIColor(named: "selected-message")
        }
    }
    
    func handleUnselect() {
        messageBackgroundView.backgroundColor = .systemBlue
    }
    
    func configCell(message: Message) {
        self.message = message
        self.selectionStyle = .none
        if message.content == "" || message.content == nil {
            messageBackgroundView.isHidden = true
        } else {
            messageBackgroundView.isHidden = false
        }
        if let url = message.imageURL {
            let processor = DownsamplingImageProcessor(size: messageImageView.bounds.size)
            messageImageView.kf.indicatorType = .activity
            messageImageView.kf.setImage(
                with: url,
                placeholder: UIImage(named: "image-placeholder"),
                options: [
                    .processor(processor),
                    .scaleFactor(UIScreen.main.scale),
                    .transition(.fade(1)),
                    .cacheOriginalImage
                ])
        }
        messageLabel.text = message.content
    }
    
}
