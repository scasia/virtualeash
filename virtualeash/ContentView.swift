import SwiftUI

// MARK: - Dynamic Theme Gradient Background

struct LeashBackgroundGradient: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark ? [
                Color(red: 193/255.0, green: 0/255.0, blue: 124/255.0),
                Color(red: 105/255.0, green: 0/255.0, blue: 68/255.0),
                Color(red: 25/255.0, green: 0/255.0, blue: 18/255.0),
                Color.black
            ] : [
                Color(red: 193/255.0, green: 0/255.0, blue: 124/255.0),
                Color(red: 224/255.0, green: 85/255.0, blue: 170/255.0),
                Color(red: 248/255.0, green: 195/255.0, blue: 230/255.0),
                Color.white
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Liquid Glass View Modifier

struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var tintColor: Color? = nil
    
    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    if let tint = tintColor {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(0.14))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.55),
                                .white.opacity(0.15),
                                .clear,
                                .white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 7)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 20, tint: Color? = nil) -> some View {
        self.modifier(LiquidGlassModifier(cornerRadius: cornerRadius, tintColor: tint))
    }
}

// MARK: - Native Tactile Button Styles

struct LiquidGlassButtonStyle: ButtonStyle {
    var backgroundColor: Color
    var cornerRadius: CGFloat = 16
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(backgroundColor)
                    
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.15))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.45),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: backgroundColor.opacity(configuration.isPressed ? 0.2 : 0.35), radius: configuration.isPressed ? 6 : 12, y: configuration.isPressed ? 2 : 6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

struct TactileGlassActionStyle: ButtonStyle {
    var cornerRadius: CGFloat = 14
    var isDestructive: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    if isDestructive {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.red.opacity(0.12))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                (isDestructive ? Color.red : Color.white).opacity(0.35),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Distance Meter Display

struct DistanceMeterDisplayView: View {
    let valueText: String
    let unitText: String
    let angle: Double?
    let isAlarmTriggered: Bool
    
    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 4) {
            if let angle = angle {
                Image(systemName: "arrow.up")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(isAlarmTriggered ? .red : .primary)
                    .rotationEffect(.degrees(angle))
                    .padding(.trailing, 4)
                    .alignmentGuide(.lastTextBaseline) { d in d[.bottom] - 16 }
            }
            
            Text(valueText)
                .font(.system(size: 112, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .foregroundColor(isAlarmTriggered ? .red : .primary)
            
            if !unitText.isEmpty {
                Text(unitText)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(isAlarmTriggered ? .red.opacity(0.85) : .primary.opacity(0.65))
                    .alignmentGuide(.lastTextBaseline) { d in d[.bottom] - 8 }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .liquidGlass(cornerRadius: 28, tint: isAlarmTriggered ? .red : nil)
    }
}

// MARK: - Training Tools Buttons

struct BadButton: View {
    let onTouchDown: () -> Void
    let onTouchUp: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 20, weight: .black))
            Text("BAD!")
                .font(.system(.title3, design: .rounded, weight: .heavy))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 0.90, green: 0.15, blue: 0.18))
                
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(isPressed ? 0.28 : 0.15))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.55), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
        .shadow(color: Color.red.opacity(isPressed ? 0.55 : 0.3), radius: isPressed ? 14 : 8, y: isPressed ? 2 : 5)
        .scaleEffect(isPressed ? 0.94 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        onTouchDown()
                    }
                }
                .onEnded { _ in
                    if isPressed {
                        isPressed = false
                        onTouchUp()
                    }
                }
        )
    }
}

struct ClickerButton: View {
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 19, weight: .bold))
                Text("Clicker")
                    .font(.system(.title3, design: .rounded, weight: .heavy))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
        }
        .buttonStyle(LiquidGlassButtonStyle(
            backgroundColor: Color(red: 0.10, green: 0.52, blue: 0.95),
            cornerRadius: 18
        ))
    }
}

// MARK: - Main ContentView

