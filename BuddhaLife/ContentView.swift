import SwiftUI

struct ContentView: View {
    @State private var engine = GameEngine()

    var body: some View {
        Group {
            switch engine.screen {
            case .title:
                TitleView(engine: engine)
            case .playing, .event:
                GameView(engine: engine)
            case .endOfLife:
                EndOfLifeView(engine: engine)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: engine.screen)
    }
}
