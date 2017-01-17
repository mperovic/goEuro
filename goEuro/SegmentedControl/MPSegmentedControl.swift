//
//  MPSegmentedControl.swift
//
//  Created by Miroslav Perovic on 10/17/16.
//  Copyright © 2017 Miroslav Perovic. All rights reserved.
//

import UIKit

final class MPSegmentedControl: UIControl {
	var indicatorView = UIView()
	var stateDelegate: MPSegmentControlCellStateDelegate?
	var delegate: MPSegmentControlDelegate?
	var defaultSelectedSegmentIndex = 0
	var isUpdateToNearestIndexWhenDrag = true
	
	var numberOfSegments: Int {
		return self.cells.count
	}
	
	var selectedSegmentIndex: Int = 0 {
		didSet {
			if selectedSegmentIndex < 0 {
				selectedSegmentIndex = 0
			}
			if selectedSegmentIndex >= self.cells.count {
				selectedSegmentIndex = self.cells.count - 1
			}
			updateSelectedIndex()
		}
	}
	
	var isScrollEnabled: Bool = true {
		didSet {
			self.panGestureRecognizer.isEnabled = self.isScrollEnabled
		}
	}
	
	var isSwipeEnabled: Bool = true {
		didSet {
			self.leftSwipeGestureRecognizer.isEnabled = self.isSwipeEnabled
			self.rightSwipeGestureRecognizer.isEnabled = self.isSwipeEnabled
		}
	}
	
	var isRoundedFrame: Bool = true {
		didSet {
			layoutIfNeeded()
		}
	}
	
	var roundedRelativeFactor: CGFloat = 0.5 {
		didSet {
			layoutIfNeeded()
		}
	}
	
	var apportionsSegmentWidthsByContent = false
	
	fileprivate var cells: [MPSegmentedControlCell] = []
	fileprivate var enabledCells: [Bool] = []
	fileprivate var contentOffsets: [CGSize] = []
	
	fileprivate var panGestureRecognizer: UIPanGestureRecognizer!
	fileprivate var leftSwipeGestureRecognizer: UISwipeGestureRecognizer!
	fileprivate var rightSwipeGestureRecognizer: UISwipeGestureRecognizer!
	
	fileprivate var initialIndicatorViewFrame: CGRect?
	fileprivate var oldNearestIndex: Int!
	
