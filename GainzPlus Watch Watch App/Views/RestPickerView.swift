import SwiftUI
import Foundation

struct RestPickerView: View {
    @ObservedObject var vm: SessionViewModel
    @State private var showCustomPicker = false
    @State private var customMinutes = 1
    @State private var customSeconds = 0
    @State private var tappedOption: Int? = nil

    private let options = [30, 60, 90, 120, 180]
    private let accent = Color(red: 0.78, green: 0.96, blue: 0.35)

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Opciones predefinidas
                ForEach(options, id: \.self) { secs in
                    let isSelected = tappedOption == secs
                    Button {
                        withAnimation(.easeIn(duration: 0.08)) {
                            tappedOption = secs
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            vm.startRest(seconds: secs)
                        }
                    } label: {
                        Text(secs.formattedAsTime)
                            .font(.system(.title3, design: .monospaced).weight(.bold))
                            .foregroundStyle(isSelected ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isSelected ? accent : accent.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(accent.opacity(isSelected ? 0 : 0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                // Opción Custom
                Button {
                    showCustomPicker = true
                } label: {
                    HStack {
                        Text("Custom")
                            .font(.system(.title3, design: .monospaced).weight(.bold))
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(.footnote))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom)
        }
        .fullScreenCover(isPresented: $showCustomPicker) {
            CustomTimerPickerView(
                minutes: $customMinutes,
                seconds: $customSeconds,
                onStart: {
                    let totalSeconds = (customMinutes * 60) + customSeconds
                    vm.startRest(seconds: totalSeconds)
                    showCustomPicker = false
                }
            )
        }
    }
}

// Vista para el picker personalizado
struct CustomTimerPickerView: View {
    @Binding var minutes: Int
    @Binding var seconds: Int
    let onStart: () -> Void
    @Environment(\.dismiss) private var dismiss

    private let minuteRange = Array(0...59)
    private let secondRange = Array(0...59)

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                VStack(spacing: 4) {
                    
                    Picker("Minutes", selection: $minutes) {
                        ForEach(minuteRange, id: \.self) { m in
                            Text("\(m)").tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }

                VStack(spacing: 4) {
                    
                    Picker("Seconds", selection: $seconds) {
                        ForEach(secondRange, id: \.self) { s in
                            Text(String(format: "%02d", s)).tag(s)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)

            HStack(spacing: 8) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Start") {
                    onStart()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.top, 8)
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    RestPickerView(vm: SessionViewModel())
}
