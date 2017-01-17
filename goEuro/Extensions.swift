//
//  Extensions.swift
//  goEuro
//
//  Created by Miroslav Perovic on 1/14/17.
//  Copyright © 2017 Miroslav Perovic. All rights reserved.
//

import Foundation

extension Int {
	func format(f: String) -> String {
		return String(format: "%\(f)d", self)
	}
}

extension Double {
	func format(f: String) -> String {
		return String(format: "%\(f)f", self)
	}
}
