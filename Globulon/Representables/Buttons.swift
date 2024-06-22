//
//  Buttons.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct btnPreviousView: View {
    var body: some View {
        HStack {
            Image(systemName: "arrow.left")
                .resizable()
                .foregroundColor(.gray)
                .frame(width: 30, height: 30)
                .padding()
                .background(Color.clear)
                .clipShape(Circle())
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.gray, lineWidth: 1)
                )
        }
    }
}

import UIKit


struct CustomButton: UIViewRepresentable {
    var value: Double
    var text: String
    let action: () -> Void

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center

        // Apply rounded corners
        button.layer.cornerRadius = 10
        button.clipsToBounds = true

        // Add action
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)

        return button
    }

    func updateUIView(_ uiView: UIButton, context: Context) {
        let valueColor = value > 75 ? UIColor.green : UIColor.black
        let valueAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: valueColor, .font: UIFont.boldSystemFont(ofSize: 16)]
        let textAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 14)]

        let valueString = NSAttributedString(string: "\(value)\n", attributes: valueAttributes)
        let textString = NSAttributedString(string: text, attributes: textAttributes)

        let combinedString = NSMutableAttributedString()
        combinedString.append(valueString)
        combinedString.append(textString)

        uiView.setAttributedTitle(combinedString, for: .normal)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    class Coordinator: NSObject {
        var action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func tapped() {
            action()
        }
    }
}


// Define a custom UIButton subclass
class ScoreUIButton: UIButton {
    private let valueLabel = UILabel()
    private let textLabel = UILabel()
    
    var tapAction: (() -> Void)?

    var value: Double = 0 {
        didSet {
            updateDisplay()
        }
    }
    var customText: String = "" {
        didSet {
            updateDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        setupLabels()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLabels() {
        valueLabel.textAlignment = .center
        textLabel.textAlignment = .center
        
        // Customize label appearance
        valueLabel.font = UIFont.boldSystemFont(ofSize: 16)
        textLabel.font = UIFont.systemFont(ofSize: 14)
        
        addSubview(valueLabel)
        addSubview(textLabel)
    }
    
    private func updateDisplay() {
        valueLabel.text = String(format: "%.2f", value)
        textLabel.text = customText
        
        // Change value color based on the value
        valueLabel.textColor = value > 75 ? .green : .black
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Layout your labels here
        let labelHeight = bounds.height / 2
        valueLabel.frame = CGRect(x: 0, y: 0, width: bounds.width, height: labelHeight)
        textLabel.frame = CGRect(x: 0, y: labelHeight, width: bounds.width, height: labelHeight)
    }
    

    @objc private func handleTap() {
        tapAction?()
    }
}

struct ScoreButton: UIViewRepresentable {
    var value: Double
    var text: String
    var action: () -> Void
    
    func makeUIView(context: Context) -> ScoreUIButton {
        let button = ScoreUIButton()
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.blue.cgColor
        
        // Set initial values
        button.value = value
        button.customText = text
        button.tapAction = action
        
        return button
    }
    
    func updateUIView(_ uiView: ScoreUIButton, context: Context) {
        // Update values
        uiView.value = value
        uiView.customText = text
    }
}

// Example Usage in a SwiftUI View
/*
struct ContentView: View {
    var body: some View {
        ScoreButton(value: 76, text: "Performance")
            .frame(width: 200, height: 100) // Adjust the frame size as needed
    }
}
*/

