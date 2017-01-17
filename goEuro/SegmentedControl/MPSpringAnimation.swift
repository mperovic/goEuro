//
//  MPSpringAnimation.swift
//
//  Created by Miroslav Perovic on 10/12/16.
//  Copyright © 2017 Miroslav Perovic. All rights reserved.
//

import UIKit

class MPSpringAnimation {
	fileprivate static let spring: CGFloat = 1.0
	fileprivate static let velocity: CGFloat = 1.0
	
	static func animate(withDuration duration: TimeInterval, animations: (() -> Void)!, delay: TimeInterval = 0, spring: CGFloat = spring, velocity: CGFloat = velocity, options: UIViewAnimationOptions = [], withComplection completion: (() -> Void)! = {}) {
		UIView.animate(
			withDuration: duration,
			delay: delay,
			usingSpringWithDamping: spring,
			initialSpringVelocity: velocity,
			options: options,
			animations: {
				animations()
		}, completion: { finished in
			completion()
		})
	}
	
	static func repeatAnimation(withDuration duration: TimeInterval, animations: (() -> Void)!, delay: TimeInterval = 0, options: UIViewAnimationOptions = [], withComplection completion: (() -> Void)! = {}) {
		var optionsWithRepeatition = options
		optionsWithRepeatition.insert([.autoreverse, .repeat])
		
		UIView.animate(
			withDuration: duration,
			delay: delay,
			usingSpringWithDamping: spring,
			initialSpringVelocity: velocity,
			options: optionsWithRepeatition,
			animations: {
				animations()
		}, completion: { finished in
			completion()
		})
	}
}
