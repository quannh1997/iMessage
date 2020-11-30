//
//  FriendTableViewCell.swift
//  iMessage
//
//  Created by Quan Nguyen on 10/9/20.
//

import UIKit
import Reusable

class RoomTableViewCell: UITableViewCell, NibReusable {
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configCell(name: String) {
        nameLabel.text = name
        self.selectionStyle = .none
    }
}