struct ContentView: View {
    @StateObject private var viewModel = LeashViewModel()
    @State private var showDomSettings = false
    @State private var showSubSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LeashBackgroundGradient()
                
                VStack(spacing: 20) {
                    if viewModel.selectedRole == nil {
                        roleSelectionView
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.96)),
                                removal: .opacity.combined(with: .scale(scale: 1.04))
                            ))
                    } else if viewModel.selectedRole == .sub {
                        subView
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.96)),
                                removal: .opacity.combined(with: .scale(scale: 1.04))
                            ))
                    } else {
                        domView
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.96)),
                                removal: .opacity.combined(with: .scale(scale: 1.04))
                            ))
                    }
                }
                .padding()
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedRole)
            }
            .navigationTitle(viewModel.selectedRole == nil ? "" : "Virtualeash")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.selectedRole == .dom {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            showDomSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    } else if viewModel.selectedRole == .sub {
                        if viewModel.connectedPeerName == nil {
                            Button("Unpair") {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    viewModel.unpair()
                                }
                            }
                            .buttonStyle(TactileGlassActionStyle(cornerRadius: 10, isDestructive: false))
                        }
                    }
                }
            }
            .sheet(isPresented: $showDomSettings) {
                DomSettingsSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showSubSettings) {
                SubSettingsSheet(viewModel: viewModel)
            }
            .onChange(of: viewModel.alarmSettings.allowSubToViewSettings) { _, allowed in
                if !allowed {
                    showSubSettings = false
                }
            }
            .onChange(of: viewModel.connectedPeerName) { _, peer in
                if peer == nil {
                    showSubSettings = false
                }
            }
        }
    }
    
    // MARK: - Role Selection
    
    private var roleSelectionView: some View {
        VStack {
            Spacer().frame(height: 36)
            
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 144, height: 144)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(color: Color.purple.opacity(0.25), radius: 20, x: 0, y: 10)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            Text("Virtualeash")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
                .padding(.top, 14)
            
            Spacer()
            
            HStack(spacing: 14) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                        viewModel.selectRole(.sub)
                    }
                } label: {
                    Text("I'm the sub")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .buttonStyle(LiquidGlassButtonStyle(backgroundColor: Color(red: 0.96, green: 0.28, blue: 0.58)))
                
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                        viewModel.selectRole(.dom)
                    }
                } label: {
                    Text("I'm the dom")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .buttonStyle(LiquidGlassButtonStyle(backgroundColor: Color(red: 0.92, green: 0.20, blue: 0.24)))
            }
            
            if !viewModel.isUWBSupported {
                Text("UWB not supported on this device.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.top, 8)
            }
            
            Spacer().frame(height: 16)
        }
    }
    
    // MARK: - Sub View
    
    private var subView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if viewModel.isAlarmTriggered {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Hey! Go back on the leash!")
                }
                .font(.title3.bold())
                .foregroundColor(.red)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .liquidGlass(cornerRadius: 16, tint: .red)
            }
            
            DistanceMeterDisplayView(
                valueText: viewModel.distanceValueString,
                unitText: viewModel.distanceUnitString,
                angle: viewModel.directionAngleDegrees,
                isAlarmTriggered: viewModel.isAlarmTriggered
            )
            
            if viewModel.connectedPeerName == nil {
                Text("Disconnected from Dom")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            if viewModel.alarmSettings.allowSubToViewSettings && viewModel.connectedPeerName != nil {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showSubSettings = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "eye.fill")
                        Text("Active Dom Settings")
                        Image(systemName: "chevron.right")
                            .font(.caption2.bold())
                    }
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .liquidGlass(cornerRadius: 16)
                }
            }
            
            Spacer()
            
            if viewModel.connectedPeerName == nil {
                Button(role: .destructive) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        viewModel.disconnect()
                    }
                } label: {
                    Text("Disconnect")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(TactileGlassActionStyle(cornerRadius: 14, isDestructive: true))
            }
        }
    }
    
    // MARK: - Dom View
    
    private var domView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if viewModel.isAlarmTriggered {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("SUB EXCEEDED LEASH LIMIT")
                }
                .font(.headline.bold())
                .foregroundColor(.red)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .liquidGlass(cornerRadius: 16, tint: .red)
            }
            
            DistanceMeterDisplayView(
                valueText: viewModel.distanceValueString,
                unitText: viewModel.distanceUnitString,
                angle: viewModel.directionAngleDegrees,
                isAlarmTriggered: viewModel.isAlarmTriggered
            )
            
            if viewModel.alarmSettings.trainingToolsEnabled {
                HStack(spacing: 14) {
                    BadButton(
                        onTouchDown: {
                            viewModel.sendTrainingToolAction(.badStart)
                        },
                        onTouchUp: {
                            viewModel.sendTrainingToolAction(.badStop)
                        }
                    )
                    
                    ClickerButton {
                        viewModel.sendTrainingToolAction(.clicker)
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                    removal: .opacity.combined(with: .scale(scale: 0.95))
                ))
            }
            
            if viewModel.connectedPeerName == nil {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(.white)
                    Text("Searching for Sub...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .liquidGlass(cornerRadius: 14)
            }
            
            Spacer()
        }
    }
}

