//
//  MPSegmentControlDelegate.swift
//
//  Created by Miroslav Perovic on 10/17/16.
//  Copyright © 2017 Miroslav Perovic. All rights reserved.
//

import UIKit

@objc protocol MPSegmentControlDelegate {

	@objc optional func indicatorViewRelativeTo(position: CGFloat, onSegmentControl segmentControl: MPSegmentedControl)

}
