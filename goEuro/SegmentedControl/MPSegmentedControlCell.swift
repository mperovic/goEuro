//
//  MPSegmentedControlCell.swift
//
//  Created by Miroslav Perovic on 10/16/16.
//  Copyright © 2017 Miroslav Perovic. All rights reserved.
//

import UIKit

enum MPSegmentedControlCellLayout {
	case none
	case textOnly
	case imageOnly
	case textWithImage
}

enum MPSegmentedControlCellSpace {
	case fixed
	case scale
}

final class MPSegmentedControlCell: UIView {
	var imageView = UIImageView.init()
	var label = UILabel()
	var labelTextColor = UIColor.white
	var labelFont = UIFont(name: "SFUIDisplay-Medium", size: 13.0)!
	var iconScale: CGFloat = 0.5
	var spaceValue: CGFloat = 8.0 {
		didSet {
			layoutIfNeeded()
		}
	}
	var spaceScale: CGFloat = 0.05 {
		didSet {
			layoutIfNeeded()
		}
	}
	
	var layout: MPSegmentedControlCellLayout = .textOnly {
		didSet {
			layoutIfNeeded()
		}
	}
	
	var interspace: MPSegmentedControlCellSpace = .scale {
		didSet {
			layoutIfNeeded()
		}
	}
	
	init(layout: MPSegmentedControlCellLayout, interspace: MPSegmentedControlCellSpace = .scale) {
		self.layout = layout
		self.interspace = interspace

		super.init(frame: CGRect.zero)
		
		self.commonInit()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		self.commonInit()
	}

	private func commonInit() {
		self.label.font = self.labelFont
		self.label.text = ""
		self.label.textColor = self.labelTextColor
		self.label.backgroundColor = UIColor.clear
		self.addSubview(label)
		
		self.imageView.backgroundColor = UIColor.clear
		self.addSubview(self.imageView)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		label.frame = CGRect.zero
		imageView.frame = CGRect.zero
		switch self.layout {
		case .imageOnly:
			let sideSize = min(self.frame.width , self.frame.height) * self.iconScale
			self.imageView.frame = CGRect.init(
				x: 0, y: 0,
				width: sideSize,
				height: sideSize
			)
			self.imageView.center = CGPoint.init(
				x: self.frame.width / 2,
				y: self.frame.height / 2
			)
			
		case .textOnly:
			label.textAlignment = .center
			label.frame = self.bounds
			
		case .textWithImage:
			label.sizeToFit()
			let sideSize = min(self.frame.width , self.frame.height) * self.iconScale
			self.imageView.frame = CGRect.init(
				x: 0, y: 0,
				width: sideSize,
				height: sideSize
			)
			let space: CGFloat
			switch self.interspace {
			case .fixed:
				space = self.spaceValue
				
			case .scale:
				space = self.frame.width * self.spaceScale
			}
			let elementsWidth: CGFloat = self.imageView.frame.width + space + self.label.frame.width
			let leftEdge = (self.frame.width - elementsWidth) / 2
			let centeringHeight = self.frame.height / 2
			self.imageView.center = CGPoint.init(
				x: leftEdge + self.imageView.frame.width / 2,
				y: centeringHeight
			)
			self.label.center = CGPoint.init(
				x: leftEdge + self.imageView.frame.width + space + label.frame.width / 2,
				y: centeringHeight
			)
			
		default:
			break
		}
	}
}
