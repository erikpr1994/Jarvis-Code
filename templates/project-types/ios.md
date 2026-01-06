# iOS/Swift Project Additions

> Inherits from: global-claude.md + CLAUDE.md.template
> Override: {{OVERRIDE_PARENT}} (set to true for complete override, false for merge)
> Token budget: ~800 tokens

This template extends the base CLAUDE.md with iOS/Swift-specific patterns.

## Tech Stack Additions

```yaml
platform:
  - iOS {{IOS_VERSION}}
  - Swift {{SWIFT_VERSION}}

ui_framework:
  - {{UI_FRAMEWORK}}  # SwiftUI | UIKit | Mixed

architecture:
  - {{ARCHITECTURE}}  # MVVM | TCA | Clean Architecture

dependencies:
  - {{DEPENDENCY_MANAGER}}  # SPM | CocoaPods
```

## Project Structure

### SwiftUI Project

```
ProjectName/
├── App/
│   ├── ProjectNameApp.swift     # App entry point
│   └── AppDelegate.swift        # App delegate (if needed)
├── Core/
│   ├── Extensions/              # Swift extensions
│   ├── Utilities/               # Helper classes
│   └── Constants/               # App constants
├── Features/
│   ├── Auth/
│   │   ├── Views/               # SwiftUI views
│   │   ├── ViewModels/          # ObservableObjects
│   │   └── Models/              # Feature models
│   └── Home/
│       ├── Views/
│       ├── ViewModels/
│       └── Models/
├── Shared/
│   ├── Components/              # Reusable views
│   ├── Services/                # API, storage services
│   └── Repositories/            # Data repositories
├── Resources/
│   ├── Assets.xcassets
│   └── Localizable.strings
└── Tests/
    ├── UnitTests/
    └── UITests/
```

## Key Patterns

### SwiftUI View Structure

```swift
import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Profile")
                .toolbar { toolbarContent }
                .task { await viewModel.loadProfile() }
                .alert("Error", isPresented: $viewModel.showError) {
                    Button("OK") { }
                } message: {
                    Text(viewModel.errorMessage ?? "Unknown error")
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
        } else if let profile = viewModel.profile {
            ProfileContent(profile: profile)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Done") { dismiss() }
        }
    }
}

#Preview {
    ProfileView()
}
```

### ViewModel Pattern

```swift
import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var profile: Profile?
    @Published private(set) var isLoading = false
    @Published var showError = false
    @Published private(set) var errorMessage: String?

    private let profileRepository: ProfileRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(profileRepository: ProfileRepositoryProtocol = ProfileRepository()) {
        self.profileRepository = profileRepository
    }

    func loadProfile() async {
        isLoading = true
        defer { isLoading = false }

        do {
            profile = try await profileRepository.fetchProfile()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func updateProfile(name: String) async {
        guard var updatedProfile = profile else { return }
        updatedProfile.name = name

        do {
            profile = try await profileRepository.updateProfile(updatedProfile)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
```

### Repository Pattern

```swift
import Foundation

protocol ProfileRepositoryProtocol {
    func fetchProfile() async throws -> Profile
    func updateProfile(_ profile: Profile) async throws -> Profile
}

final class ProfileRepository: ProfileRepositoryProtocol {
    private let apiService: APIServiceProtocol
    private let cache: CacheServiceProtocol

    init(
        apiService: APIServiceProtocol = APIService.shared,
        cache: CacheServiceProtocol = CacheService.shared
    ) {
        self.apiService = apiService
        self.cache = cache
    }

    func fetchProfile() async throws -> Profile {
        if let cached: Profile = cache.get(key: "profile") {
            return cached
        }

        let profile: Profile = try await apiService.request(.getProfile)
        cache.set(key: "profile", value: profile)
        return profile
    }

    func updateProfile(_ profile: Profile) async throws -> Profile {
        let updated: Profile = try await apiService.request(.updateProfile(profile))
        cache.set(key: "profile", value: updated)
        return updated
    }
}
```

### Networking

