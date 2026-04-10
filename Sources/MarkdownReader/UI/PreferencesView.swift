import SwiftUI

struct PreferencesView: View {
    @AppStorage(ReaderPreferenceKey.baseFontSize) private var baseFontSize = 18.0
    @AppStorage(ReaderPreferenceKey.readingWidth) private var readingWidth = 820.0
    @AppStorage(ReaderPreferenceKey.showProgress) private var showProgress = true

    var body: some View {
        Form {
            LabeledContent("Font Size") {
                Stepper(value: $baseFontSize, in: 15...24, step: 1) {
                    Text("\(Int(baseFontSize)) pt")
                        .monospacedDigit()
                        .frame(width: 54, alignment: .trailing)
                }
            }

            LabeledContent("Reading Width") {
                VStack(alignment: .trailing, spacing: 8) {
                    Slider(value: $readingWidth, in: 640...1040, step: 20)
                        .frame(width: 220)
                    Text("\(Int(readingWidth)) px")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            Toggle("Show reading progress in the toolbar", isOn: $showProgress)
        }
        .tint(AppTheme.tint)
        .padding(24)
        .frame(width: 420)
        .background(AppTheme.detailBackground)
    }
}
