import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userProfile: UserProfile
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                if let experiment = userProfile.activeExperiment {
                    Text("Your Current Experiment")
                        .font(.title2)

                    Text(experiment.title)
                        .font(.headline)

                    ForEach(experiment.parts, id: \.self) { part in
                        Text("• \(part)")
                    }

                    Text("Started on \(experiment.startDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("You haven't started an experiment yet.")
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
        }
    }
}
