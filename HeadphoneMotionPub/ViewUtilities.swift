//
//  ViewUtilities.swift
//  HeadphoneMotionPub
//
//  Created by Yoshito Okada on 2023/04/15.
//

import CoreMotion
import Foundation
import SwiftUI

struct HImageText: View {
    let image: (systemName: String, color: Color)
    let text: (string: String, color: Color)
    
    var body: some View {
        HStack {
            Image(systemName: image.systemName)
                .foregroundColor(image.color)
            Text(text.string)
                .foregroundColor(text.color)
        }
    }
}

struct HTextTextField: View {
    let text: (string: String, color: Color)
    let textField: (text: Binding<String>, fgcolor: Color, bgcolor: Color, onSubmit: () -> Void)
    
    var body: some View {
        HStack {
            Text(text.string)
                .foregroundColor(text.color)
            TextField(text.string, text: textField.text)
                .foregroundColor(textField.fgcolor)
                .background(textField.bgcolor)
                .onSubmit {
                    textField.onSubmit()
                }
        }
    }
}

struct HTextDoubleField: View {
    let text: (string: String, color: Color)
    let textField: (value: Binding<Double>, fgcolor: Color, bgcolor: Color, onSubmit: () -> Void)
    
    var body: some View {
        HStack {
            Text(text.string)
                .foregroundColor(text.color)
            TextField(text.string, value: textField.value, format: .number)
                .foregroundColor(textField.fgcolor)
                .background(textField.bgcolor)
                .keyboardType(.numbersAndPunctuation)
                .onSubmit {
                    textField.onSubmit()
                }
        }
    }
}

enum UrlParseError: Error {
    case invalidUrl
}

struct UrlParseStrategy: ParseStrategy {
    func parse(_ value: String) throws -> URL {
        // ensure the input string can be parsed into a valid URL using URLComponents,
        // which guarantees conformity to the URL standard.
        guard let url = URLComponents(string: value)?.url else { throw UrlParseError.invalidUrl }
        return url
    }
}

struct UrlFormatStyle: ParseableFormatStyle {
    var parseStrategy: UrlParseStrategy {
        return UrlParseStrategy()
    }
    
    func format(_ value: URL) -> String {
        return value.absoluteString
    }
}

struct HTextUrlField: View {
    let text: (string: String, color: Color)
    let textField: (value: Binding<URL>, fgcolor: Color, bgcolor: Color, onSubmit: () -> Void)
    
    var body: some View {
        HStack {
            Text(text.string)
                .foregroundColor(text.color)
            TextField(text.string, value: textField.value, format: UrlFormatStyle())
                .foregroundColor(textField.fgcolor)
                .background(textField.bgcolor)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .onSubmit {
                    textField.onSubmit()
                }
        }
    }
}

struct MotionView: View {
    let motion: CMDeviceMotion
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(String(format: "Eular Angles: (%+.2f, %+.2f, %+.2f)",
                        motion.attitude.roll, motion.attitude.pitch, motion.attitude.yaw))
            .foregroundColor(color)
            Text(String(format: "Angular Velocities: (%+.2f, %+.2f, %+.2f)",
                        motion.rotationRate.x, motion.rotationRate.y, motion.rotationRate.z))
            .foregroundColor(color)
            Text(String(format: "Linear Accelerations: (%+.2f, %+.2f, %+.2f)",
                        motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z))
            .foregroundColor(color)
        }
    }
}

struct PreferenceView: View {
    @AppStorage("keepScreenOn") private(set) var keepScreenOn: Bool = false
    
    var body: some View {
        Toggle("Keep Screen On", isOn: $keepScreenOn)
            .foregroundColor(.secondary)
            .tint(.accentColor)
            .onAppear() {
                // reflect the **initial** preference in the system
                UIApplication.shared.isIdleTimerDisabled = keepScreenOn
            }
            .onChange(of: keepScreenOn) { _ in
                // reflect the **changed** preference in the system
                UIApplication.shared.isIdleTimerDisabled = keepScreenOn
            }
    }
}
