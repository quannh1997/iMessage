//
//  UserTableViewCell.swift
//  iMessage
//
//  Created by Quan Nguyen on 11/12/20.
//

import UIKit
import Reusable

class UserTableViewCell: UITableViewCell, NibReusable {
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

