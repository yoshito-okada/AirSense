//
//  ViewUtilities.swift
//  AirSense
//
//  Created by Yoshito Okada on 2023/04/15.
//

import CoreMotion
import Foundation
import simd
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
            Text(String(format: "Gravity: (%+.2f, %+.2f, %+.2f)",
                        motion.gravity.x, motion.gravity.y, motion.gravity.z))
            .foregroundColor(color)
            Text(String(format: "User Acceleration: (%+.2f, %+.2f, %+.2f)",
                        motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z))
            .foregroundColor(color)
        }
    }
}

struct TransformView: View {
    let transform: simd_float4x4
    let color: Color
    
    var body: some View {
        // extract translation & rotation from transformation matrix
        let translation = simd_make_float3(transform.columns.3)
        let rotation = simd_quatf(
            simd_float3x3(columns: (simd_make_float3(transform.columns.0),
                                    simd_make_float3(transform.columns.1),
                                    simd_make_float3(transform.columns.2))))
        // show extracted properties
        Text(String(format: "Translation: (%+.2f, %+.2f, %+.2f)",
                    translation.x, translation.y, translation.z))
        .foregroundColor(color)
        Text(String(format: "Rotation: (%+.2f; %+.2f, %+.2f, %+.2f)",
                    rotation.real, rotation.imag.x, rotation.imag.y, rotation.imag.z))
        .foregroundColor(color)
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
