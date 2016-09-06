//
//  CustomTableViewCell.swift
//  MoonRunner
//
//  Created by Bradley Patton on 9/5/16.
//  Copyright © 2016 Zedenem. All rights reserved.
//

import UIKit

class CustomTableViewCell: UITableViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var paceLabel: UILabel!
    
    override func awakeFromNib() { super.awakeFromNib() }
    
    override func setSelected(selected: Bool, animated: Bool) { super.setSelected(selected, animated: animated) }


}