// MARK: - Dom Settings Sheet

struct DomSettingsSheet: View {
    @ObservedObject var viewModel: LeashViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                LeashBackgroundGradient()
                
                ScrollView {
                    VStack(spacing: 18) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("STATUS")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white.opacity(0.7))
                                Text(viewModel.connectedPeerName ?? "Searching for Sub...")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Circle()
                                .fill(viewModel.connectedPeerName != nil ? Color.green : Color.orange)
                                .frame(width: 12, height: 12)
                        }
                        .padding(16)
                        .liquidGlass(cornerRadius: 18)
                        
                        VStack(alignment: .leading, spacing: 14) {
                            Text("BOUNDARY ALARM")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.8))
                            
                            Toggle("Boundary Alarm", isOn: Binding(
                                get: { viewModel.alarmSettings.isEnabled },
                                set: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    viewModel.setAlarmEnabled($0)
                                }
                            ))
                            .font(.headline)
                            .tint(Color(red: 0.92, green: 0.20, blue: 0.24))
                            
                            if viewModel.alarmSettings.isEnabled {
                                Divider().background(Color.white.opacity(0.2))
                                
                                HStack {
                                    Text("Alarm Threshold")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                    Spacer()
                                    Text(String(format: "%.1f m", viewModel.alarmSettings.thresholdMeters))
                                        .font(.headline.monospacedDigit())
                                        .foregroundColor(.white)
                                }
                                
                                Slider(
                                    value: Binding(
                                        get: { Double(viewModel.alarmSettings.thresholdMeters) },
                                        set: { viewModel.setAlarmThreshold(Float($0)) }
                                    ),
                                    in: 1.0...15.0,
                                    step: 0.5
                                )
                                .tint(Color(red: 0.92, green: 0.20, blue: 0.24))
                            }
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 20)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SUB VISIBILITY")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.8))
                            
                            Toggle("Allow Sub to See Settings", isOn: Binding(
                                get: { viewModel.alarmSettings.allowSubToViewSettings },
                                set: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    viewModel.setAllowSubToViewSettings($0)
                                }
                            ))
                            .font(.headline)
                            .tint(Color(red: 0.96, green: 0.28, blue: 0.58))
                            
                            Text("When enabled, the Sub device can view the active threshold and alert options in read-only mode.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.75))
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 20)
                        
                        VStack(alignment: .leading, spacing: 14) {
                            Text("ALERTS")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.8))
                            
                            Toggle("Vibration Alerts", isOn: Binding(
                                get: { viewModel.alarmSettings.vibrationAlertsEnabled },
                                set: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    viewModel.setVibrationAlertsEnabled($0)
                                }
                            ))
                            .font(.headline)
                            .tint(Color(red: 0.96, green: 0.28, blue: 0.58))
                            
                            Divider().background(Color.white.opacity(0.2))
                            
                            Toggle("Sound Alerts", isOn: Binding(
                                get: { viewModel.alarmSettings.soundAlertsEnabled },
                                set: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    viewModel.setSoundAlertsEnabled($0)
                                }
                            ))
                            .font(.headline)
                            .tint(Color(red: 0.96, green: 0.28, blue: 0.58))
                            
                            Text("Audible alarm sounds will play even if the device's hardware mute switch is turned on.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.75))
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 20)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TRAINING TOOLS")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.8))
                            
                            Toggle("Training Tools", isOn: Binding(
                                get: { viewModel.alarmSettings.trainingToolsEnabled },
                                set: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    viewModel.setTrainingToolsEnabled($0)
                                }
                            ))
                            .font(.headline)
                            .tint(Color(red: 0.96, green: 0.28, blue: 0.58))
                            
                            Text("Displays real-time 'BAD!' vibration paddle and auditory 'Clicker' buttons directly under the distance meter.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.75))
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 20)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Distance Unit")
                                    .font(.headline)
                                Spacer()
                                Picker("Unit", selection: $viewModel.unit) {
                                    ForEach(DistanceUnit.allCases, id: \.self) { u in
                                        Text(u.rawValue).tag(u)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 140)
                            }
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 20)
                        
                        VStack(spacing: 12) {
                            Button(role: .destructive) {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                dismiss()
                                viewModel.disconnect()
                            } label: {
                                Text("Disconnect Session")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                            .buttonStyle(TactileGlassActionStyle(cornerRadius: 14, isDestructive: true))
                            
                            Button(role: .destructive) {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                dismiss()
                                viewModel.unpair()
                            } label: {
                                Text("Unpair Device")
                                    .font(.subheadline)
                                    .foregroundColor(.red.opacity(0.85))
                            }
                        }
                        .padding(.top, 6)
                    }
                    .padding()
                }
            }
            .navigationTitle("Leash Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline.bold())
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Sub Read-Only Settings Sheet

struct SubSettingsSheet: View {
    @ObservedObject var viewModel: LeashViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                LeashBackgroundGradient()
                
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ACTIVE LEASH PARAMETERS")
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack {
                            Text("Boundary Alarm")
                            Spacer()
                            Text(viewModel.alarmSettings.isEnabled ? "ACTIVE" : "DISABLED")
                                .font(.headline.bold())
                                .foregroundColor(viewModel.alarmSettings.isEnabled ? .red : .secondary)
                        }
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        HStack {
                            Text("Allowed Distance")
                            Spacer()
                            Text(String(format: "%.1f m", viewModel.alarmSettings.thresholdMeters))
                                .font(.headline.monospacedDigit().bold())
                                .foregroundColor(.white)
                        }
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        HStack {
                            Text("Vibration Alerts")
                            Spacer()
                            Text(viewModel.alarmSettings.vibrationAlertsEnabled ? "Enabled" : "Disabled")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                        }
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        HStack {
                            Text("Sound Alerts")
                            Spacer()
                            Text(viewModel.alarmSettings.soundAlertsEnabled ? "Enabled (Bypasses Mute)" : "Disabled")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                        }
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        HStack {
                            Text("Training Tools")
                            Spacer()
                            Text(viewModel.alarmSettings.trainingToolsEnabled ? "Active" : "Disabled")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                        }
                    }
                    .padding(20)
                    .liquidGlass(cornerRadius: 20)
                    
                    Text("Settings are controlled exclusively by your Dom.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.75))
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Dom's Rules")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline.bold())
                    .foregroundColor(.white)
                }
            }
            .onChange(of: viewModel.alarmSettings.allowSubToViewSettings) { _, allowed in
                if !allowed {
                    dismiss()
                }
            }
            .onChange(of: viewModel.connectedPeerName) { _, peer in
                if peer == nil {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
