import SwiftUI

struct DiaryView: View {
    
    @State private var diaryText: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Text("我的日記")
                    .font(.title)
                
                TextEditor(text: $diaryText)
                    .padding()
                    .border(Color.gray)
            }
            .padding()
            .navigationTitle("日記")
        }
    }
}
