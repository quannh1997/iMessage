//
//  ReceivedMessageTableViewCell.swift
//  iMessage
//
//  Created by Quan Nguyen on 10/12/20.
//

import UIKit
import Reusable
import Kingfisher
import RxSwift

class ReceivedMessageTableViewCell: UITableViewCell, NibReusable {
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var messageBackgroundView: UIView!
    @IBOutlet weak var messageImageView: UIImageView!
    
    let reloadTableView = PublishSubject<Void>()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        messageImageView.image = nil
    }
    
    func configCell(message: Message) {
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