```swift
import Foundation

enum APIEndpoint {
    case getProfile
    case updateProfile(Profile)

    var path: String {
        switch self {
        case .getProfile: return "/profile"
        case .updateProfile: return "/profile"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getProfile: return .get
        case .updateProfile: return .put
        }
    }
}

protocol APIServiceProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
}

final class APIService: APIServiceProtocol {
    static let shared = APIService()

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let url = URL(string: "\(baseURL)\(endpoint.path)")!
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        return try decoder.decode(T.self, from: data)
    }
}
```

### Dependency Injection

```swift
import SwiftUI

// Environment key for dependency injection
private struct RepositoryKey: EnvironmentKey {
    static let defaultValue: RepositoriesContainer = .live
}

extension EnvironmentValues {
    var repositories: RepositoriesContainer {
        get { self[RepositoryKey.self] }
        set { self[RepositoryKey.self] = newValue }
    }
}

struct RepositoriesContainer {
    let profile: ProfileRepositoryProtocol
    let auth: AuthRepositoryProtocol

    static let live = RepositoriesContainer(
        profile: ProfileRepository(),
        auth: AuthRepository()
    )

    static let mock = RepositoriesContainer(
        profile: MockProfileRepository(),
        auth: MockAuthRepository()
    )
}

// Usage in views
struct ContentView: View {
    @Environment(\.repositories) private var repositories
}
```

## Testing

### Unit Testing

```swift
import XCTest
@testable import ProjectName

final class ProfileViewModelTests: XCTestCase {
    var sut: ProfileViewModel!
    var mockRepository: MockProfileRepository!

    @MainActor
    override func setUp() {
        super.setUp()
        mockRepository = MockProfileRepository()
        sut = ProfileViewModel(profileRepository: mockRepository)
    }

    @MainActor
    func testLoadProfileSuccess() async {
        // Given
        let expectedProfile = Profile(id: "1", name: "Test")
        mockRepository.profileToReturn = expectedProfile

        // When
        await sut.loadProfile()

        // Then
        XCTAssertEqual(sut.profile, expectedProfile)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.showError)
    }

    @MainActor
    func testLoadProfileFailure() async {
        // Given
        mockRepository.shouldFail = true

        // When
        await sut.loadProfile()

        // Then
        XCTAssertNil(sut.profile)
        XCTAssertTrue(sut.showError)
        XCTAssertNotNil(sut.errorMessage)
    }
}
```

### UI Testing

```swift
import XCTest

final class ProfileUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    func testProfileEditing() {
        // Navigate to profile
        app.tabBars.buttons["Profile"].tap()

        // Edit name
        let nameField = app.textFields["profile_name"]
        nameField.tap()
        nameField.clearAndType("New Name")

        // Save
        app.buttons["Save"].tap()

        // Verify
        XCTAssertTrue(app.staticTexts["New Name"].exists)
    }
}
```

## Common Commands

```bash
# Build project
{{BUILD_CMD}}

# Run tests
{{TEST_CMD}}

# Run UI tests
{{UI_TEST_CMD}}

# Archive for distribution
{{ARCHIVE_CMD}}

# SwiftLint
{{LINT_CMD}}

# Generate documentation
{{DOC_CMD}}
```

## DO NOT

- Force unwrap optionals without guard
- Use stringly-typed APIs when type-safe alternatives exist
- Skip `@MainActor` on UI-updating code
- Create retain cycles (use `[weak self]` in closures)
- Store sensitive data in UserDefaults
- Skip accessibility labels on interactive elements
- Use synchronous network calls on main thread
- Ignore Swift concurrency warnings

## Performance Guidelines

- Use `LazyVStack` / `LazyHStack` for large lists
- Avoid unnecessary `@State` updates
- Use `task` modifier over `onAppear` for async work
- Profile with Instruments regularly
- Use `equatable()` modifier to prevent unnecessary redraws

## File Conventions

| Pattern | Purpose |
|---------|---------|
| `*View.swift` | SwiftUI views |
| `*ViewModel.swift` | View models |
| `*Repository.swift` | Data repositories |
| `*Service.swift` | Business services |
| `*Model.swift` | Data models |
| `*Tests.swift` | Unit tests |
| `*UITests.swift` | UI tests |