	init() {
		super.init(frame: CGRect.zero)
		commonInit()
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	init(items: [MPSegmentedControlCell]?) {
		super.init(frame: CGRect.zero)
		commonInit()
		
		guard items != nil else { return }
		
		for cell in items! {
			self.insertCell(cell, atIndex: self.cells.count)
		}
		self.selectedSegmentIndex = self.defaultSelectedSegmentIndex
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}
	
	private func commonInit() {
		self.layer.masksToBounds = true
		self.backgroundColor = UIColor.clear
		self.layer.borderColor = UIColor.white.cgColor
		self.layer.borderWidth = 2
		
		self.indicatorView.backgroundColor = UIColor.white
		self.addSubview(indicatorView)
		
		panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(MPSegmentedControl.pan(_:)))
		panGestureRecognizer.delegate = self
		addGestureRecognizer(panGestureRecognizer)
		
		leftSwipeGestureRecognizer = UISwipeGestureRecognizer.init(target: self, action: #selector(MPSegmentedControl.leftSwipe(_:)))
		leftSwipeGestureRecognizer.delegate = self
		leftSwipeGestureRecognizer.direction = .left
		self.indicatorView.addGestureRecognizer(leftSwipeGestureRecognizer)
		
		rightSwipeGestureRecognizer = UISwipeGestureRecognizer.init(target: self, action: #selector(MPSegmentedControl.rightSwipe(_:)))
		rightSwipeGestureRecognizer.delegate = self
		rightSwipeGestureRecognizer.direction = .right
		self.indicatorView.addGestureRecognizer(rightSwipeGestureRecognizer)
	}
	
	
	//MARK: - Managing Segment Content
	func setImage(_ image: UIImage?, forSegmentAt index: Int) {
		guard index >= 0 && index <= self.cells.count else { fatalError("Wrong segment index") }
		
		self.cells[index].imageView.image = image
	}
	
	func imageForSegment(at index: Int) -> UIImage? {
		guard index >= 0 && index <= self.cells.count else { fatalError("Wrong segment index") }
		
		return self.cells[index].imageView.image
	}
	
	func setTitle(_ title: String?, forSegmentAt index: Int) {
		guard index >= 0 && index <= self.cells.count else { fatalError("Wrong segment index") }
		
		self.cells[index].label.text = title
	}
	
	func titleForSegment(at index: Int) -> String? {
		guard index >= 0 && index <= self.cells.count else { fatalError("Wrong segment index") }
		
		return self.cells[index].label.text
	}
	
	//MARK: - Managing Segments
	func insertSegment(with image: UIImage?, at segment: Int, animated: Bool) {
		guard segment >= 0 && segment <= self.cells.count else { fatalError("Wrong segment index") }
		
		let cell = MPSegmentedControlCell(layout: .imageOnly)
		cell.imageView.image = image
		cell.isUserInteractionEnabled = false
		self.insertCell(cell, atIndex: segment)
//		self.selectedSegmentIndex = self.defaultSelectedSegmentIndex
	}
	
	func insertSegment(withTitle title: String?, at segment: Int, animated: Bool) {
		guard segment >= 0 && segment <= self.cells.count else { fatalError("Wrong segment index") }
		
		let cell = MPSegmentedControlCell(layout: .textOnly)
		cell.label.text = title
		cell.isUserInteractionEnabled = false
		self.insertCell(cell, atIndex: segment)
//		self.selectedSegmentIndex = self.defaultSelectedSegmentIndex
	}
	
	func insertSegment(withTitle title: String?, andImage image: UIImage?, at index: Int, animated: Bool) {
		guard index >= 0 && index <= self.cells.count else { fatalError("Wrong segment index") }
		
		let cell = MPSegmentedControlCell(layout: .textWithImage)
		cell.label.text = title
		cell.imageView.image = image
		cell.isUserInteractionEnabled = false
		cell.tag = index
		self.insertCell(cell, atIndex: index)
//		self.selectedSegmentIndex = self.defaultSelectedSegmentIndex
	}
	
	private func insertCell(_ cell: MPSegmentedControlCell, atIndex index: Int) {
		self.cells.insert(cell, at: index)
		self.enabledCells.insert(true, at: index)
		self.contentOffsets.insert(CGSize.zero, at: index)
		cell.layoutIfNeeded()
		self.addSubview(cell)
		
		// Update tag for remaining cells
		guard index < self.numberOfSegments - 1 else { return }
		
		var idx = index
		for cell in self.cells[index..<self.numberOfSegments] {
			cell.tag = idx
			idx += 1
		}
	}
	
	func removeAllSegments() {
		self.cells.removeAll()
		self.enabledCells.removeAll()
		self.contentOffsets.removeAll()
		
		for view in self.subviews {
			view.removeFromSuperview()
		}
	}
	
	func removeSegment(at segment: Int, animated: Bool) {
		guard segment >= 0 && segment < self.enabledCells.count else { fatalError("Wrong segment index") }
		
		self.cells.remove(at: segment)
		self.enabledCells.remove(at: segment)
		
		for view in self.subviews {
			if view.tag == segment {
				view.removeFromSuperview()
			}
		}
	}
	
	
	//MARK: - Managing Segment Behavior and Appearance
	func setEnabled(_ enabled: Bool, forSegmentAt segment: Int) {
		guard segment >= 0 && segment < self.enabledCells.count else { fatalError("Wrong segment index") }
		
		enabledCells[segment] = enabled
	}
	
	func isEnabledForSegment(at segment: Int) -> Bool {
		guard segment >= 0 && segment < self.enabledCells.count else { fatalError("Wrong segment index") }
		
		return enabledCells[segment]
	}
	
	func setContentOffset(_ offset: CGSize, forSegmentAt segment: Int) {
		guard segment >= 0 && segment < self.enabledCells.count else { fatalError("Wrong segment index") }
		
		self.contentOffsets[segment] = offset
	}
	
	func contentOffsetForSegment(at segment: Int) -> CGSize {
		guard segment >= 0 && segment < self.enabledCells.count else { fatalError("Wrong segment index") }
		
		return self.contentOffsets[segment]
	}
	
	func setWidth(_ width: CGFloat, forSegmentAt segment: Int) {
		guard segment >= 0 && segment < self.enabledCells.count else { fatalError("Wrong segment index") }
		
		self.cells[segment].frame.size.width = width
	}
	
	func widthForSegment(at segment: Int) -> CGFloat {
		guard segment >= 0 && segment < self.enabledCells.count else { fatalError("Wrong segment index") }
		
		return self.cells[segment].frame.size.width
	}
	

	//MARK: - Private functions
	private func updateSelectedIndex(animated: Bool = false) {
		if self.stateDelegate != nil {
			for (index, cell) in self.cells.enumerated() {
				self.stateDelegate?.segmentControlCellNormalState?(cell, forIndex: index)
			}
			self.stateDelegate?.segmentControlCellSelectedState?(self.cells[self.selectedSegmentIndex], forIndex: self.selectedSegmentIndex)
		}
		
		MPSpringAnimation.animate(
			withDuration: 0.35,
			animations: {
				self.indicatorView.frame = self.cells[self.selectedSegmentIndex].frame
		}, delay: 0,
		   spring: 1.0,
		   velocity: 0.8,
		   options: [.curveEaseOut]
		)
	}
	
	fileprivate func nearestIndexToPoint(point: CGPoint) -> Int {
		var distances = [CGFloat]()
		
		for cell in self.cells {
			distances.append(
				abs(point.x - cell.center.x)
			)
		}
		return Int(distances.index(of: distances.min()!)!)
	}
	
	override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
		let location = touch.location(in: self)
		var calculatedIndex : Int?
		for (index, cell) in cells.enumerated() {
			if cell.frame.contains(location) {
				calculatedIndex = index
			}
		}
		if calculatedIndex != nil {
			self.selectedSegmentIndex = calculatedIndex!
			sendActions(for: .valueChanged)
		}
		return false
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		if isRoundedFrame {
			self.layer.cornerRadius = min(self.frame.width, self.frame.height) * self.roundedRelativeFactor
			self.indicatorView.layer.cornerRadius = self.layer.cornerRadius
		}
		
		if cells.isEmpty {
			return
		}
		
		let cellWidth = self.frame.width / CGFloat(self.numberOfSegments)
		
		for (index, cell) in cells.enumerated() {
			cell.frame = CGRect.init(
				x: cellWidth * CGFloat(index),
				y: 0,
				width: cellWidth,
				height: self.frame.height
			)
		}
		
		self.indicatorView.frame = CGRect.init(
			x: 0, y: 0,
			width: cellWidth,
			height: self.frame.height
		)
		self.updateSelectedIndex(animated: true)
	}
}


extension MPSegmentedControl: UIGestureRecognizerDelegate {
	func pan(_ gestureRecognizer: UIPanGestureRecognizer!) {
		switch gestureRecognizer.state {
		case .began:
			self.initialIndicatorViewFrame = self.indicatorView.frame
			self.oldNearestIndex = self.nearestIndexToPoint(point: self.indicatorView.center)
			
		case .changed:
			var frame = self.initialIndicatorViewFrame!
			frame.origin.x += gestureRecognizer.translation(in: self).x
			indicatorView.frame = frame
			if indicatorView.frame.origin.x < 0 {
				indicatorView.frame.origin.x = 0
			}
			if (indicatorView.frame.origin.x + indicatorView.frame.width > self.frame.width) {
				indicatorView.frame.origin.x = self.frame.width - indicatorView.frame.width
			}
			
			if (isUpdateToNearestIndexWhenDrag) {
				let nearestIndex = self.nearestIndexToPoint(point: self.indicatorView.center)
				if (self.oldNearestIndex != nearestIndex) && (stateDelegate != nil) {
					self.oldNearestIndex = self.nearestIndexToPoint(point: self.indicatorView.center)
					for (index, cell) in cells.enumerated() {
						stateDelegate?.segmentControlCellNormalState?(cell, forIndex: index)
					}
					stateDelegate?.segmentControlCellSelectedState?(cells[nearestIndex], forIndex:nearestIndex)
				}
			}
			self.delegate?.indicatorViewRelativeTo?(
				position: self.indicatorView.frame.origin.x,
				onSegmentControl: self
			)
			
		case .ended, .failed, .cancelled:
			let translation = gestureRecognizer.translation(in: self).x
			if abs(translation) > (self.frame.width / CGFloat(self.cells.count) * 0.08) {
				if self.selectedSegmentIndex == self.nearestIndexToPoint(point: self.indicatorView.center) {
					if translation > 0 {
						selectedSegmentIndex = selectedSegmentIndex + 1
					} else {
						selectedSegmentIndex = selectedSegmentIndex - 1
					}
				} else {
					self.selectedSegmentIndex = self.nearestIndexToPoint(point: self.indicatorView.center)
				}
			} else {
				self.selectedSegmentIndex = self.nearestIndexToPoint(point: self.indicatorView.center)
			}
			
		default:
			break
		}
	}
	
	func leftSwipe(_ gestureRecognizer: UISwipeGestureRecognizer!) {
		switch gestureRecognizer.state {
		case.ended:
			self.selectedSegmentIndex = selectedSegmentIndex - 1
		default:
			break
		}
	}
	
	func rightSwipe(_ gestureRecognizer: UISwipeGestureRecognizer!) {
		switch gestureRecognizer.state {
		case.ended:
			self.selectedSegmentIndex = selectedSegmentIndex + 1
		default:
			break
		}
	}
	
	override open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		if gestureRecognizer == panGestureRecognizer {
			return indicatorView.frame.contains(gestureRecognizer.location(in: self))
		}
		return super.gestureRecognizerShouldBegin(gestureRecognizer)
	}
}
