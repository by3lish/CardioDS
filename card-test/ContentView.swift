import SwiftUI

struct ContentView: View {
    private let cardsRootPath = "/var/mobile/Library/Passes/Cards"

    @StateObject private var exploit = ExploitManager.shared
    @State private var showNoCardsError = false
    @State private var cards: [Card] = []

    private func loadCards() {
        cards = getPasses()
    }

    private func getPasses() -> [Card] {
        let fm = FileManager.default
        var data = [Card]()

        do {
            let passes = try fm.contentsOfDirectory(atPath: cardsRootPath).filter { $0.hasSuffix("pkpass") }

            for pass in passes {
                let cardDirectory = cardsRootPath + "/" + pass
                let files = try fm.contentsOfDirectory(atPath: cardDirectory)

                if files.contains("cardBackgroundCombined@2x.png") {
                    data.append(Card(imagePath: cardDirectory + "/cardBackgroundCombined@2x.png", id: pass, format: "@2x.png"))
                } else if files.contains("cardBackgroundCombined.pdf") {
                    data.append(Card(imagePath: cardDirectory + "/cardBackgroundCombined.pdf", id: pass, format: ".pdf"))
                }
            }

            return data
        } catch {
            return []
        }
    }

    private func recheckAndReload() {
        exploit.refreshAccessProbe()
        loadCards()
    }

    private func runAllAndReload() {
        exploit.runAll { _ in
            recheckAndReload()
            if cards.isEmpty {
                showNoCardsError = true
            }
        }
    }

    private var exploitPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Exploit Engine")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Text(exploit.statusMessage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(exploit.canApplyCardChanges ? .green : .orange)

            Text(String(
                format: "darksword=%@ | kfs=%@",
                exploit.darkswordReady ? "ready" : "not-ready",
                exploit.kfsReady ? "ready" : "not-ready"
            ))
            .font(.system(size: 12, weight: .regular, design: .monospaced))
            .foregroundColor(.white.opacity(0.85))

            if exploit.darkswordReady {
                Text(String(
                    format: "kernel_base=0x%llx slide=0x%llx",
                    exploit.kernelBase,
                    exploit.kernelSlide
                ))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
            }

            HStack(spacing: 10) {
                Button(exploit.darkswordRunning ? "Running Darksword..." : "Run Darksword") {
                    exploit.runDarksword { _ in
                        recheckAndReload()
                    }
                }
                .disabled(exploit.darkswordRunning || exploit.kfsRunning)
                .foregroundColor(.white)

                Button(exploit.kfsRunning ? "Init KFS..." : "Init KFS") {
                    exploit.initKFS { _ in
                        recheckAndReload()
                    }
                }
                .disabled(exploit.darkswordRunning || exploit.kfsRunning)
                .foregroundColor(.white)

                Button("Run All") {
                    runAllAndReload()
                }
                .disabled(exploit.darkswordRunning || exploit.kfsRunning)
                .foregroundColor(.white)
            }

            ScrollView {
                Text(exploit.logText.isEmpty ? "No logs yet." : exploit.logText)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color.green.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .frame(height: 120)
            .background(Color.white.opacity(0.06))
            .cornerRadius(8)
        }
        .padding(12)
        .background(Color.white.opacity(0.09))
        .cornerRadius(12)
        .padding(.horizontal, 14)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Tap a card to customize")
                    .font(.system(size: 25))
                    .foregroundColor(.white)

                Text("Swipe to view different cards")
                    .font(.system(size: 15))
                    .foregroundColor(.white)

                exploitPanel

                if !cards.isEmpty {
                    TabView {
                        ForEach(cards, id: \.id) { card in
                            CardView(card: card, exploit: exploit)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .frame(height: 340)

                    Button("Refresh Cards") {
                        loadCards()
                        if cards.isEmpty {
                            showNoCardsError = true
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.top, 16)
                } else {
                    VStack(spacing: 12) {
                        Text("No Cards Found").foregroundColor(.red)

                        Button("Run All + Scan") {
                            runAllAndReload()
                        }
                        .foregroundColor(.white)

                        Button("Scan Again") {
                            loadCards()
                            if cards.isEmpty {
                                showNoCardsError = true
                            }
                        }
                        .foregroundColor(.white)
                    }
                }
            }
            .alert(isPresented: $showNoCardsError) {
                Alert(title: Text("No Cards Were Found"))
            }
        }
        .onAppear {
            recheckAndReload()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
