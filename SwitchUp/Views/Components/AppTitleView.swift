import SwiftUI

struct AppTitleView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("SwitchUp.")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0, green: 9/255, blue: 1))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
            
            Rectangle()
                .fill(Color(red: 217/255, green: 217/255, blue: 217/255))
                .frame(height: 1)
                .edgesIgnoringSafeArea(.horizontal)
        }
        .padding(.bottom, 4)
    }
}

#Preview {
    AppTitleView()
}
