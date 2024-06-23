//
//  ContentView.swift
//  Instafilter
//
//  Created by Om Preetham Bandi on 6/14/24.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import StoreKit
import SwiftUI

struct ContentView: View {
    @State private var processedImage: Image?
    @State private var inputIntensity = 0.5
    @State private var inputRadius = 0.5
    @State private var inputScale = 0.5
    @State private var inputTime = 0.5
    @State private var inputAngle = 0.5

    @State private var showingConfirmation = false
    
    @State private var selectedItem: PhotosPickerItem?
    
    @AppStorage("filterCount") var filterCount = 0
    @Environment(\.requestReview) var requestReview

    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    let context = CIContext()
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                PhotosPicker(selection: $selectedItem) {
                    if let processedImage {
                        processedImage
                            .resizable()
                            .scaledToFit()
                    } else {
                        ContentUnavailableView("No Picture", systemImage: "photo.badge.plus", description: Text("Tap to import a photo"))
                    }
                }
                .buttonStyle(.plain)
                .onChange(of: selectedItem, loadImage)
                
                Spacer()

                if selectedItem != nil {
                    VStack {
                        HStack {
                            Text("Intensity")
                            Slider(value: $inputIntensity)
                                .onChange(of: inputIntensity, applyProcessing)
                        }
                        HStack {
                            Text("Radius")
                            Slider(value: $inputRadius)
                                .onChange(of: inputRadius, applyProcessing)
                        }
                        HStack {
                            Text("Scale")
                            Slider(value: $inputScale)
                                .onChange(of: inputScale, applyProcessing)
                        }
                        HStack {
                            Text("Time")
                            Slider(value: $inputTime)
                                .onChange(of: inputTime, applyProcessing)
                        }
                        HStack {
                            Text("Angle")
                            Slider(value: $inputAngle)
                                .onChange(of: inputAngle, applyProcessing)
                        }


                    }
                    .padding(.vertical)

                    HStack {
                        Button("Change Filter", action: changeFilter)

                        Spacer()

                        if let processedImage {
                            ShareLink(item: processedImage, message: Text("InstaFilter Image"), preview: SharePreview(Text("Instafilter Image"), image: processedImage))
                        }
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("Instafilter")
            .confirmationDialog("Select a filter", isPresented: $showingConfirmation) {
                Button("Crystallize") { setFilter(CIFilter.crystallize()) }
                Button("Edges") { setFilter(CIFilter.edges()) }
                Button("Gaussian Blur") { setFilter(CIFilter.gaussianBlur()) }
                Button("Pixellate") { setFilter(CIFilter.pixellate()) }
                Button("Sepia Tone") { setFilter(CIFilter.sepiaTone()) }
                Button("Unsharp Mask") { setFilter(CIFilter.unsharpMask()) }
                Button("Vignette") { setFilter(CIFilter.vignette()) }
                Button("Kaleidoscope") { setFilter(CIFilter.kaleidoscope()) }
                Button("Dissolve Transition") { setFilter(CIFilter.dissolveTransition()) }
                Button("Page Curl Transition") { setFilter(CIFilter.pageCurlTransition()) }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    func changeFilter() {
        showingConfirmation = true
    }
    
    func loadImage() {
        Task {
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else { return }
            
            guard let inputImage = UIImage(data: imageData) else { return }
            
            let beginImage = CIImage(image: inputImage)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            applyProcessing()
        }
    }
    
    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys
        
        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(inputIntensity, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(inputRadius * 200, forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(inputScale * 10, forKey: kCIInputScaleKey) }
        if inputKeys.contains(kCIInputTimeKey) { currentFilter.setValue(inputTime, forKey: kCIInputTimeKey) }
        if inputKeys.contains(kCIInputAngleKey) { currentFilter.setValue(inputAngle, forKey: kCIInputAngleKey) }



        guard let outputImage = currentFilter.outputImage else { return }
        
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }
        
        let uiImage = UIImage(cgImage: cgImage)
        processedImage = Image(uiImage: uiImage)
    }
    
    @MainActor func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
        
        filterCount += 1

        if filterCount == 3 {
            requestReview()
        }
    }
}

#Preview {
    ContentView()
}
