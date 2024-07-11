//
//  Trip.swift
//  ElderCalculator
//
//  Created by Michelle Chau on 09/07/24.
//

import Foundation
import SwiftData

@Model
class Trip: Identifiable {
    var id: UUID = UUID()
    var date: Date
    var storeName: String
    var budget: Double
    var tax: Int
    var products: [Product]
    
    init(date: Date, storeName: String, budget: Double, tax: Int) {
        self.date = date
        self.storeName = storeName
        self.budget = budget
        self.tax = tax
        self.products = []
    }
    
//    var grandTotal: Double {
//        let totalProductCost = products.reduce(0.0) { $0 + $1.totalPrice }
//        let totalCostWithTax = totalProductCost + (totalProductCost * Double(tax) / 100)
//        return totalCostWithTax.isNaN ? 0 : totalCostWithTax
//    }
    
    func addProduct(_ product: Product?) {
        products.append(product!)
    }
}