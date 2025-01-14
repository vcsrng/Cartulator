//
//  ShoppingTripViewModel.swift
//  ElderCalculator
//
//  Created by Michelle Chau on 10/07/24.
//

import SwiftUI
import SwiftData

class ShoppingTripViewModel: ObservableObject {
    
    @Published var trips: [Trip] = [] {
        didSet {
            calculateTotalsForSelectedMonth()
        }
    }
    
    @Published var products: [Product] = [] {
        didSet {
            calculateTotalsForSelectedMonth()
        }
    }
    
    
    // shopping trip card
    @Published var monthlyTotalExpense: Double = 0.0
    @Published var monthlyTotalTax: Double = 0.0
    @Published var monthlyTotalDiscount: Double = 0.0
    
    @Published var selectedDate: Date = Date()
    @Published var selectedMonthTrips: [Trip] = []
    
    // add new trip view model
    @Published var storeName: String = ""
    @Published var budget: String = "" {
        didSet {
            let locale = Locale.current
            let currencySymbol = locale.currencySymbol ?? "$"
            
            if currencySymbol == "$" {
                cleanBudget = budget.replacingOccurrences(of: ",", with: "")
            } else {
                cleanBudget = budget.replacingOccurrences(of: ".", with: "")
//                cleanBudget = cleanBudget.replacingOccurrences(of: ",", with: "")
            }
            //            cleanBudget = budget.replacingOccurrences(of: ".", with: "")
//            cleanBudget = budget.replacingOccurrences(of: ",", with: "")
        }
    }
    private var cleanBudget: String = ""
    
    @Published var tax: String = ""
    
    // swift data
    @Published var error: Error? = nil
    
    enum OtherErrors: Error {
        case nilContext
    }
    
    var modelContext: ModelContext? = nil
    var modelContainer: ModelContainer? = nil
    
    @MainActor
    init(inMemory: Bool) {
        do {
            // container init
            let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
            let container = try ModelContainer(for: Trip.self, Product.self, configurations: configuration)
            modelContainer = container
            
            // get model context
            modelContext = container.mainContext
            modelContext?.autosaveEnabled = true
            
            // query data
            queryTrips()
            queryProducts()
            
        } catch(let error) {
            print(error)
            print(error.localizedDescription)
            self.error = error
        }
    }
    
    func queryTrips() {
        guard let modelContext = modelContext else {
            self.error = OtherErrors.nilContext
            return
        }
        
        var tripDescriptor = FetchDescriptor<Trip>(
            predicate: nil,
            sortBy: [
                .init(\.date, order: .reverse)
            ]
        )
        tripDescriptor.fetchLimit = 4
        do {
            trips = try modelContext.fetch(tripDescriptor)
        } catch(let error) {
            self.error = error
        }
    }
    
    
    private func queryProducts() {
        guard let modelContext = modelContext else {
            self.error = OtherErrors.nilContext
            return
        }
        let productDescriptor = FetchDescriptor<Product>(
            predicate: nil,
            sortBy: [
                .init(\.id, order: .reverse)
            ]
        )
        do {
            products = try modelContext.fetch(productDescriptor)
        } catch(let error) {
            self.error = error
        }
    }
    
    func addTrip(storeName: String, budget: Double, tax: Int) {
        guard let modelContext = modelContext else {
            self.error = OtherErrors.nilContext
            return
        }
        
        let date = Date()
        let cleanedBudget = cleanBudget.isEmpty ? budget : Double(cleanBudget) ?? budget
        let newTrip = Trip(
            date: date,
            storeName: storeName,
            budget: cleanedBudget,
            tax: Int(tax)
        )
        modelContext.insert(newTrip)
        save()
        queryTrips()
    }
    
    func updateTrip(trip: Trip, storeName: String, budget: Double, tax: Int) {
        let cleanedBudget = cleanBudget.isEmpty ? budget : Double(cleanBudget) ?? budget
        trip.storeName = storeName
        trip.budget = cleanedBudget
        trip.tax = tax
        
        save()
        queryTrips()
    }
    
    
    func deleteTrip(at offsets: IndexSet) {
        guard let modelContext = modelContext else {
            self.error = OtherErrors.nilContext
            return
        }
        for index in offsets {
            let trip = trips[index]
            modelContext.delete(trip)
        }
        save()
        queryTrips()
    }
    
    
    // Validation for add new trip form
    func isTripValid() -> Bool {
        if !storeName.isEmpty && (Double(cleanBudget) ?? 0) > 0 {
            return true
        } else {
            return false
        }
    }
    
    func resetTripForm() {
        storeName = ""
        budget = ""
        tax = ""
    }
    
    
    func addNewProduct(name: String, price: Double, quantity: Int, discount: Int, trip: Trip, imageName: String) {
        guard let modelContext = modelContext else {
            self.error = OtherErrors.nilContext
            return
        }
        
        let newProduct = Product(
            name: name,
            price: price,
            quantity: quantity,
            discount: discount,
            imageName: imageName
        )
        modelContext.insert(newProduct)
        trip.addProduct(newProduct)
    }
    
    func deleteProduct(indexes: IndexSet, from trip: Trip) {
        
        for index in indexes {
            let objectId = trip.products[index].persistentModelID
            if let productToDelete = modelContext?.model(for: objectId) as? Product {
                modelContext?.delete(productToDelete)
            }
        }
        trip.products.remove(atOffsets: indexes)
        
        do {
            try modelContext?.save()
        } catch {
            print("Error saving context \(error)")
        }
    }
    
    
    
    // Saving any pending changes
    private func save() {
        guard let modelContext = modelContext else {
            self.error = OtherErrors.nilContext
            return
        }
        do {
            try modelContext.save()
        } catch (let error) {
            print(error)
            self.error = error
        }
    }
    
    
    //mainpageviewmodel:
    func calculateTotalsForSelectedMonth() {
        //reset values
        monthlyTotalExpense = 0
        monthlyTotalTax = 0
        monthlyTotalDiscount = 0
        
        //filter trips by the selected month
        let calendar = Calendar.current
        selectedMonthTrips = trips.filter { trip in
            calendar.isDate(trip.date, equalTo: selectedDate, toGranularity: .month) &&
            calendar.isDate(trip.date, equalTo: selectedDate, toGranularity: .year)
        }
        
        
        //calculate totals for the filtered trips
        for trip in selectedMonthTrips {
            for product in trip.products {
                let priceValue = Double(product.price)
                let quantityValue = Double(product.quantity)
                let discountValue = Double(product.discount)
                let discountMultiplier = 1 - (discountValue / 100)
                let taxMultiplier = Double(trip.tax) / 100
                
                let totalTax = priceValue * quantityValue * discountMultiplier * taxMultiplier
                let totalDiscount = priceValue * quantityValue * discountValue / 100
                var totalPrice = (priceValue * quantityValue * discountMultiplier) + totalTax
                
                // Handle 100% discount (free)
                if discountMultiplier == 0 {
                    totalPrice = 0
                }
                
                self.monthlyTotalExpense += totalPrice
                self.monthlyTotalTax += totalTax
                self.monthlyTotalDiscount += totalDiscount
                
            }
        }
    }
    
}
