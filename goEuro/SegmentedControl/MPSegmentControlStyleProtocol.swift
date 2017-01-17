//
//  MPSegmentControlStyleProtocol.swift
//
//  Created by Miroslav Perovic on 1/12/17.
//  Copyright © 2017 Miroslav Perovic. All rights reserved.
//

import UIKit

@objc protocol MPSegmentControlCellStateDelegate {
	
	@objc optional func segmentControlCellSelectedState(_ segmentControlCell: MPSegmentedControlCell, forIndex index: Int)
	@objc optional func segmentControlCellNormalState(_ segmentControlCell: MPSegmentedControlCell,  forIndex index: Int)

}
