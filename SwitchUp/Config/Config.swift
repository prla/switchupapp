import Foundation

enum Config {
    private static let config: [String: Any] = {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            fatalError("Config.plist not found or invalid format")
        }
        return dict
    }()
    
    static var openAIAPIKey: String {
        guard let key = config["OpenAI_API_Key"] as? String, !key.isEmpty else {
            fatalError("OpenAI_API_Key not found in Config.plist or is empty")
        }
        return key
    }
}
