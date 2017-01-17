//
//  MPAnimation.swift
//  goEuro
//
//  Created by Miroslav Perovic on 1/12/17.
//  Copyright © 2017 Miroslav Perovic. All rights reserved.
//

import UIKit

class MPAnimation {
	static func animate(withDuration duration: TimeInterval, animations: (() -> Void)!, delay: TimeInterval = 0, options: UIViewAnimationOptions = [], withComplection completion: (() -> Void)! = {}) {
		UIView.animate(
			withDuration: duration,
			delay: delay,
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
		
		self.animate(
			withDuration: duration,
			animations: {
				animations()
		},
			delay: delay,
			options: optionsWithRepeatition,
			withComplection: { finished in
				completion()
		})
	}
}
