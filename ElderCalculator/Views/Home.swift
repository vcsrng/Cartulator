//
//  Home.swift
//  ElderCalculator
//
//  Created by James Cellars on 09/07/24.
//

import SwiftUI

struct Home: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            VStack {
                //Tax toggle
                TaxToggle(isTaxIncluded: $viewModel.isTaxIncluded)
                
                //Total spendings
                TotalSpendings(total: viewModel.total)
                
                //Category input
                CategoryInput(selectedCategory: $viewModel.selectedCategory, categories: viewModel.categories)
                
                //Price input
                PriceInput(price: $viewModel.price)
                
                //Quantity input
                QuantityInput(quantity: $viewModel.quantity)
                
                //Discount input
                DiscountInput(discount: $viewModel.discount)
                
                //Calculate button
                Button(action: viewModel.calculateTotal) {
                    Text("Add item")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .padding()
        }
    }
}

#Preview {
    Home()
}
