//
//  ContentView.swift
//  ffMacpeg
//
//  Created by Marios Igkiempor on 03/03/2026.
//

import SwiftUI

struct ContentView: View {

    let appState: AppState

    var body: some View {
        VStack(spacing: 24) {
            headerSection
            Divider()
            instructionsSection
            Spacer()
            statusSection
        }
        .padding(32)
        .frame(width: 480, height: 400)
        .task {
            await ConversionNotifier.requestPermission()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "video.badge.waveform")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("FFmacPeg")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Convert videos right from Finder")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Setup")
                .font(.headline)

            InstructionRow(
                step: 1,
                text: "Open System Settings"
            )
            InstructionRow(
                step: 2,
                text: "Go to Privacy & Security \u{2192} Extensions \u{2192} Added Extensions"
            )
            InstructionRow(
                step: 3,
                text: "Enable FFmacPeg"
            )
            InstructionRow(
                step: 4,
                text: "Right-click any video file in Finder and choose \u{201C}Convert to...\u{201D}"
            )
        }
    }

    // MARK: - Status

    private var statusSection: some View {
        Group {
            if appState.isConverting {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Converting\u{2026}")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Ready")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - InstructionRow

private struct InstructionRow: View {

    let step: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(step)")
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.blue, in: Circle())

            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    ContentView(appState: AppState())
}
