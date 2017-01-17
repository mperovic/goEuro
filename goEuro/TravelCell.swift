//
//  TravelCell.swift
//  goEuro
//
//  Created by Miroslav Perovic on 1/14/17.
//  Copyright © 2017 Miroslav Perovic. All rights reserved.
//

import UIKit
import Nuke
import DFCache

final class TravelCell: UITableViewCell {
	@IBOutlet weak var logo: UIImageView?
	@IBOutlet weak var travelTime: UILabel?
	@IBOutlet weak var numberOfChanges: UILabel?
	@IBOutlet weak var price: UILabel?
	@IBOutlet weak var duration: UILabel?
}
